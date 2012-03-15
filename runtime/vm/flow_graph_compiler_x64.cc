// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_X64.
#if defined(TARGET_ARCH_X64)

#include "vm/flow_graph_compiler.h"

#include "vm/ast_printer.h"
#include "vm/code_generator.h"
#include "vm/disassembler.h"
#include "vm/longjump.h"
#include "vm/object_store.h"
#include "vm/parser.h"
#include "vm/stub_code.h"

namespace dart {

DECLARE_FLAG(bool, print_ast);
DECLARE_FLAG(bool, print_scopes);
DECLARE_FLAG(bool, trace_functions);

FlowGraphCompiler::FlowGraphCompiler(
    Assembler* assembler,
    const ParsedFunction& parsed_function,
    const GrowableArray<BlockEntryInstr*>* blocks)
    : assembler_(assembler),
      parsed_function_(parsed_function),
      blocks_(blocks),
      block_info_(blocks->length()),
      current_block_(NULL),
      pc_descriptors_list_(new CodeGenerator::DescriptorList()) {
  for (int i = 0; i < blocks->length(); ++i) {
    block_info_.Add(new BlockInfo());
  }
}


FlowGraphCompiler::~FlowGraphCompiler() {
  // BlockInfos are zone-allocated, so their destructors are not called.
  // Verify the labels explicitly here.
  for (int i = 0; i < block_info_.length(); ++i) {
    ASSERT(!block_info_[i]->label.IsLinked());
    ASSERT(!block_info_[i]->label.HasNear());
  }
}


intptr_t FlowGraphCompiler::StackSize() const {
  return parsed_function_.stack_local_count() +
      parsed_function_.copied_parameter_count();
}


void FlowGraphCompiler::Bailout(const char* reason) {
  const char* kFormat = "FlowGraphCompiler Bailout: %s %s.";
  const char* function_name = parsed_function_.function().ToCString();
  intptr_t len = OS::SNPrint(NULL, 0, kFormat, function_name, reason) + 1;
  char* chars = reinterpret_cast<char*>(
      Isolate::Current()->current_zone()->Allocate(len));
  OS::SNPrint(chars, len, kFormat, function_name, reason);
  const Error& error = Error::Handle(
      LanguageError::New(String::Handle(String::New(chars))));
  Isolate::Current()->long_jump_base()->Jump(1, error);
}

#define __ assembler_->


void FlowGraphCompiler::GenerateAssertAssignable(intptr_t node_id,
                                                 intptr_t token_index,
                                                 const AbstractType& dst_type,
                                                 const String& dst_name) {
  Bailout("GenerateAssertAssignable");
}


void FlowGraphCompiler::LoadValue(Register dst, Value* value) {
  if (value->IsConstant()) {
    ConstantVal* constant = value->AsConstant();
    if (constant->value().IsSmi()) {
      int64_t imm = reinterpret_cast<int64_t>(constant->value().raw());
      __ movq(dst, Immediate(imm));
    } else {
      __ LoadObject(dst, value->AsConstant()->value());
    }
  } else {
    ASSERT(value->IsTemp());
    __ popq(dst);
  }
}


void FlowGraphCompiler::VisitTemp(TempVal* val) {
  LoadValue(RAX, val);
}


void FlowGraphCompiler::VisitConstant(ConstantVal* val) {
  LoadValue(RAX, val);
}


void FlowGraphCompiler::VisitAssertAssignable(AssertAssignableComp* comp) {
  Bailout("AssertAssignableComp");
}


// True iff. the arguments to a call will be properly pushed and can
// be popped after the call.
template <typename T> static bool VerifyCallComputation(T* comp) {
  // Argument values should be consecutive temps.
  //
  // TODO(kmillikin): implement stack height tracking so we can also assert
  // they are on top of the stack.
  intptr_t previous = -1;
  for (int i = 0; i < comp->ArgumentCount(); ++i) {
    TempVal* temp = comp->ArgumentAt(i)->AsTemp();
    if (temp == NULL) return false;
    if (i != 0) {
      if (temp->index() != previous + 1) return false;
    }
    previous = temp->index();
  }
  return true;
}


// Truee iff. the v2 is above v1 on stack, or one of them is constant.
static bool VerifyValues(Value* v1, Value* v2) {
  if (v1->IsTemp() && v2->IsTemp()) {
    return (v1->AsTemp()->index() + 1) == v2->AsTemp()->index();
  }
  return true;
}


void FlowGraphCompiler::EmitInstanceCall(intptr_t node_id,
                                         intptr_t token_index,
                                         const String& function_name,
                                         intptr_t argument_count,
                                         const Array& argument_names,
                                         intptr_t checked_argument_count) {
  ICData& ic_data =
      ICData::ZoneHandle(ICData::New(parsed_function_.function(),
                                     function_name,
                                     node_id,
                                     checked_argument_count));
  const Array& arguments_descriptor =
      CodeGenerator::ArgumentsDescriptor(argument_count, argument_names);
  __ LoadObject(RBX, ic_data);
  __ LoadObject(R10, arguments_descriptor);

  uword label_address = 0;
  switch (checked_argument_count) {
    case 1:
      label_address = StubCode::OneArgCheckInlineCacheEntryPoint();
      break;
    case 2:
      label_address = StubCode::TwoArgsCheckInlineCacheEntryPoint();
      break;
    default:
      UNIMPLEMENTED();
  }
  ExternalLabel target_label("InlineCache", label_address);
  __ call(&target_label);
  AddCurrentDescriptor(PcDescriptors::kIcCall, node_id, token_index);
  __ addq(RSP, Immediate(argument_count * kWordSize));
}


void FlowGraphCompiler::VisitCurrentContext(CurrentContextComp* comp) {
  __ movq(RAX, CTX);
}


void FlowGraphCompiler::VisitClosureCall(ClosureCallComp* comp) {
  ASSERT(comp->context()->IsTemp());
  ASSERT(VerifyCallComputation(comp));
  // The arguments to the stub include the closure.  The arguments
  // descriptor describes the closure's arguments (and so does not include
  // the closure).
  int argument_count = comp->ArgumentCount();
  const Array& arguments_descriptor =
      CodeGenerator::ArgumentsDescriptor(argument_count - 1,
                                         comp->argument_names());
  __ LoadObject(R10, arguments_descriptor);

  GenerateCall(comp->token_index(),
               &StubCode::CallClosureFunctionLabel(),
               PcDescriptors::kOther);
  __ addq(RSP, Immediate(argument_count * kWordSize));
  __ popq(CTX);
}


void FlowGraphCompiler::VisitInstanceCall(InstanceCallComp* comp) {
  ASSERT(VerifyCallComputation(comp));
  EmitInstanceCall(comp->node_id(),
                   comp->token_index(),
                   comp->function_name(),
                   comp->ArgumentCount(),
                   comp->argument_names(),
                   comp->checked_argument_count());
}


void FlowGraphCompiler::VisitStrictCompare(StrictCompareComp* comp) {
  const Bool& bool_true = Bool::ZoneHandle(Bool::True());
  const Bool& bool_false = Bool::ZoneHandle(Bool::False());
  LoadValue(RAX, comp->left());
  LoadValue(RDX, comp->right());
  __ cmpq(RAX, RDX);
  Label load_true, done;
  if (comp->kind() == Token::kEQ_STRICT) {
    __ j(EQUAL, &load_true, Assembler::kNearJump);
  } else {
    __ j(NOT_EQUAL, &load_true, Assembler::kNearJump);
  }
  __ LoadObject(RAX, bool_false);
  __ jmp(&done, Assembler::kNearJump);
  __ Bind(&load_true);
  __ LoadObject(RAX, bool_true);
  __ Bind(&done);
}



void FlowGraphCompiler::VisitStaticCall(StaticCallComp* comp) {
  ASSERT(VerifyCallComputation(comp));

  int argument_count = comp->ArgumentCount();
  const Array& arguments_descriptor =
      CodeGenerator::ArgumentsDescriptor(argument_count,
                                         comp->argument_names());
  __ LoadObject(RBX, comp->function());
  __ LoadObject(R10, arguments_descriptor);

  GenerateCall(comp->token_index(),
               &StubCode::CallStaticFunctionLabel(),
               PcDescriptors::kFuncCall);
  __ addq(RSP, Immediate(argument_count * kWordSize));
}


void FlowGraphCompiler::VisitLoadLocal(LoadLocalComp* comp) {
  if (comp->local().is_captured()) {
    Bailout("load of context variable");
  }
  __ movq(RAX, Address(RBP, comp->local().index() * kWordSize));
}


void FlowGraphCompiler::VisitStoreLocal(StoreLocalComp* comp) {
  if (comp->local().is_captured()) {
    Bailout("store to context variable");
  }
  LoadValue(RAX, comp->value());
  __ movq(Address(RBP, comp->local().index() * kWordSize), RAX);
}


void FlowGraphCompiler::VisitNativeCall(NativeCallComp* comp) {
  // Push the result place holder initialized to NULL.
  __ PushObject(Object::ZoneHandle());
  // Pass a pointer to the first argument in RAX.
  if (!comp->has_optional_parameters()) {
    __ leaq(RAX, Address(RBP, (1 + comp->argument_count()) * kWordSize));
  } else {
    __ leaq(RAX, Address(RBP, -1 * kWordSize));
  }
  __ movq(RBX, Immediate(reinterpret_cast<uword>(comp->native_c_function())));
  __ movq(R10, Immediate(comp->argument_count()));
  GenerateCall(comp->token_index(),
               &StubCode::CallNativeCFunctionLabel(),
               PcDescriptors::kOther);
  __ popq(RAX);
}


void FlowGraphCompiler::VisitLoadInstanceField(LoadInstanceFieldComp* comp) {
  LoadValue(RAX, comp->instance());
  __ movq(RAX, FieldAddress(RAX, comp->field().Offset()));
}


void FlowGraphCompiler::VisitStoreInstanceField(StoreInstanceFieldComp* comp) {
  VerifyValues(comp->instance(), comp->value());
  LoadValue(RDX, comp->value());
  LoadValue(RAX, comp->instance());
  __ StoreIntoObject(RAX, FieldAddress(RAX, comp->field().Offset()), RDX);
}



void FlowGraphCompiler::VisitLoadStaticField(LoadStaticFieldComp* comp) {
  __ LoadObject(RDX, comp->field());
  __ movq(RAX, FieldAddress(RDX, Field::value_offset()));
}


void FlowGraphCompiler::VisitStoreStaticField(StoreStaticFieldComp* comp) {
  LoadValue(RAX, comp->value());
  __ LoadObject(RDX, comp->field());
  __ StoreIntoObject(RDX, FieldAddress(RDX, Field::value_offset()), RAX);
}


void FlowGraphCompiler::VisitStoreIndexed(StoreIndexedComp* comp) {
  // Call operator []= but preserve the third argument value under the
  // arguments as the result of the computation.
  const String& function_name =
      String::ZoneHandle(String::NewSymbol(Token::Str(Token::kASSIGN_INDEX)));

  // Insert a copy of the third (last) argument under the arguments.
  __ popq(RAX);  // Value.
  __ popq(RBX);  // Index.
  __ popq(RCX);  // Receiver.
  __ pushq(RAX);
  __ pushq(RCX);
  __ pushq(RBX);
  __ pushq(RAX);
  EmitInstanceCall(comp->node_id(), comp->token_index(), function_name, 3,
                   Array::ZoneHandle(), 1);
  __ popq(RAX);
}


void FlowGraphCompiler::VisitInstanceSetter(InstanceSetterComp* comp) {
  // Preserve the second argument under the arguments as the result of the
  // computation, then call the getter.
  const String& function_name =
      String::ZoneHandle(Field::SetterSymbol(comp->field_name()));

  // Insert a copy of the second (last) argument under the arguments.
  __ popq(RAX);  // Value.
  __ popq(RBX);  // Reciever.
  __ pushq(RAX);
  __ pushq(RBX);
  __ pushq(RAX);
  EmitInstanceCall(comp->node_id(), comp->token_index(), function_name, 2,
                   Array::ZoneHandle(), 1);
  __ popq(RAX);
}


void FlowGraphCompiler::VisitBooleanNegate(BooleanNegateComp* comp) {
  const Bool& bool_true = Bool::ZoneHandle(Bool::True());
  const Bool& bool_false = Bool::ZoneHandle(Bool::False());
  Label done;
  LoadValue(RDX, comp->value());
  __ LoadObject(RAX, bool_true);
  __ cmpq(RAX, RDX);
  __ j(NOT_EQUAL, &done, Assembler::kNearJump);
  __ LoadObject(RAX, bool_false);
  __ Bind(&done);
}


static const Class* CoreClass(const char* c_name) {
  const String& class_name = String::Handle(String::NewSymbol(c_name));
  const Class& cls = Class::ZoneHandle(Library::Handle(
      Library::CoreImplLibrary()).LookupClass(class_name));
  ASSERT(!cls.IsNull());
  return &cls;
}


void FlowGraphCompiler::GenerateInstantiatorTypeArguments(
    intptr_t token_index) {
  Bailout("FlowGraphCompiler::GenerateInstantiatorTypeArguments");
}


// Copied from CodeGenerator.
// Optimize instanceof type test by adding inlined tests for:
// - NULL -> return false.
// - Smi -> compile time subtype check (only if dst class is not parameterized).
// - Class equality (only if class is not parameterized).
// Inputs:
// - RAX: object.
// Destroys RCX.
// Returns:
// - true or false in RAX.
void FlowGraphCompiler::GenerateInstanceOf(intptr_t node_id,
                                           intptr_t token_index,
                                           const AbstractType& type,
                                           bool negate_result) {
  ASSERT(type.IsFinalized() && !type.IsMalformed());
  const Bool& bool_true = Bool::ZoneHandle(Bool::True());
  const Bool& bool_false = Bool::ZoneHandle(Bool::False());

  // All instances are of a subtype of the Object type.
  const Type& object_type =
      Type::Handle(Isolate::Current()->object_store()->object_type());
  Error& malformed_error = Error::Handle();
  if (type.IsInstantiated() &&
      object_type.IsSubtypeOf(type, &malformed_error)) {
    __ LoadObject(RAX, negate_result ? bool_false : bool_true);
    return;
  }

  const Immediate raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  Label done;
  // If type is instantiated and non-parameterized, we can inline code
  // checking whether the tested instance is a Smi.
  if (type.IsInstantiated()) {
    // A null object is only an instance of Object and Dynamic, which has
    // already been checked above (if the type is instantiated). So we can
    // return false here if the instance is null (and if the type is
    // instantiated).
    // We can only inline this null check if the type is instantiated at compile
    // time, since an uninstantiated type at compile time could be Object or
    // Dynamic at run time.
    Label non_null;
    __ cmpq(RAX, raw_null);
    __ j(NOT_EQUAL, &non_null, Assembler::kNearJump);
    __ PushObject(negate_result ? bool_true : bool_false);
    __ jmp(&done);

    __ Bind(&non_null);

    const Class& type_class = Class::ZoneHandle(type.type_class());
    const bool requires_type_arguments = type_class.HasTypeArguments();
    // A Smi object cannot be the instance of a parameterized class.
    // A class equality check is only applicable with a dst type of a
    // non-parameterized class or with a raw dst type of a parameterized class.
    if (requires_type_arguments) {
      const AbstractTypeArguments& type_arguments =
          AbstractTypeArguments::Handle(type.arguments());
      const bool is_raw_type = type_arguments.IsNull() ||
          type_arguments.IsDynamicTypes(type_arguments.Length());
      Label runtime_call;
      __ testq(RAX, Immediate(kSmiTagMask));
      __ j(ZERO, &runtime_call, Assembler::kNearJump);
      // Object not Smi.
      if (is_raw_type) {
        if (type.IsListInterface()) {
          Label push_result;
          // TODO(srdjan) also accept List<Object>.
          __ movq(RCX, FieldAddress(RAX, Object::class_offset()));
          __ CompareObject(RCX, *CoreClass("ObjectArray"));
          __ j(EQUAL, &push_result, Assembler::kNearJump);
          __ CompareObject(RCX, *CoreClass("GrowableObjectArray"));
          __ j(NOT_EQUAL, &runtime_call, Assembler::kNearJump);
          __ Bind(&push_result);
          __ PushObject(negate_result ? bool_false : bool_true);
          __ jmp(&done);
        } else if (!type_class.is_interface()) {
          __ movq(RCX, FieldAddress(RAX, Object::class_offset()));
          __ CompareObject(RCX, type_class);
          __ j(NOT_EQUAL, &runtime_call, Assembler::kNearJump);
          __ PushObject(negate_result ? bool_false : bool_true);
          __ jmp(&done);
        }
      }
      __ Bind(&runtime_call);
      // Fall through to runtime call.
    } else {
      Label compare_classes;
      __ testq(RAX, Immediate(kSmiTagMask));
      __ j(NOT_ZERO, &compare_classes, Assembler::kNearJump);
      // Object is Smi.
      const Class& smi_class = Class::Handle(Smi::Class());
      // TODO(regis): We should introduce a SmiType.
      Error& malformed_error = Error::Handle();
      if (smi_class.IsSubtypeOf(TypeArguments::Handle(),
                                type_class,
                                TypeArguments::Handle(),
                                &malformed_error)) {
        __ PushObject(negate_result ? bool_false : bool_true);
      } else {
        __ PushObject(negate_result ? bool_true : bool_false);
      }
      __ jmp(&done);

      // Compare if the classes are equal.
      __ Bind(&compare_classes);
      const Class* compare_class = NULL;
      if (type.IsStringInterface()) {
        compare_class = &Class::ZoneHandle(
            Isolate::Current()->object_store()->one_byte_string_class());
      } else if (type.IsBoolInterface()) {
        compare_class = &Class::ZoneHandle(
            Isolate::Current()->object_store()->bool_class());
      } else if (!type_class.is_interface()) {
        compare_class = &type_class;
      }
      if (compare_class != NULL) {
        Label runtime_call;
        __ movq(RCX, FieldAddress(RAX, Object::class_offset()));
        __ CompareObject(RCX, *compare_class);
        __ j(NOT_EQUAL, &runtime_call, Assembler::kNearJump);
        __ PushObject(negate_result ? bool_false : bool_true);
        __ jmp(&done, Assembler::kNearJump);
        __ Bind(&runtime_call);
      }
    }
  }
  __ PushObject(Object::ZoneHandle());  // Make room for the result.
  const Immediate location =
      Immediate(reinterpret_cast<int64_t>(Smi::New(token_index)));
  __ pushq(location);  // Push the source location.
  __ pushq(RAX);  // Push the instance.
  __ PushObject(type);  // Push the type.
  if (!type.IsInstantiated()) {
    GenerateInstantiatorTypeArguments(token_index);
  } else {
    __ pushq(raw_null);  // Null instantiator.
  }
  GenerateCallRuntime(node_id, token_index, kInstanceofRuntimeEntry);
  // Pop the two parameters supplied to the runtime entry. The result of the
  // instanceof runtime call will be left as the result of the operation.
  __ addq(RSP, Immediate(4 * kWordSize));
  if (negate_result) {
    Label negate_done;
    __ popq(RDX);
    __ LoadObject(RAX, bool_true);
    __ cmpq(RDX, RAX);
    __ j(NOT_EQUAL, &negate_done, Assembler::kNearJump);
    __ LoadObject(RAX, bool_false);
    __ Bind(&negate_done);
    __ pushq(RAX);
  }
  __ Bind(&done);
  __ popq(RAX);
}


void FlowGraphCompiler::VisitInstanceOf(InstanceOfComp* comp) {
  __ popq(RAX);
  GenerateInstanceOf(comp->node_id(),
                     comp->token_index(),
                     comp->type(),
                     comp->negate_result());
}


void FlowGraphCompiler::VisitAllocateObject(AllocateObjectComp* comp) {
  const Class& cls = Class::ZoneHandle(comp->constructor().owner());
  const Code& stub = Code::Handle(StubCode::GetAllocationStubForClass(cls));
  const ExternalLabel label(cls.ToCString(), stub.EntryPoint());
  GenerateCall(comp->token_index(), &label, PcDescriptors::kOther);
  for (intptr_t i = 0; i < comp->arguments().length(); i++) {
    __ popq(RCX);  // Discard allocation argument
  }
}


void FlowGraphCompiler::VisitCreateArray(CreateArrayComp* comp) {
  // 1. Allocate the array.  R10 = length, RBX = element type.
  __ movq(R10, Immediate(Smi::RawValue(comp->ElementCount())));
  const AbstractTypeArguments& element_type = comp->type_arguments();
  ASSERT(element_type.IsNull() || element_type.IsInstantiated());
  __ LoadObject(RBX, element_type);
  GenerateCall(comp->token_index(),
               &StubCode::AllocateArrayLabel(),
               PcDescriptors::kOther);

  // 2. Initialize the array in RAX with the element values.
  __ leaq(RCX, FieldAddress(RAX, Array::data_offset()));
  for (int i = comp->ElementCount() - 1; i >= 0; --i) {
    if (comp->ElementAt(i)->IsTemp()) {
      __ popq(Address(RCX, i * kWordSize));
    } else {
      LoadValue(RDX, comp->ElementAt(i));
      __ movq(Address(RCX, i * kWordSize), RDX);
    }
  }
}


void FlowGraphCompiler::VisitCreateClosure(CreateClosureComp* comp) {
  const Function& function = comp->function();
  const Code& stub = Code::Handle(
      StubCode::GetAllocationStubForClosure(function));
  const ExternalLabel label(function.ToCString(), stub.EntryPoint());
  GenerateCall(comp->token_index(), &label, PcDescriptors::kOther);

  const Class& cls = Class::Handle(function.signature_class());
  if (cls.HasTypeArguments()) {
    __ popq(RCX);  // Discard type arguments.
  }
  if (function.IsImplicitInstanceClosureFunction()) {
    __ popq(RCX);  // Discard receiver.
  }
}


void FlowGraphCompiler::VisitThrow(ThrowComp* comp) {
  LoadValue(RAX, comp->exception());
  __ pushq(RAX);
  GenerateCallRuntime(comp->node_id(), comp->token_index(), kThrowRuntimeEntry);
  __ int3();
}


void FlowGraphCompiler::VisitReThrow(ReThrowComp* comp) {
  LoadValue(RBX, comp->stack_trace());
  LoadValue(RAX, comp->exception());
  __ pushq(RAX);
  __ pushq(RBX);
  GenerateCallRuntime(
      comp->node_id(), comp->token_index(), kReThrowRuntimeEntry);
  Bailout("ReThrow Untested");
}


void FlowGraphCompiler::VisitNativeLoadField(NativeLoadFieldComp* comp) {
  __ popq(RAX);
  __ movq(RAX, FieldAddress(RAX, comp->offset_in_bytes()));
}


void FlowGraphCompiler::VisitExtractFactoryTypeArguments(
    ExtractFactoryTypeArgumentsComp* comp) {
  __ popq(RAX);  // Instantiator.

  // RAX is the instantiator AbstractTypeArguments object (or null).
  // If RAX is null, no need to instantiate the type arguments, use null, and
  // allocate an object of a raw type.
  const Immediate raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  Label type_arguments_instantiated, type_arguments_uninstantiated;
  __ cmpq(RAX, raw_null);
  __ j(EQUAL, &type_arguments_instantiated, Assembler::kNearJump);

  // Instantiate non-null type arguments.
  if (comp->type_arguments().IsUninstantiatedIdentity()) {
    // Check if the instantiator type argument vector is a TypeArguments of a
    // matching length and, if so, use it as the instantiated type_arguments.
    __ LoadObject(RCX, Class::ZoneHandle(Object::type_arguments_class()));
    __ cmpq(RCX, FieldAddress(RAX, Object::class_offset()));
    __ j(NOT_EQUAL, &type_arguments_uninstantiated, Assembler::kNearJump);
    Immediate arguments_length = Immediate(reinterpret_cast<int64_t>(
        Smi::New(comp->type_arguments().Length())));
    __ cmpq(FieldAddress(RAX, TypeArguments::length_offset()),
        arguments_length);
    __ j(EQUAL, &type_arguments_instantiated, Assembler::kNearJump);
  }
  __ Bind(&type_arguments_uninstantiated);
  // A runtime call to instantiate the type arguments is required before
  // calling the factory.
  __ PushObject(Object::ZoneHandle());  // Make room for the result.
  __ PushObject(comp->type_arguments());
  __ pushq(RAX);  // Push instantiator type arguments.
  GenerateCallRuntime(comp->node_id(),
                      comp->token_index(),
                      kInstantiateTypeArgumentsRuntimeEntry);
  __ popq(RAX);  // Pop instantiator type arguments.
  __ popq(RAX);  // Pop uninstantiated type arguments.
  __ popq(RAX);  // Pop instantiated type arguments.
  __ Bind(&type_arguments_instantiated);
  // RAX: Instantiated type arguments.
}


void FlowGraphCompiler::VisitExtractConstructorTypeArguments(
    ExtractConstructorTypeArgumentsComp* comp) {
  __ popq(RAX);  // Instantiator.

  // RAX is the instantiator AbstractTypeArguments object (or null).
  // If RAX is null, no need to instantiate the type arguments, use null, and
  // allocate an object of a raw type.
  // TODO(regis): The above sentence is actually not correct. If the type
  // arguments are only partially uninstantiated, we are losing type information
  // by allocating a raw type. The code needs to be fixed here and in the
  // unoptimized version (both ia32 and x64).
  const Immediate raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  Label type_arguments_instantiated, type_arguments_uninstantiated;
  __ cmpq(RAX, raw_null);
  __ j(EQUAL, &type_arguments_instantiated, Assembler::kNearJump);

  // Check if type arguments represent the uninstantiated identity vector.
  if (comp->type_arguments().IsUninstantiatedIdentity()) {
    // Check if the instantiator type argument vector is a TypeArguments of a
    // matching length and, if so, use it as the instantiated type_arguments.
    __ LoadObject(RCX, Class::ZoneHandle(Object::type_arguments_class()));
    __ cmpq(RCX, FieldAddress(RAX, Object::class_offset()));
    __ j(NOT_EQUAL, &type_arguments_uninstantiated, Assembler::kNearJump);
    Immediate arguments_length = Immediate(reinterpret_cast<int64_t>(
        Smi::New(comp->type_arguments().Length())));
    __ cmpq(FieldAddress(RAX, TypeArguments::length_offset()),
        arguments_length);
    __ j(EQUAL, &type_arguments_instantiated, Assembler::kNearJump);
  }
  __ Bind(&type_arguments_uninstantiated);
  // In the non-factory case, we rely on the allocation stub to
  // instantiate the type arguments.
  __ LoadObject(RAX, comp->type_arguments());
  // RAX: uninstantiated type arguments.
  __ Bind(&type_arguments_instantiated);
  // RAX: uninstantiated or instantiated type arguments.
}


void FlowGraphCompiler::VisitExtractConstructorInstantiator(
    ExtractConstructorInstantiatorComp* comp) {
  __ popq(RCX);  // Discard value.
  __ popq(RAX);  // Instantiator.

  // RAX is the instantiator AbstractTypeArguments object (or null).
  // If RAX is null, no need to instantiate the type arguments, use null, and
  // allocate an object of a raw type.
  // TODO(regis): The above sentence is actually not correct. If the type
  // arguments are only partially uninstantiated, we are losing type information
  // by allocating a raw type. The code needs to be fixed here and in the
  // unoptimized version (both ia32 and x64).

  // If type arguments represent the uninstantiated identity vector and if the
  // instantiator is not null, the instantiator was used as type arguments,
  // therefore, the instantiator must be reset to null here to indicate to the
  // allocator that the type arguments are instantiated.
  if (comp->type_arguments().IsUninstantiatedIdentity()) {
    // TODO(regis): The following emitted code is duplicated in
    // VisitExtractConstructorTypeArguments above. The reason is that the code
    // is split between two computations, so that each one produces a
    // single value, rather than producing a pair of values.
    // If this becomes an issue, we should expose these tests at the IL level.
    // Note that this code will still change, because bounds checking is not
    // implemented yet.
    const Immediate raw_null =
          Immediate(reinterpret_cast<intptr_t>(Object::null()));
    Label use_instantiator;
    __ cmpq(RAX, raw_null);
    __ j(EQUAL, &use_instantiator, Assembler::kNearJump);  // Already null.

    // Check if the instantiator type argument vector is a TypeArguments of a
    // matching length and, if so, use it as the instantiated type_arguments.
    __ LoadObject(RCX, Class::ZoneHandle(Object::type_arguments_class()));
    __ cmpq(RCX, FieldAddress(RAX, Object::class_offset()));
    __ j(NOT_EQUAL, &use_instantiator, Assembler::kNearJump);
    Immediate arguments_length = Immediate(reinterpret_cast<int64_t>(
        Smi::New(comp->type_arguments().Length())));
    __ cmpq(FieldAddress(RAX, TypeArguments::length_offset()),
        arguments_length);
    __ j(NOT_EQUAL, &use_instantiator, Assembler::kNearJump);
    // The instantiator was used in VisitExtractConstructorTypeArguments as the
    // instantiated type arguments, reset instantiator to null.
    __ movq(RAX, raw_null);  // Null instantiator.
    __ Bind(&use_instantiator);  // Use instantiator in RAX.
  }
  // In the non-factory case, we rely on the allocation stub to
  // instantiate the type arguments.
  // RAX: instantiator or null.
}


void FlowGraphCompiler::VisitBlocks(
    const GrowableArray<BlockEntryInstr*>& blocks) {
  for (intptr_t i = blocks.length() - 1; i >= 0; --i) {
    // Compile the block entry.
    current_block_ = blocks[i];
    Instruction* instr = current_block()->Accept(this);
    // Compile all successors until an exit, branch, or a block entry.
    while ((instr != NULL) && !instr->IsBlockEntry()) {
      instr = instr->Accept(this);
    }

    BlockEntryInstr* successor =
        (instr == NULL) ? NULL : instr->AsBlockEntry();
    if (successor != NULL) {
      // Block ended with a "goto".  We can fall through if it is the
      // next block in the list.  Otherwise, we need a jump.
      if (i == 0 || (blocks[i - 1] != successor)) {
        __ jmp(&block_info_[successor->block_number()]->label);
      }
    }
  }
}


void FlowGraphCompiler::VisitJoinEntry(JoinEntryInstr* instr) {
  __ Bind(&block_info_[instr->block_number()]->label);
}


void FlowGraphCompiler::VisitTargetEntry(TargetEntryInstr* instr) {
  __ Bind(&block_info_[instr->block_number()]->label);
}


void FlowGraphCompiler::VisitPickTemp(PickTempInstr* instr) {
  // Semantics is to copy a stack-allocated temporary to the top of stack.
  // Destination index d is assumed the new top of stack after the
  // operation, so d-1 is the current top of stack and so d-s-1 is the
  // offset to source index s.
  intptr_t offset = instr->destination() - instr->source() - 1;
  ASSERT(offset >= 0);
  __ pushq(Address(RSP, offset * kWordSize));
}


void FlowGraphCompiler::VisitTuckTemp(TuckTempInstr* instr) {
  // Semantics is to assign to a stack-allocated temporary a copy of the top
  // of stack.  Source index s is assumed the top of stack, s-d is the
  // offset to destination index d.
  intptr_t offset = instr->source() - instr->destination();
  ASSERT(offset >= 0);
  __ movq(RAX, Address(RSP, 0));
  __ movq(Address(RSP, offset * kWordSize), RAX);
}


void FlowGraphCompiler::VisitDo(DoInstr* instr) {
  instr->computation()->Accept(this);
}


void FlowGraphCompiler::VisitBind(BindInstr* instr) {
  instr->computation()->Accept(this);
  __ pushq(RAX);
}


void FlowGraphCompiler::VisitReturn(ReturnInstr* instr) {
  LoadValue(RAX, instr->value());

#ifdef DEBUG
  // Check that the entry stack size matches the exit stack size.
  __ movq(R10, RBP);
  __ subq(R10, RSP);
  __ cmpq(R10, Immediate(StackSize() * kWordSize));
  Label stack_ok;
  __ j(EQUAL, &stack_ok, Assembler::kNearJump);
  __ Stop("Exit stack size does not match the entry stack size.");
  __ Bind(&stack_ok);
#endif  // DEBUG.

  if (FLAG_trace_functions) {
    __ pushq(RAX);  // Preserve result.
    const Function& function =
        Function::ZoneHandle(parsed_function_.function().raw());
    __ LoadObject(RBX, function);
    __ pushq(RBX);
    GenerateCallRuntime(AstNode::kNoId,
                        0,
                        kTraceFunctionExitRuntimeEntry);
    __ popq(RAX);  // Remove argument.
    __ popq(RAX);  // Restore result.
  }
  __ LeaveFrame();
  __ ret();

  // Generate 8 bytes of NOPs so that the debugger can patch the
  // return pattern with a call to the debug stub.
  __ nop(1);
  __ nop(1);
  __ nop(1);
  __ nop(1);
  __ nop(1);
  __ nop(1);
  __ nop(1);
  __ nop(1);
  AddCurrentDescriptor(PcDescriptors::kReturn,
                       AstNode::kNoId,
                       instr->token_index());
}


void FlowGraphCompiler::VisitBranch(BranchInstr* instr) {
  // Determine if the true branch is fall through (!negated) or the false
  // branch is.  They cannot both be backwards branches.
  intptr_t index = blocks_->length() - current_block()->block_number() - 1;
  ASSERT(index > 0);

  bool negated = ((*blocks_)[index - 1] == instr->false_successor());
  ASSERT(!negated == ((*blocks_)[index - 1] == instr->true_successor()));

  LoadValue(RAX, instr->value());
  __ LoadObject(RDX, Bool::ZoneHandle(Bool::True()));
  __ cmpq(RAX, RDX);
  if (negated) {
    __ j(EQUAL, &block_info_[instr->true_successor()->block_number()]->label);
  } else {
    __ j(NOT_EQUAL,
         &block_info_[instr->false_successor()->block_number()]->label);
  }
}


// Coped from CodeGenerator::CopyParameters (CodeGenerator will be deprecated).
void FlowGraphCompiler::CopyParameters() {
  const Function& function = parsed_function_.function();
  LocalScope* scope = parsed_function_.node_sequence()->scope();
  const int num_fixed_params = function.num_fixed_parameters();
  const int num_opt_params = function.num_optional_parameters();
  ASSERT(parsed_function_.first_parameter_index() == -1);
  // Copy positional arguments.
  // Check that no fewer than num_fixed_params positional arguments are passed
  // in and that no more than num_params arguments are passed in.
  // Passed argument i at fp[1 + argc - i] copied to fp[-1 - i].
  const int num_params = num_fixed_params + num_opt_params;

  // Total number of args is the first Smi in args descriptor array (R10).
  __ movq(RBX, FieldAddress(R10, Array::data_offset()));
  // Check that num_args <= num_params.
  Label wrong_num_arguments;
  __ cmpq(RBX, Immediate(Smi::RawValue(num_params)));
  __ j(GREATER, &wrong_num_arguments);
  // Number of positional args is the second Smi in descriptor array (R10).
  __ movq(RCX, FieldAddress(R10, Array::data_offset() + (1 * kWordSize)));
  // Check that num_pos_args >= num_fixed_params.
  __ cmpq(RCX, Immediate(Smi::RawValue(num_fixed_params)));
  __ j(LESS, &wrong_num_arguments);
  // Since RBX and RCX are Smi, use TIMES_4 instead of TIMES_8.
  // Let RBX point to the last passed positional argument, i.e. to
  // fp[1 + num_args - (num_pos_args - 1)].
  __ subq(RBX, RCX);
  __ leaq(RBX, Address(RBP, RBX, TIMES_4, 2 * kWordSize));
  // Let RDI point to the last copied positional argument, i.e. to
  // fp[-1 - (num_pos_args - 1)].
  __ SmiUntag(RCX);
  __ movq(RAX, RCX);
  __ negq(RAX);
  __ leaq(RDI, Address(RBP, RAX, TIMES_8, 0));
  Label loop, loop_condition;
  __ jmp(&loop_condition, Assembler::kNearJump);
  // We do not use the final allocation index of the variable here, i.e.
  // scope->VariableAt(i)->index(), because captured variables still need
  // to be copied to the context that is not yet allocated.
  const Address argument_addr(RBX, RCX, TIMES_8, 0);
  const Address copy_addr(RDI, RCX, TIMES_8, 0);
  __ Bind(&loop);
  __ movq(RAX, argument_addr);
  __ movq(copy_addr, RAX);
  __ Bind(&loop_condition);
  __ decq(RCX);
  __ j(POSITIVE, &loop, Assembler::kNearJump);

  // Copy or initialize optional named arguments.
  ASSERT(num_opt_params > 0);  // Or we would not have to copy arguments.
  // Start by alphabetically sorting the names of the optional parameters.
  LocalVariable** opt_param = new LocalVariable*[num_opt_params];
  int* opt_param_position = new int[num_opt_params];
  for (int pos = num_fixed_params; pos < num_params; pos++) {
    LocalVariable* parameter = scope->VariableAt(pos);
    const String& opt_param_name = parameter->name();
    int i = pos - num_fixed_params;
    while (--i >= 0) {
      LocalVariable* param_i = opt_param[i];
      const intptr_t result = opt_param_name.CompareTo(param_i->name());
      ASSERT(result != 0);
      if (result > 0) break;
      opt_param[i + 1] = opt_param[i];
      opt_param_position[i + 1] = opt_param_position[i];
    }
    opt_param[i + 1] = parameter;
    opt_param_position[i + 1] = pos;
  }
  // Generate code handling each optional parameter in alphabetical order.
  // Total number of args is the first Smi in args descriptor array (R10).
  __ movq(RBX, FieldAddress(R10, Array::data_offset()));
  // Number of positional args is the second Smi in descriptor array (R10).
  __ movq(RCX, FieldAddress(R10, Array::data_offset() + (1 * kWordSize)));
  __ SmiUntag(RCX);
  // Let RBX point to the first passed argument, i.e. to fp[1 + argc - 0].
  __ leaq(RBX, Address(RBP, RBX, TIMES_4, kWordSize));  // RBX is Smi.
  // Let EDI point to the name/pos pair of the first named argument.
  __ leaq(RDI, FieldAddress(R10, Array::data_offset() + (2 * kWordSize)));
  for (int i = 0; i < num_opt_params; i++) {
    // Handle this optional parameter only if k or fewer positional arguments
    // have been passed, where k is the position of this optional parameter in
    // the formal parameter list.
    Label load_default_value, assign_optional_parameter, next_parameter;
    const int param_pos = opt_param_position[i];
    __ cmpq(RCX, Immediate(param_pos));
    __ j(GREATER, &next_parameter, Assembler::kNearJump);
    // Check if this named parameter was passed in.
    __ movq(RAX, Address(RDI, 0));  // Load RAX with the name of the argument.
    __ CompareObject(RAX, opt_param[i]->name());
    __ j(NOT_EQUAL, &load_default_value, Assembler::kNearJump);
    // Load RAX with passed-in argument at provided arg_pos, i.e. at
    // fp[1 + argc - arg_pos].
    __ movq(RAX, Address(RDI, kWordSize));  // RAX is arg_pos as Smi.
    __ addq(RDI, Immediate(2 * kWordSize));  // Point to next name/pos pair.
    __ negq(RAX);
    Address argument_addr(RBX, RAX, TIMES_4, 0);  // RAX is a negative Smi.
    __ movq(RAX, argument_addr);
    __ jmp(&assign_optional_parameter, Assembler::kNearJump);
    __ Bind(&load_default_value);
    // Load RAX with default argument at pos.
    const Object& value = Object::ZoneHandle(
        parsed_function_.default_parameter_values().At(
            param_pos - num_fixed_params));
    __ LoadObject(RAX, value);
    __ Bind(&assign_optional_parameter);
    // Assign RAX to fp[-1 - param_pos].
    // We do not use the final allocation index of the variable here, i.e.
    // scope->VariableAt(i)->index(), because captured variables still need
    // to be copied to the context that is not yet allocated.
    const Address param_addr(RBP, (-1 - param_pos) * kWordSize);
    __ movq(param_addr, RAX);
    __ Bind(&next_parameter);
  }
  delete[] opt_param;
  delete[] opt_param_position;
  // Check that RDI now points to the null terminator in the array descriptor.
  const Immediate raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  Label all_arguments_processed;
  __ cmpq(Address(RDI, 0), raw_null);
  __ j(EQUAL, &all_arguments_processed, Assembler::kNearJump);

  __ Bind(&wrong_num_arguments);
  if (function.IsClosureFunction()) {
    GenerateCallRuntime(AstNode::kNoId,
                        0,
                        kClosureArgumentMismatchRuntimeEntry);
  } else {
    // Invoke noSuchMethod function.
    const int kNumArgsChecked = 1;
    ICData& ic_data = ICData::ZoneHandle();
    ic_data = ICData::New(parsed_function_.function(),
                          String::Handle(function.name()),
                          AstNode::kNoId,
                          kNumArgsChecked);
    __ LoadObject(RBX, ic_data);
    // RBP : points to previous frame pointer.
    // RBP + 8 : points to return address.
    // RBP + 16 : address of last argument (arg n-1).
    // RSP + 16 + 8*(n-1) : address of first argument (arg 0).
    // RBX : ic-data.
    // R10 : arguments descriptor array.
    __ call(&StubCode::CallNoSuchMethodFunctionLabel());
  }

  if (FLAG_trace_functions) {
    __ pushq(RAX);  // Preserve result.
    __ PushObject(Function::ZoneHandle(function.raw()));
    GenerateCallRuntime(AstNode::kNoId,
                        0,
                        kTraceFunctionExitRuntimeEntry);
    __ popq(RAX);  // Remove argument.
    __ popq(RAX);  // Restore result.
  }
  __ LeaveFrame();
  __ ret();

  __ Bind(&all_arguments_processed);
  // Nullify originally passed arguments only after they have been copied and
  // checked, otherwise noSuchMethod would not see their original values.
  // This step can be skipped in case we decide that formal parameters are
  // implicitly final, since garbage collecting the unmodified value is not
  // an issue anymore.

  // R10 : arguments descriptor array.
  // Total number of args is the first Smi in args descriptor array (R10).
  __ movq(RCX, FieldAddress(R10, Array::data_offset()));
  __ SmiUntag(RCX);
  Label null_args_loop, null_args_loop_condition;
  __ jmp(&null_args_loop_condition, Assembler::kNearJump);
  const Address original_argument_addr(RBP, RCX, TIMES_8, 2 * kWordSize);
  __ Bind(&null_args_loop);
  __ movq(original_argument_addr, raw_null);
  __ Bind(&null_args_loop_condition);
  __ decq(RCX);
  __ j(POSITIVE, &null_args_loop, Assembler::kNearJump);
}


// TODO(srdjan): Investigate where to put the argument type checks for
// checked mode.
void FlowGraphCompiler::CompileGraph() {
  // Specialized version of entry code from CodeGenerator::GenerateEntryCode.
  const Function& function = parsed_function_.function();

  const int parameter_count = function.num_fixed_parameters();
  const int num_copied_params = parsed_function_.copied_parameter_count();
  const int local_count = parsed_function_.stack_local_count();
  __ EnterFrame(StackSize() * kWordSize);

  // We check the number of passed arguments when we have to copy them due to
  // the presence of optional named parameters.
  // No such checking code is generated if only fixed parameters are declared,
  // unless we are debug mode or unless we are compiling a closure.
  if (num_copied_params == 0) {
#ifdef DEBUG
    const bool check_arguments = true;
#else
    const bool check_arguments = function.IsClosureFunction();
#endif
    if (check_arguments) {
      // Check that num_fixed <= argc <= num_params.
      Label argc_in_range;
      // Total number of args is the first Smi in args descriptor array (R10).
      __ movq(RAX, FieldAddress(R10, Array::data_offset()));
      __ cmpq(RAX, Immediate(Smi::RawValue(parameter_count)));
      __ j(EQUAL, &argc_in_range, Assembler::kNearJump);
      if (function.IsClosureFunction()) {
        GenerateCallRuntime(AstNode::kNoId,
                            function.token_index(),
                            kClosureArgumentMismatchRuntimeEntry);
      } else {
        __ Stop("Wrong number of arguments");
      }
      __ Bind(&argc_in_range);
    }
  } else {
    CopyParameters();
  }

  // Initialize locals to null.
  if (local_count > 0) {
    __ movq(RAX, Immediate(reinterpret_cast<intptr_t>(Object::null())));
    const int base = parsed_function_.first_stack_local_index();
    for (int i = 0; i < local_count; ++i) {
      // Subtract index i (locals lie at lower addresses than RBP).
      __ movq(Address(RBP, (base - i) * kWordSize), RAX);
    }
  }

  // Generate stack overflow check.
  __ movq(TMP, Immediate(Isolate::Current()->stack_limit_address()));
  __ cmpq(RSP, Address(TMP, 0));
  Label no_stack_overflow;
  __ j(ABOVE, &no_stack_overflow, Assembler::kNearJump);
  GenerateCallRuntime(AstNode::kNoId,
                      function.token_index(),
                      kStackOverflowRuntimeEntry);
  __ Bind(&no_stack_overflow);

  if (FLAG_print_scopes) {
    // Print the function scope (again) after generating the prologue in order
    // to see annotations such as allocation indices of locals.
    if (FLAG_print_ast) {
      // Second printing.
      OS::Print("Annotated ");
    }
    AstPrinter::PrintFunctionScope(parsed_function_);
  }

  VisitBlocks(*blocks_);

  __ int3();
  // Emit function patching code. This will be swapped with the first 13 bytes
  // at entry point.
  pc_descriptors_list_->AddDescriptor(PcDescriptors::kPatchCode,
                                      assembler_->CodeSize(),
                                      AstNode::kNoId,
                                      0,
                                      -1);
  __ jmp(&StubCode::FixCallersTargetLabel());
}


// Infrastructure copied from class CodeGenerator.
void FlowGraphCompiler::GenerateCall(intptr_t token_index,
                                     const ExternalLabel* label,
                                     PcDescriptors::Kind kind) {
  __ call(label);
  AddCurrentDescriptor(kind, AstNode::kNoId, token_index);
}


void FlowGraphCompiler::GenerateCallRuntime(intptr_t node_id,
                                            intptr_t token_index,
                                            const RuntimeEntry& entry) {
  __ CallRuntimeFromDart(entry);
  AddCurrentDescriptor(PcDescriptors::kOther, node_id, token_index);
}


// Uses current pc position and try-index.
void FlowGraphCompiler::AddCurrentDescriptor(PcDescriptors::Kind kind,
                                             intptr_t node_id,
                                             intptr_t token_index) {
  pc_descriptors_list_->AddDescriptor(kind,
                                      assembler_->CodeSize(),
                                      node_id,
                                      token_index,
                                      CatchClauseNode::kInvalidTryIndex);
}


void FlowGraphCompiler::FinalizePcDescriptors(const Code& code) {
  ASSERT(pc_descriptors_list_ != NULL);
  const PcDescriptors& descriptors = PcDescriptors::Handle(
      pc_descriptors_list_->FinalizePcDescriptors(code.EntryPoint()));
  descriptors.Verify(parsed_function_.function().is_optimizable());
  code.set_pc_descriptors(descriptors);
}


void FlowGraphCompiler::FinalizeVarDescriptors(const Code& code) {
  const LocalVarDescriptors& var_descs = LocalVarDescriptors::Handle(
          parsed_function_.node_sequence()->scope()->GetVarDescriptors());
  code.set_var_descriptors(var_descs);
}


void FlowGraphCompiler::FinalizeExceptionHandlers(const Code& code) {
  // We don't compile exception handlers yet.
  code.set_exception_handlers(
      ExceptionHandlers::Handle(ExceptionHandlers::New(0)));
}


}  // namespace dart

#endif  // defined TARGET_ARCH_X64
