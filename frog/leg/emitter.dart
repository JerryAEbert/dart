// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Generates the code for all used classes in the program. Static fields (even
 * in classes) are ignored, since they can be treated as non-class elements.
 *
 * The code for the containing (used) methods must exist in the [:universe:].
 */
class CodeEmitterTask extends CompilerTask {
  static final String INHERIT_FUNCTION = '''
function(child, parent) {
  if (child.prototype.__proto__) {
    child.prototype.__proto__ = parent.prototype;
  } else {
    function tmp() {};
    tmp.prototype = parent.prototype;
    child.prototype = new tmp();
    child.prototype.constructor = child;
  }
}''';

  bool addedInheritFunction = false;
  final Namer namer;

  CodeEmitterTask(Compiler compiler) : namer = compiler.namer, super(compiler);
  String get name() => 'CodeEmitter';

  String get inheritsName() => '${compiler.namer.ISOLATE}.\$inherits';

  void addInheritFunctionIfNecessary(StringBuffer buffer) {
    if (addedInheritFunction) return;
    addedInheritFunction = true;
    buffer.add('$inheritsName = ');
    buffer.add(INHERIT_FUNCTION);
    buffer.add(';\n');
  }

  void addInstanceMember(Element member,
                         String prototype,
                         StringBuffer buffer) {
    assert(member.isInstanceMember());
    if (member.kind === ElementKind.FUNCTION
        || member.kind === ElementKind.GENERATIVE_CONSTRUCTOR_BODY) {
      String codeBlock = compiler.universe.generatedCode[member];
      if (codeBlock !== null) {
        buffer.add('$prototype.${namer.getName(member)} = $codeBlock;\n');
      }
      codeBlock = compiler.universe.generatedBailoutCode[member];
      if (codeBlock !== null) {
        String name = namer.getBailoutName(member);
        buffer.add('$prototype.$name = $codeBlock;\n');
      }
    } else {
      // TODO(ngeoffray): Have another class generate the code for the
      // fields.
      assert(member.kind === ElementKind.FIELD);
      if (compiler.universe.invokedSetters.contains(member.name.stringValue)) {
        String setterName = namer.setterName(member.name);
        buffer.add('$prototype.$setterName = function(v){\n' +
          '  this.${namer.getName(member)} = v;\n}\n');
      }
      if (compiler.universe.invokedGetters.contains(member.name.stringValue)) {
        String getterName = namer.getterName(member.name);
        buffer.add('$prototype.$getterName = function(){\n' +
          '  return this.${namer.getName(member)};\n}\n');
      }
    }
  }

  bool generateFieldInits(ClassElement classElement,
                          StringBuffer argumentsBuffer,
                          StringBuffer bodyBuffer) {
    bool isFirst = true;
    do {
      // TODO(floitsch): make sure there are no name clashes.
      String className = namer.getName(classElement);
      for (Element member in classElement.members) {
        if (member.isInstanceMember() && member.kind == ElementKind.FIELD) {
          if (!isFirst) argumentsBuffer.add(', ');
          isFirst = false;
          String memberName = namer.instanceName(member.name);
          argumentsBuffer.add('${className}_$memberName');
          bodyBuffer.add('  this.$memberName = ${className}_$memberName;\n');
        }
      }
      classElement = classElement.superClass;
    } while(classElement !== null);
  }

  void generateClass(ClassElement classElement,
                     StringBuffer buffer,
                     Set<ClassElement> seenClasses) {
    if (seenClasses.contains(classElement)) return;
    seenClasses.add(classElement);
    ClassElement superClass = classElement.superClass;
    if (superClass !== null) {
      generateClass(classElement.superClass, buffer, seenClasses);
    }

    String className = namer.isolatePropertyAccess(classElement);
    buffer.add('$className = function ${classElement.name}(');
    StringBuffer bodyBuffer = new StringBuffer();
    generateFieldInits(classElement, buffer, bodyBuffer);
    buffer.add(') {\n');
    buffer.add(bodyBuffer);
    buffer.add('};\n');
    if (superClass !== null) {
      addInheritFunctionIfNecessary(buffer);
      String superName = namer.isolatePropertyAccess(superClass);
      buffer.add('${inheritsName}($className, $superName);\n');
    }
    String prototype = '$className.prototype';

    for (Element member in classElement.members) {
      if (member.isInstanceMember()) {
        addInstanceMember(member, prototype, buffer);
      }
    }
    for (Element member in classElement.backendMembers) {
      if (member.isInstanceMember()) {
        addInstanceMember(member, prototype, buffer);
      }
    }
    buffer.add('$prototype.${namer.operatorIs(classElement)} = true;\n');
  }

  void emitClasses(StringBuffer buffer) {
    Set seenClasses = new Set<ClassElement>();
    for (ClassElement element in compiler.universe.instantiatedClasses) {
      generateClass(element, buffer, seenClasses);
    }
  }

  void emitStaticFunctionsWithNamer(StringBuffer buffer,
                                    Map<Element, String> generatedCode,
                                    String functionNamer(Element element)) {
    generatedCode.forEach((Element element, String codeBlock) {
      if (!element.isInstanceMember()) {
        buffer.add('${functionNamer(element)} = ');
        buffer.add(codeBlock);
        buffer.add(';\n\n');
      }
    });
  }

  void emitStaticFunctions(StringBuffer buffer) {
    emitStaticFunctionsWithNamer(buffer,
                                 compiler.universe.generatedCode,
                                 namer.isolatePropertyAccess);
    emitStaticFunctionsWithNamer(buffer,
                                 compiler.universe.generatedBailoutCode,
                                 namer.isolateBailoutPropertyAccess);
  }

  void emitStaticNonFinalFieldInitializations(StringBuffer buffer) {
    // Adds initializations inside the Isolate constructor.
    // Example:
    //    function Isolate() {
    //       this.staticNonFinal = Isolate.prototype.someVal;
    //       ...
    //    }
    CompileTimeConstantHandler constants = compiler.compileTimeConstantHandler;
    List<VariableElement> staticNonFinalFields =
        constants.getStaticNonFinalFieldsForEmission();
    if (!staticNonFinalFields.isEmpty()) buffer.add('\n');
    for (Element element in staticNonFinalFields) {
      buffer.add('  this.${namer.getName(element)} = ');
      constants.emitJsCodeForField(element, buffer);
      buffer.add(';\n');
    }
  }

  void emitStaticFinalFieldInitializations(StringBuffer buffer) {
    CompileTimeConstantHandler constants = compiler.compileTimeConstantHandler;
    List<VariableElement> staticFinalFields =
        constants.getStaticFinalFieldsForEmission();
    for (VariableElement element in staticFinalFields) {
      buffer.add('${namer.isolatePropertyAccess(element)} = ');
      constants.emitJsCodeForField(element, buffer);
      buffer.add(';\n');
    }
  }

  String assembleProgram() {
    measure(() {
      StringBuffer buffer = new StringBuffer();
      buffer.add('function ${namer.ISOLATE}() {');
      emitStaticNonFinalFieldInitializations(buffer);
      buffer.add('}\n\n');
      emitClasses(buffer);
      emitStaticFunctions(buffer);
      emitStaticFinalFieldInitializations(buffer);
      buffer.add('var ${namer.CURRENT_ISOLATE} = new ${namer.ISOLATE}();\n');
      buffer.add('${namer.CURRENT_ISOLATE}.main();\n');
      compiler.assembledCode = buffer.toString();
    });
    return compiler.assembledCode;
  }
}
