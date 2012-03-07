// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface TreeElements {
  Element operator[](Node node);
  Selector getSelector(Send send);
}

class TreeElementMapping implements TreeElements {
  Map<Node, Element> map;
  Map<Send, Selector> selectors;
  TreeElementMapping()
    : map = new LinkedHashMap<Node, Element>(),
      selectors = new LinkedHashMap<Send, Selector>();

  operator []=(Node node, Element element) => map[node] = element;
  operator [](Node node) => map[node];
  void remove(Node node) { map.remove(node); }

  void setSelector(Send send, Selector selector) {
    selectors[send] = selector;
  }

  Selector getSelector(Send send) => selectors[send];
}

class ResolverTask extends CompilerTask {
  Queue<ClassElement> toResolve;

  // Caches the elements of analyzed constructors to make them available
  // for inlining in later tasks.
  Map<FunctionElement, TreeElements> constructorElements;

  ResolverTask(Compiler compiler)
    : super(compiler), toResolve = new Queue<ClassElement>(),
      constructorElements = new Map<FunctionElement, TreeElements>();

  String get name() => 'Resolver';

  TreeElements resolve(Element element) {
    return measure(() {
      switch (element.kind) {
        case ElementKind.GENERATIVE_CONSTRUCTOR:
        case ElementKind.FUNCTION:
        case ElementKind.GETTER:
        case ElementKind.SETTER:
          return resolveMethodElement(element);

        case ElementKind.FIELD:
        case ElementKind.PARAMETER:
          return resolveVariableElement(element);

        default:
          compiler.unimplemented(
              "resolver", node: element.parseNode(compiler));
      }
    });
  }

  SourceString getConstructorName(Send node) {
    if (node.receiver !== null) {
      return node.selector.asIdentifier().source;
    } else {
      return const SourceString('');
    }
  }

  FunctionElement lookupConstructor(ClassElement classElement, Send send,
                                    [noConstructor(Element)]) {
    final SourceString constructorName = getConstructorName(send);
    final SourceString className = classElement.name;
    FunctionElement result = classElement.lookupConstructor(className,
                                                            constructorName,
                                                            noConstructor);
    if (result === null && send.arguments.isEmpty()) {
      result = classElement.getSynthesizedConstructor();
    }
    return result;
  }

  FunctionElement resolveConstructorRedirection(FunctionElement constructor) {
    FunctionExpression node = constructor.parseNode(compiler);
    // A synthetic constructor does not have a node.
    if (node === null) return null;
    if (node.initializers === null) return null;
    Link<Node> initializers = node.initializers.nodes;
    if (!initializers.isEmpty() &&
        Initializers.isConstructorRedirect(initializers.head)) {
      return lookupConstructor(constructor.enclosingElement, initializers.head);
    }
    return null;
  }

  void resolveRedirectingConstructor(InitializerResolver resolver,
                                     Node node,
                                     FunctionElement constructor,
                                     FunctionElement redirection) {
    Set<FunctionElement> seen = new Set<FunctionElement>();
    seen.add(constructor);
    while (redirection !== null) {
      if (seen.contains(redirection)) {
        resolver.visitor.error(node, MessageKind.REDIRECTING_CONSTRUCTOR_CYCLE);
        return;
      }
      seen.add(redirection);
      redirection = resolveConstructorRedirection(redirection);
    }
  }

  TreeElements resolveMethodElement(FunctionElement element) {
    return compiler.withCurrentElement(element, () {
      bool isConstructor = element.kind === ElementKind.GENERATIVE_CONSTRUCTOR;
      if (constructorElements.containsKey(element)) {
        assert(isConstructor);
        TreeElements elements = constructorElements[element];
        if (elements !== null) return elements;
      }
      FunctionExpression tree = element.parseNode(compiler);
      if (isConstructor) {
        resolveConstructorImplementation(element, tree);
      }
      ResolverVisitor visitor = new ResolverVisitor(compiler, element);
      visitor.useElement(tree, element);
      visitor.setupFunction(tree, element);

      if (tree.initializers != null) {
        if (!isConstructor) {
          error(tree, MessageKind.FUNCTION_WITH_INITIALIZER);
        }
        InitializerResolver resolver = new InitializerResolver(visitor);
        FunctionElement redirection =
            resolver.resolveInitializers(element, tree);
        if (redirection !== null) {
          resolveRedirectingConstructor(resolver, tree, element, redirection);
        }
      }
      visitor.visit(tree.body);

      // Resolve the type annotations encountered in the method.
      Link<ClassElement> newResolvedClasses = const EmptyLink<ClassElement>();
      while (!toResolve.isEmpty()) {
        ClassElement classElement = toResolve.removeFirst();
        if (!classElement.isResolved) {
          classElement.resolve(compiler);
        }
        newResolvedClasses = newResolvedClasses.prepend(classElement);
      }
      checkClassHierarchy(newResolvedClasses);
      if (isConstructor) {
        constructorElements[element] = visitor.mapping;
      }
      return visitor.mapping;
    });
  }

  void resolveConstructorImplementation(FunctionElement constructor,
                                        FunctionExpression node) {
    assert(constructor.defaultImplementation === constructor);
    ClassElement intrface = constructor.enclosingElement;
    if (!intrface.isInterface()) return;
    Type defaultType = intrface.defaultClass;
    if (defaultType === null) {
      error(node, MessageKind.NO_DEFAULT_CLASS, [intrface.name]);
    }
    ClassElement defaultClass = defaultType.element;
    defaultClass.resolve(compiler);
    if (defaultClass.isInterface()) {
      error(node, MessageKind.CANNOT_INSTANTIATE_INTERFACE,
            [defaultClass.name]);
    }
    // We have now established the following:
    // [intrface] is an interface, let's say "MyInterface".
    // [defaultClass] is a class, let's say "MyClass".

    // First look up the constructor named "MyInterface.name".
    constructor.defaultImplementation =
      defaultClass.lookupConstructor(constructor.name);

    // If that fails, try looking up "MyClass.name".
    if (constructor.defaultImplementation === null) {
      SourceString name =
          new SourceString(constructor.name.slowToString().replaceFirst(
              intrface.name.slowToString(),
              defaultClass.name.slowToString()));
      constructor.defaultImplementation = defaultClass.lookupConstructor(name);

      if (constructor.defaultImplementation === null
          && name == defaultClass.name
          && constructor.computeParameters(compiler).parameterCount === 0) {
        constructor.defaultImplementation =
            defaultClass.getSynthesizedConstructor();
      }

      if (constructor.defaultImplementation === null) {
        // We failed find a constrcutor named either
        // "MyInterface.name" or "MyClass.name".
        error(node, MessageKind.CANNOT_FIND_CONSTRUCTOR2,
              [constructor.name, name]);
      }
    }
  }

  TreeElements resolveVariableElement(Element element) {
    Node tree = element.parseNode(compiler);
    ResolverVisitor visitor = new ResolverVisitor(compiler, element);
    if (tree is SendSet) {
      SendSet send = tree;
      visitor.visit(send.arguments.head);
    }
    return visitor.mapping;
  }

  Type resolveType(ClassElement element) {
    return measure(() {
      ClassNode tree = element.parseNode(compiler);
      ClassResolverVisitor visitor =
        new ClassResolverVisitor(compiler, element.getLibrary());
      return visitor.visit(tree);
    });
  }

  FunctionParameters resolveSignature(FunctionElement element) {
    return measure(() => SignatureResolver.analyze(compiler, element));
  }

  void checkClassHierarchy(Link<ClassElement> classes) {
    for(; !classes.isEmpty(); classes = classes.tail) {
      ClassElement classElement = classes.head;
      calculateAllSupertypes(classElement, new Set<ClassElement>());
    }
  }

  Link<Type> getOrCalculateAllSupertypes(ClassElement classElement,
                                         [Set<ClassElement> seen]) {
    Link<Type> allSupertypes = classElement.allSupertypes;
    if (allSupertypes !== null) return allSupertypes;
    if (seen === null) seen = new Set<ClassElement>();
    calculateAllSupertypes(classElement, seen);
    return classElement.allSupertypes;
  }

  void calculateAllSupertypes(ClassElement classElement,
                              Set<ClassElement> seen) {
    // TODO(karlklose): substitute type variables.
    // TODO(karlklose): check if type arguments match, if a classelement occurs
    //                  more than once in the supertypes.
    if (classElement.allSupertypes !== null) return;
    final Type supertype = classElement.supertype;
    if (seen.contains(classElement)) {
      error(classElement.parseNode(compiler),
            MessageKind.CYCLIC_CLASS_HIERARCHY,
            [classElement.name]);
      classElement.allSupertypes = const EmptyLink<Type>();
    } else if (supertype != null) {
      seen.add(classElement);
      Link<Type> superSupertypes =
        getOrCalculateAllSupertypes(supertype.element, seen);
      Link<Type> supertypes = new Link<Type>(supertype, superSupertypes);
      for (Link<Type> interfaces = classElement.interfaces;
           !interfaces.isEmpty();
           interfaces = interfaces.tail) {
        Element element = interfaces.head.element;
        Link<Type> interfaceSupertypes =
            getOrCalculateAllSupertypes(element, seen);
        supertypes = supertypes.reversePrependAll(interfaceSupertypes);
        supertypes = supertypes.prepend(interfaces.head);
      }
      seen.remove(classElement);
      classElement.allSupertypes = supertypes;
    } else {
      classElement.allSupertypes = const EmptyLink<Type>();
    }
  }

  error(Node node, MessageKind kind, [arguments = const []]) {
    ResolutionError message = new ResolutionError(kind, arguments);
    compiler.reportError(node, message);
  }
}

class InitializerResolver {
  final ResolverVisitor visitor;
  final Map<SourceString, Node> initialized;
  Link<Node> initializers;
  bool hasSuper;

  InitializerResolver(this.visitor)
    : initialized = new Map<SourceString, Node>(), hasSuper = false;

  error(Node node, MessageKind kind, [arguments = const []]) {
    visitor.error(node, kind, arguments);
  }

  warning(Node node, MessageKind kind, [arguments = const []]) {
    visitor.warning(node, kind, arguments);
  }

  bool isFieldInitializer(SendSet node) {
    if (node.selector.asIdentifier() == null) return false;
    if (node.receiver == null) return true;
    if (node.receiver.asIdentifier() == null) return false;
    return node.receiver.asIdentifier().isThis();
  }

  void resolveFieldInitializer(FunctionElement constructor, SendSet init) {
    // init is of the form [this.]field = value.
    final Node selector = init.selector;
    final SourceString name = selector.asIdentifier().source;
    // Lookup target field.
    Element target;
    if (isFieldInitializer(init)) {
      final ClassElement classElement = constructor.enclosingElement;
      target = classElement.lookupLocalMember(name);
      if (target === null) {
        error(selector, MessageKind.CANNOT_RESOLVE, [name]);
      } else if (target.kind != ElementKind.FIELD) {
        error(selector, MessageKind.NOT_A_FIELD, [name]);
      } else if (!target.isInstanceMember()) {
        error(selector, MessageKind.INIT_STATIC_FIELD, [name]);
      }
    } else {
      error(init, MessageKind.INVALID_RECEIVER_IN_INITIALIZER);
    }
    visitor.useElement(init, target);
    // Check for duplicate initializers.
    if (initialized.containsKey(name)) {
      error(init, MessageKind.DUPLICATE_INITIALIZER, [name]);
      warning(initialized[name], MessageKind.ALREADY_INITIALIZED, [name]);
    }
    initialized[name] = init;
    // Resolve initializing value.
    visitor.visitInStaticContext(init.arguments.head);
  }

  Element resolveSuperOrThis(FunctionElement constructor,
                             FunctionExpression functionNode,
                             Send call) {
    noConstructor(e) {
      if (e !== null) error(call, MessageKind.NO_CONSTRUCTOR, [e.name, e.kind]);
    }

    ClassElement lookupTarget = constructor.enclosingElement;
    bool validTarget = true;
    FunctionElement result;
    if (Initializers.isSuperConstructorCall(call)) {
      // Check for invalid initializers.
      if (hasSuper) {
        error(call, MessageKind.DUPLICATE_SUPER_INITIALIZER);
      }
      hasSuper = true;
      // Calculate correct lookup target and constructor name.
      if (lookupTarget.name == Types.OBJECT) {
        error(call, MessageKind.SUPER_INITIALIZER_IN_OBJECT);
      } else {
        lookupTarget = lookupTarget.supertype.element;
      }
    } else if (Initializers.isConstructorRedirect(call)) {
      // Check that there is no body (Language specification 7.5.1).
      if (functionNode.hasBody()) {
        error(functionNode, MessageKind.REDIRECTING_CONSTRUCTOR_HAS_BODY);
      }
      // Check that there are no other initializers.
      if (!initializers.tail.isEmpty()) {
        error(call, MessageKind.REDIRECTING_CONSTRUCTOR_HAS_INITIALIZER);
      }
    } else {
      visitor.error(call, MessageKind.CONSTRUCTOR_CALL_EXPECTED);
      validTarget = false;
    }

    if (validTarget) {
      // Resolve the arguments, and make sure the call gets a selector
      // by calling handleArguments.
      visitor.inStaticContext( () => visitor.handleArguments(call) );
      // Lookup constructor and try to match it to the selector.
      ResolverTask resolver = visitor.compiler.resolver;
      result = resolver.lookupConstructor(lookupTarget, call);
      if (result === null) {
        SourceString constructorName = resolver.getConstructorName(call);
        String className = lookupTarget.name.slowToString();
        String name = (constructorName === const SourceString(''))
                          ? className
                          : "$className.${constructorName.slowToString()}";
        error(call, MessageKind.CANNOT_RESOLVE_CONSTRUCTOR, [name]);
      } else {
        final Compiler compiler = visitor.compiler;
        Selector selector = visitor.mapping.getSelector(call);
        // TODO(karlklose): support optional arguments.
        if (!selector.applies(compiler, result)) {
          error(call, MessageKind.NO_MATCHING_CONSTRUCTOR);
        }
      }
      visitor.useElement(call, result);
    }
    return result;
  }

  FunctionElement resolveRedirection(FunctionElement constructor,
                                     FunctionExpression functionNode) {
    if (functionNode.initializers === null) return null;
    Link<Node> link = functionNode.initializers.nodes;
    if (!link.isEmpty() && Initializers.isConstructorRedirect(link.head)) {
      return resolveSuperOrThis(constructor, functionNode, link.head);
    }
    return null;
  }

  /**
   * Resolve all initializers of this constructor. In the case of a redirecting
   * constructor, the resolved constructor's function element is returned.
   */
  FunctionElement resolveInitializers(FunctionElement constructor,
                                      FunctionExpression functionNode) {
    if (functionNode.initializers === null) return null;
    initializers = functionNode.initializers.nodes;
    FunctionElement result;
    for (Link<Node> link = initializers;
         !link.isEmpty();
         link = link.tail) {
      if (link.head.asSendSet() != null) {
        final SendSet init = link.head.asSendSet();
        resolveFieldInitializer(constructor, init);
      } else if (link.head.asSend() !== null) {
        final Send call = link.head.asSend();
        result = resolveSuperOrThis(constructor, functionNode, call);
      } else {
        error(link.head, MessageKind.INVALID_INITIALIZER);
      }
    }
    return result;
  }
}

class CommonResolverVisitor<R> extends AbstractVisitor<R> {
  final Compiler compiler;

  CommonResolverVisitor(Compiler this.compiler);

  R visitNode(Node node) {
    cancel(node, 'internal error');
  }

  R visitEmptyStatement(Node node) => null;

  /** Convenience method for visiting nodes that may be null. */
  R visit(Node node) => (node == null) ? null : node.accept(this);

  void error(Node node, MessageKind kind, [arguments = const []]) {
    ResolutionError message  = new ResolutionError(kind, arguments);
    compiler.reportError(node, message);
  }

  void warning(Node node, MessageKind kind, [arguments = const []]) {
    ResolutionWarning message  = new ResolutionWarning(kind, arguments);
    compiler.reportWarning(node, message);
  }

  void cancel(Node node, String message) {
    compiler.cancel(message, node: node);
  }

  void internalError(Node node, String message) {
    compiler.internalError(message, node: node);
  }

  void unimplemented(Node node, String message) {
    compiler.unimplemented(message, node: node);
  }
}

interface LabelScope {
  LabelScope get outer();
  LabelElement lookup(String label);
}

class LabeledStatementLabelScope implements LabelScope {
  final LabelScope outer;
  final LabelElement label;
  LabeledStatementLabelScope(this.outer, this.label);
  LabelElement lookup(String labelName) {
    if (this.label.labelName == labelName) return label;
    return outer.lookup(labelName);
  }
}

class EmptyLabelScope implements LabelScope {
  const EmptyLabelScope();
  LabelElement lookup(String label) => null;
  LabelScope get outer() {
    throw 'internal error: empty label scope has no outer';
  }
}

class StatementScope {
  LabelScope labels;
  Link<StatementElement> breakTargetStack;
  Link<StatementElement> continueTargetStack;

  StatementScope()
      : labels = const EmptyLabelScope(),
        breakTargetStack = const EmptyLink<StatementElement>(),
        continueTargetStack = const EmptyLink<StatementElement>();

  LabelElement lookupLabel(String label) => labels.lookup(label);
  StatementElement currentBreakTarget() =>
    breakTargetStack.isEmpty() ? null : breakTargetStack.head;
  StatementElement currentContinueTarget() =>
    continueTargetStack.isEmpty() ? null : continueTargetStack.head;

  void enterLabelScope(LabelElement element) {
    labels = new LabeledStatementLabelScope(labels, element);
  }
  void exitLabelScope() {
    labels = labels.outer;
  }
  void enterLoop(StatementElement element) {
    breakTargetStack = breakTargetStack.prepend(element);
    continueTargetStack = continueTargetStack.prepend(element);
  }
  void exitLoop() {
    breakTargetStack = breakTargetStack.tail;
    continueTargetStack = continueTargetStack.tail;
  }
}


class ResolverVisitor extends CommonResolverVisitor<Element> {
  final TreeElementMapping mapping;
  final Element enclosingElement;
  bool inInstanceContext;
  Scope context;
  ClassElement currentClass;
  bool typeRequired = false;
  StatementScope statementScope;

  ResolverVisitor(Compiler compiler, Element element)
    : this.mapping  = new TreeElementMapping(),
      this.enclosingElement = element,
      inInstanceContext = element.isInstanceMember()
          || element.isGenerativeConstructor(),
      this.context  = element.isMember()
        ? new ClassScope(element.enclosingElement, element.getLibrary())
        : new TopScope(element.getLibrary()),
      this.currentClass = element.isMember() ? element.enclosingElement : null,
      this.statementScope = new StatementScope(),
      super(compiler);

  Element lookup(Node node, SourceString name) {
    Element result = context.lookup(name);
    if (!inInstanceContext && result != null && result.isInstanceMember()) {
      error(node, MessageKind.NO_INSTANCE_AVAILABLE, [node]);
    }
    return result;
  }

  // Create, or reuse an already created, statement element for a statement.
  StatementElement getOrCreateStatementElement(Node statement) {
    StatementElement element = mapping[statement];
    if (element !== null) return element;
    element = new StatementElement(statement, enclosingElement);
    mapping[statement] = element;
    return element;
  }

  inStaticContext(action()) {
    bool wasInstanceContext = inInstanceContext;
    inInstanceContext = false;
    action();
    inInstanceContext = wasInstanceContext;
  }

  visitInStaticContext(Node node) {
    inStaticContext(() => visit(node));
  }

  visitIdentifier(Identifier node) {
    if (node.isThis()) {
      if (!inInstanceContext) {
        error(node, MessageKind.NO_INSTANCE_AVAILABLE, [node]);
      }
      return null;
    } else if (node.isSuper()) {
      if (!inInstanceContext) error(node, MessageKind.NO_SUPER_IN_STATIC);
      return null;
    } else {
      Element element = lookup(node, node.source);
      if (element == null) {
        error(node, MessageKind.CANNOT_RESOLVE, [node]);
      }
      return useElement(node, element);
    }
  }

  visitTypeAnnotation(TypeAnnotation node) {
    SourceString className;
    if (node.typeName.asSend() !== null) {
      // In new and const expressions, the type name can be a Send to
      // denote named constructors or library prefixes.
      Send send = node.typeName.asSend();
      className = send.receiver.asIdentifier().source;
    } else {
      className = node.typeName.asIdentifier().source;
    }
    if (className == const SourceString('var')) return null;
    if (className == const SourceString('void')) return null;
    Element element = context.lookup(className);
    if (element === null) {
      if (typeRequired) {
        error(node, MessageKind.CANNOT_RESOLVE_TYPE, [className]);
      } else {
        warning(node, MessageKind.CANNOT_RESOLVE_TYPE, [className]);
      }
    } else if (!element.isClassOrInterfaceOrTypedef()) {
      if (typeRequired) {
        error(node, MessageKind.NOT_A_TYPE, [className]);
      } else {
        warning(node, MessageKind.NOT_A_TYPE, [className]);
      }
    } else {
      if (element.isClass()) {
        // TODO(ngeoffray): Should we also resolve typedef?
        ClassElement cls = element;
        compiler.resolver.toResolve.add(element);
      }
      // TODO(ahe): This should be a Type.
      useElement(node, element);
    }
    return element;
  }

  Element defineElement(Node node, Element element,
                        [bool doAddToScope = true]) {
    compiler.ensure(element !== null);
    mapping[node] = element;
    if (doAddToScope) {
      Element existing = context.add(element);
      if (existing != element) {
        error(node, MessageKind.DUPLICATE_DEFINITION, [node]);
      }
    }
    return element;
  }

  Element useElement(Node node, Element element) {
    if (element === null) return null;
    return mapping[node] = element;
  }

  void setupFunction(FunctionExpression node, FunctionElement function) {
    context = new MethodScope(context, function);
    // Put the parameters in scope.
    FunctionParameters functionParameters =
        function.computeParameters(compiler);
    Link<Node> parameterNodes = node.parameters.nodes;
    functionParameters.forEachParameter((Element element) {
      if (element == functionParameters.optionalParameters.head) {
        NodeList nodes = parameterNodes.head;
        parameterNodes = nodes.nodes;
      }
      VariableDefinitions variableDefinitions = parameterNodes.head;
      defineElement(variableDefinitions.definitions.nodes.head, element);
      parameterNodes = parameterNodes.tail;
    });
  }

  Element visitClassNode(ClassNode node) {
    cancel(node, "shouldn't be called");
  }

  visitIn(Node node, Scope scope) {
    context = scope;
    Element element = visit(node);
    context = context.parent;
    return element;
  }

  /**
   * Introduces new default targets for break and continue
   * before visiting the body of the loop
   */
  visitLoopBodyIn(Node loop, Node body, Scope scope) {
    StatementElement element = getOrCreateStatementElement(loop);
    statementScope.enterLoop(element);
    visitIn(body, scope);
    statementScope.exitLoop();
    if (!element.isTarget) {
      mapping.remove(loop);
    }
  }

  visitBlock(Block node) {
    visitIn(node.statements, new BlockScope(context));
  }

  visitDoWhile(DoWhile node) {
    visitLoopBodyIn(node, node.body, new BlockScope(context));
    visit(node.condition);
  }

  visitEmptyStatement(EmptyStatement node) { }

  visitExpressionStatement(ExpressionStatement node) {
    visit(node.expression);
  }

  visitFor(For node) {
    Scope scope = new BlockScope(context);
    visitIn(node.initializer, scope);
    visitIn(node.condition, scope);
    visitIn(node.update, scope);
    visitLoopBodyIn(node, node.body, scope);
  }

  visitFunctionDeclaration(FunctionDeclaration node) {
    assert(node.function.name !== null);
    visit(node.function);
    FunctionElement functionElement = mapping[node.function];
    // TODO(floitsch): this might lead to two errors complaining about
    // shadowing.
    defineElement(node, functionElement);
  }

  visitFunctionExpression(FunctionExpression node) {
    visit(node.returnType);
    SourceString name;
    if (node.name === null) {
      name = const SourceString("");
    } else {
      name = node.name.asIdentifier().source;
    }
    FunctionElement enclosingElement = new FunctionElement.node(
        name, node, ElementKind.FUNCTION, new Modifiers.empty(),
        context.element);
    setupFunction(node, enclosingElement);
    defineElement(node, enclosingElement, doAddToScope: node.name !== null);

    // Run the body in a fresh statement scope.
    StatementScope oldScope = statementScope;
    statementScope = new StatementScope();
    visit(node.body);
    statementScope = oldScope;

    context = context.parent;
    return enclosingElement;
  }

  visitIf(If node) {
    visit(node.condition);
    visit(node.thenPart);
    visit(node.elsePart);
  }

  static bool isLogicalOperator(Identifier op) {
    String str = op.source.stringValue;
    return (str === '&&' || str == '||' || str == '!');
  }

  Element resolveSend(Send node) {
    Element resolvedReceiver = visit(node.receiver);

    Element target = null;
    if (node.selector.asIdentifier() === null) {
      // We are calling a closure returned from an expression.
      assert(node.selector.asExpression() !== null);
      assert(resolvedReceiver === null);
      visit(node.selector);
    } else {
      SourceString name = node.selector.asIdentifier().source;
      if (node.receiver === null) {
        target = lookup(node, name);
        if (target === null && !inInstanceContext) {
          error(node, MessageKind.CANNOT_RESOLVE, [name]);
        }
      } else if (node.isSuperCall) {
        if (currentClass !== null) {
          ClassElement superElement = currentClass.superclass;
          if (superElement !== null) {
            // TODO(ngeoffray): The lookup should continue on super
            // classes.
            target = superElement.lookupLocalMember(name);
          }
          if (target === null) {
            error(node,
                  MessageKind.METHOD_NOT_FOUND,
                  [superElement.name, name]);
          }
        }
      } else if (resolvedReceiver === null) {
        return null;
      } else if (resolvedReceiver.kind === ElementKind.CLASS) {
        ClassElement receiverClass = resolvedReceiver;
        target = receiverClass.resolve(compiler).lookupLocalMember(name);
        if (target === null) {
          error(node, MessageKind.METHOD_NOT_FOUND, [receiverClass.name, name]);
        } else if (target.isInstanceMember()) {
          error(node, MessageKind.MEMBER_NOT_STATIC,
                [receiverClass.name, name]);
        }
      } else if (resolvedReceiver.kind === ElementKind.PREFIX) {
        PrefixElement prefix = resolvedReceiver;
        target = prefix.library.lookupLocalMember(name);
        if (target == null) {
          error(node, MessageKind.NO_SUCH_LIBRARY_MEMBER,
                [resolvedReceiver.name, name]);
        }
      }
    }
    return target;
  }

  resolveTypeTest(Node argument) {
    TypeAnnotation node = argument.asTypeAnnotation();
    if (node == null) {
      node = argument.asSend().receiver;
    }
    resolveTypeRequired(node);
  }

  void handleArguments(Send node) {
    int count = 0;
    List<SourceString> namedArguments = <SourceString>[];
    for (Link<Node> link = node.argumentsNode.nodes;
         !link.isEmpty();
         link = link.tail) {
      count++;
      Expression argument = link.head;
      visit(argument);
      if (argument.asNamedArgument() != null) {
        NamedArgument named = argument;
        namedArguments.add(named.name.source);
      }
    }
    mapping.setSelector(node, new Invocation(count, namedArguments));
  }

  visitSend(Send node) {
    Element target = resolveSend(node);
    if (node.isOperator) {
      Operator op = node.selector.asOperator();
      if (op.source.stringValue === 'is') {
        resolveTypeTest(node.arguments.head);
        assert(node.arguments.tail.isEmpty());
        mapping.setSelector(node, Selector.BINARY_OPERATOR);
      } else if (node.arguments.isEmpty()) {
        assert(op.token.kind !== PLUS_TOKEN);
        mapping.setSelector(node, Selector.UNARY_OPERATOR);
      } else {
        visit(node.argumentsNode);
        mapping.setSelector(node, Selector.BINARY_OPERATOR);
      }
    } else if (node.isIndex) {
      visit(node.argumentsNode);
      assert(node.arguments.tail.isEmpty());
      mapping.setSelector(node, Selector.INDEX);
    } else if (node.isPropertyAccess) {
      mapping.setSelector(node, Selector.GETTER);
    } else {
      handleArguments(node);
    }
    if (target != null && target.kind == ElementKind.ABSTRACT_FIELD) {
      AbstractFieldElement field = target;
      target = field.getter;
    }
    // TODO(ngeoffray): Warn if target is null and the send is
    // unqualified.
    return useElement(node, target);
  }

  visitSendSet(SendSet node) {
    Element target = resolveSend(node);
    Element setter = null;
    Element getter = null;
    if (target != null && target.kind == ElementKind.ABSTRACT_FIELD) {
      AbstractFieldElement field = target;
      setter = field.setter;
      getter = field.getter;
    } else {
      setter = target;
      getter = target;
    }
    // TODO(ngeoffray): Check if the target can be assigned.
    Identifier op = node.assignmentOperator;
    bool needsGetter = op.source.stringValue !== '=';
    Selector selector;
    if (needsGetter) {
      if (node.isIndex) {
        selector = Selector.INDEX_AND_INDEX_SET;
      } else {
        selector = Selector.GETTER_AND_SETTER;
      }
      useElement(node.selector, getter);
    } else if (node.isIndex) {
      selector = Selector.INDEX_SET;
    } else {
      selector = Selector.SETTER;
    }
    visit(node.argumentsNode);
    mapping.setSelector(node, selector);
    // TODO(ngeoffray): Warn if target is null and the send is
    // unqualified.
    return useElement(node, setter);
  }

  visitLiteralInt(LiteralInt node) {
  }

  visitLiteralDouble(LiteralDouble node) {
  }

  visitLiteralBool(LiteralBool node) {
  }

  visitLiteralString(LiteralString node) {
  }

  visitLiteralNull(LiteralNull node) {
  }

  visitNodeList(NodeList node) {
    for (Link<Node> link = node.nodes; !link.isEmpty(); link = link.tail) {
      visit(link.head);
    }
  }

  visitOperator(Operator node) {
    unimplemented(node, 'operator');
  }

  visitReturn(Return node) {
    visit(node.expression);
  }

  visitThrow(Throw node) {
    visit(node.expression);
  }

  visitVariableDefinitions(VariableDefinitions node) {
    visit(node.type);
    VariableDefinitionsVisitor visitor =
        new VariableDefinitionsVisitor(compiler, node, this,
                                       ElementKind.VARIABLE);
    visitor.visit(node.definitions);
  }

  visitWhile(While node) {
    visit(node.condition);
    visitLoopBodyIn(node, node.body, new BlockScope(context));
  }

  visitParenthesizedExpression(ParenthesizedExpression node) {
    visit(node.expression);
  }

  visitNewExpression(NewExpression node) {
    if (node.isConst()) {
      warning(node, MessageKind.GENERIC,
              ['const expressions are not implemented']);
    }
    Node selector = node.send.selector;
    if (selector.asTypeAnnotation() === null) {
      cancel(
          node, 'named constructors with type arguments are not implemented');
    }

    FunctionElement constructor = resolveConstructor(node);
    handleArguments(node.send);
    if (constructor === null) return null;
    // TODO(karlklose): handle optional arguments.
    if (node.send.argumentCount() != constructor.parameterCount(compiler)) {
      // TODO(ngeoffray): resolution error with wrong number of
      // parameters. We cannot do this rigth now because of the
      // List constructor.
    }
    useElement(node.send, constructor);
    return null;
  }

  FunctionElement resolveConstructor(NewExpression node) {
    SourceString constructorName;
    Node selector = node.send.selector;
    Node typeName = selector.asTypeAnnotation().typeName;
    if (typeName.asSend() !== null) {
      SourceString className = typeName.asSend().receiver.asIdentifier().source;
      SourceString name = typeName.asSend().selector.asIdentifier().source;
      constructorName = Elements.constructConstructorName(className, name);
    } else {
      constructorName = typeName.asIdentifier().source;
    }
    ClassElement cls = resolveTypeRequired(selector);
    if (cls === null) {
      error(selector, MessageKind.CANNOT_RESOLVE_TYPE, [selector]);
      return null;
    }
    cls.resolve(compiler);
    if (cls.isInterface() && (cls.defaultClass === null)) {
      error(selector, MessageKind.CANNOT_INSTANTIATE_INTERFACE, [cls.name]);
    }
    FunctionElement constructor = cls.lookupConstructor(constructorName);
    if (constructor !== null) return constructor;
    if (constructorName == cls.name && node.send.argumentsNode.isEmpty()) {
      return cls.getSynthesizedConstructor();
    }
    error(node.send, MessageKind.CANNOT_FIND_CONSTRUCTOR, [node.send]);
    return null;
  }

  ClassElement resolveTypeRequired(Node node) {
    bool old = typeRequired;
    typeRequired = true;
    ClassElement cls = visit(node);
    typeRequired = old;
    return cls;
  }

  visitModifiers(Modifiers node) {
    // TODO(ngeoffray): Implement this.
    unimplemented(node, 'modifiers');
  }

  visitLiteralList(LiteralList node) {
    if (node.isConst()) {
      warning(node, MessageKind.GENERIC,
              ['const literal lists are not implemented']);
    }
    visit(node.elements);
  }

  visitConditional(Conditional node) {
    node.visitChildren(this);
  }

  visitStringInterpolation(StringInterpolation node) {
    node.visitChildren(this);
  }

  visitStringInterpolationPart(StringInterpolationPart node) {
    node.visitChildren(this);
  }

  visitBreakStatement(BreakStatement node) {
    StatementElement target;
    if (node.target === null) {
      target = statementScope.currentBreakTarget();
      if (target === null) {
        error(node, MessageKind.NO_BREAK_TARGET);
        return;
      }
      target.isBreakTarget = true;
    } else {
      String labelName = node.target.source.slowToString();
      LabelElement label = statementScope.lookupLabel(labelName);
      if (label === null) {
        error(node.target, MessageKind.UNBOUND_LABEL, [labelName]);
        return;
      }
      target = label.target;
      label.setBreakTarget();
      mapping[node.target] = label;
    }
    mapping[node] = target;
  }

  visitContinueStatement(ContinueStatement node) {
    StatementElement target;
    if (node.target === null) {
      target = statementScope.currentContinueTarget();
      if (target === null) {
        error(node, MessageKind.NO_CONTINUE_TARGET);
        return;
      }
    } else {
      String labelName = node.target.source.slowToString();
      LabelElement label = statementScope.lookupLabel(labelName);
      if (label === null) {
        error(node.target, MessageKind.UNBOUND_LABEL, [labelName]);
        return;
      }
      target = label.target;
      if (!target.statement.isValidContinueTarget()) {
        error(node.target, MessageKind.INVALID_CONTINUE, [labelName]);
      }
    }
    target.isContinueTarget = true;
    mapping[node] = target;
  }

  visitForInStatement(ForInStatement node) {
    visit(node.expression);
    Scope scope = new BlockScope(context);
    Node declaration = node.declaredIdentifier;
    visitIn(declaration, scope);
    visitLoopBodyIn(node, node.body, scope);

    // TODO(lrn): Also allow a single identifier.
    if ((declaration is !Send || declaration.asSend().selector is !Identifier)
        && (declaration is !VariableDefinitions ||
        !declaration.asVariableDefinitions().definitions.nodes.tail.isEmpty()))
    {
      // The variable declaration is either not an identifier, not a
      // declaration, or it's declaring more than one variable.
      error(node.declaredIdentifier, MessageKind.INVALID_FOR_IN, []);
    }
  }

  visitLabelledStatement(LabelledStatement node) {
    String labelName = node.label.source.slowToString();
    LabelElement existingElement = statementScope.lookupLabel(labelName);
    if (existingElement !== null) {
      warning(node.label, MessageKind.DUPLICATE_LABEL, [labelName]);
      warning(existingElement.label, MessageKind.EXISTING_LABEL, [labelName]);
    }
    Node body = node.getBody();
    StatementElement statementElement = getOrCreateStatementElement(body);

    LabelElement element = statementElement.addLabel(node.label, labelName);
    statementScope.enterLabelScope(element);
    visit(node.statement);
    statementScope.exitLabelScope();
    if (element.isTarget) {
      mapping[node.label] = element;
    } else {
      warning(node.label, MessageKind.UNUSED_LABEL, [labelName]);
    }
    if (!statementElement.isBreakTarget && mapping[body] === statementElement) {
      // If the body is itself a break or continue for another target, it
      // might have updated its mapping to the label it actaully does target.
      mapping.remove(body);
    }
  }

  visitLiteralMap(LiteralMap node) {
    node.visitChildren(this);
  }

  visitLiteralMapEntry(LiteralMapEntry node) {
    node.visitChildren(this);
  }

  visitNamedArgument(NamedArgument node) {
    visit(node.expression);
  }

  visitSwitchStatement(SwitchStatement node) {
    node.expression.accept(this);
    StatementElement element = getOrCreateStatementElement(node);
    statementScope.enterLoop(element);
    node.cases.accept(this);
    statementScope.exitLoop();
  }

  visitSwitchCase(SwitchCase node) {
    // TODO(ahe): What about the label?
    node.expression.accept(this);
    node.statements.accept(this);
  }

  visitDefaultCase(DefaultCase node) {
    // TODO(ahe): What about the label?
    node.statements.accept(this);
  }

  visitTryStatement(TryStatement node) {
    visit(node.tryBlock);
    if (node.catchBlocks.isEmpty() && node.finallyBlock == null) {
      // TODO(ngeoffray): The precise location is
      // node.getEndtoken.next. Adjust when issue #1581 is fixed.
      error(node, MessageKind.NO_CATCH_NOR_FINALLY);
    }
    visit(node.catchBlocks);
    visit(node.finallyBlock);
  }

  visitCatchBlock(CatchBlock node) {
    Scope scope = new BlockScope(context);
    if (node.formals.isEmpty()) {
      error(node, MessageKind.EMPTY_CATCH_DECLARATION);
    } else if (!node.formals.nodes.tail.isEmpty()
               && !node.formals.nodes.tail.tail.isEmpty()) {
      for (Node extra in node.formals.nodes.tail.tail) {
        error(extra, MessageKind.EXTRA_CATCH_DECLARATION);
      }
    }
    visitIn(node.formals, scope);
    visitIn(node.block, scope);
  }

  visitTypedef(Typedef node) {
    unimplemented(node, 'typedef');
  }
}

class ClassResolverVisitor extends CommonResolverVisitor<Type> {
  Scope context;

  ClassResolverVisitor(Compiler compiler, LibraryElement library)
    : context = new TopScope(library),
      super(compiler);

  Type visitClassNode(ClassNode node) {
    ClassElement element = context.lookup(node.name.source);
    compiler.ensure(element !== null);
    compiler.ensure(!element.isResolved);
    element.supertype = visit(node.superclass);
    if (element.name != Types.OBJECT && element.supertype === null) {
      ClassElement objectElement = context.lookup(Types.OBJECT);
      if (objectElement !== null && !objectElement.isResolved) {
        compiler.resolver.toResolve.add(objectElement);
      } else if (objectElement === null){
        error(node, MessageKind.CANNOT_RESOLVE_TYPE, [Types.OBJECT]);
      }
      element.supertype = new SimpleType(Types.OBJECT, objectElement);
    }
    if (node.defaultClause !== null) {
      element.defaultClass = visit(node.defaultClause.nodes.head);
    }
    for (Link<Node> link = node.interfaces.nodes;
         !link.isEmpty();
         link = link.tail) {
      element.interfaces = element.interfaces.prepend(visit(link.head));
    }
    return element.computeType(compiler);
  }

  Type visitTypeAnnotation(TypeAnnotation node) {
    Identifier name = node.typeName.asIdentifier();
    if (name === null) {
      unimplemented(node.typeName, "prefixes");
    }
    return visit(name);
  }

  Type visitIdentifier(Identifier node) {
    Element element = context.lookup(node.source);
    if (element === null) {
      error(node, MessageKind.CANNOT_RESOLVE_TYPE, [node]);
    } else if (!element.isClassOrInterfaceOrTypedef()) {
      error(node, MessageKind.NOT_A_TYPE, [node]);
    } else {
      compiler.resolver.toResolve.add(element);
      // TODO(ngeoffray): Use type variables.
      return element.computeType(compiler);
    }
    return null;
  }
}

class VariableDefinitionsVisitor extends CommonResolverVisitor<SourceString> {
  VariableDefinitions definitions;
  ResolverVisitor resolver;
  ElementKind kind;
  VariableListElement variables;

  VariableDefinitionsVisitor(Compiler compiler,
                             this.definitions, this.resolver, this.kind)
    : super(compiler)
  {
    variables = new VariableListElement.node(
        definitions, ElementKind.VARIABLE_LIST, resolver.context.element);
  }

  SourceString visitSendSet(SendSet node) {
    assert(node.arguments.tail.isEmpty()); // Sanity check
    resolver.visit(node.arguments.head);
    return visit(node.selector);
  }

  SourceString visitIdentifier(Identifier node) => node.source;

  visitNodeList(NodeList node) {
    for (Link<Node> link = node.nodes; !link.isEmpty(); link = link.tail) {
      SourceString name = visit(link.head);
      VariableElement element = new VariableElement(
          name, variables, kind, resolver.context.element, node: link.head);
      resolver.defineElement(link.head, element);
    }
  }
}

class SignatureResolver extends CommonResolverVisitor<Element> {
  final Element enclosingElement;
  Link<Element> optionalParameters = const EmptyLink<Element>();
  int optionalParameterCount = 0;
  Node currentDefinitions;

  SignatureResolver(Compiler compiler, this.enclosingElement) : super(compiler);

  Element visitNodeList(NodeList node) {
    // This must be a list of optional arguments.
    if (node.beginToken.stringValue !== '[') {
      internalError(node, "expected optional parameters");
    }
    LinkBuilder<Element> elements = analyzeNodes(node.nodes);
    optionalParameterCount = elements.length;
    optionalParameters = elements.toLink();
    return null;
  }

  Element visitVariableDefinitions(VariableDefinitions node) {
    resolveType(node.type);

    Link<Node> definitions = node.definitions.nodes;
    if (definitions.isEmpty()) {
      cancel(node, 'internal error: no parameter definition');
      return null;
    }
    if (!definitions.tail.isEmpty()) {
      cancel(definitions.tail.head, 'internal error: extra definition');
      return null;
    }
    Node definition = definitions.head;
    if (definition is NodeList) {
      cancel(node, 'optional parameters are not implemented');
    }

    if (currentDefinitions != null) {
      cancel(node, 'function type parameters not supported');
    }
    currentDefinitions = node;
    Element element = definition.accept(this);
    currentDefinitions = null;
    return element;
  }

  Element visitIdentifier(Identifier node) {
    Element variables = new VariableListElement.node(currentDefinitions,
        ElementKind.VARIABLE_LIST, enclosingElement);
    return new VariableElement(node.source, variables,
        ElementKind.PARAMETER, enclosingElement, node: node);
  }

  Element visitSend(Send node) {
    Element element;
    if (node.receiver.asIdentifier() === null ||
        !node.receiver.asIdentifier().isThis()) {
      error(node, MessageKind.INVALID_PARAMETER, []);
    } else if (enclosingElement.kind !== ElementKind.GENERATIVE_CONSTRUCTOR) {
      error(node, MessageKind.FIELD_PARAMETER_NOT_ALLOWED, []);
    } else {
      if (node.selector.asIdentifier() == null) {
        cancel(node,
               'internal error: unimplemented receiver on parameter send');
      }
      SourceString name = node.selector.asIdentifier().source;
      element = currentClass.lookupLocalMember(name);
      if (element.kind !== ElementKind.FIELD) {
        error(node, MessageKind.NOT_A_FIELD, [name]);
      } else if (!element.isInstanceMember()) {
        error(node, MessageKind.NOT_INSTANCE_FIELD, [name]);
      }
    }
    // TODO(ngeoffray): it's not right to put the field element in
    // the parameters element. Create another element instead.
    return element;
  }

  Element visitSendSet(SendSet node) {
    Element element;
    if (node.receiver != null) {
      // TODO(ngeoffray): it's not right to put the field element in
      // the parameters element. Create another element instead.
      element = visitSend(node);
    } else if (node.selector.asIdentifier() != null) {
      Element variables = new VariableListElement.node(currentDefinitions,
          ElementKind.VARIABLE_LIST, enclosingElement);
      element = new VariableElement(node.selector.asIdentifier().source,
          variables, ElementKind.PARAMETER, enclosingElement, node: node);
    }
    // Visit the value. The compile time constant handler will
    // make sure it's a compile time constant.
    resolveExpression(node.arguments.head);
    compiler.enqueue(new WorkItem.toCompile(element));
    return element;
  }

  Element visitFunctionExpression(FunctionExpression node) {
    // This is a function typed parameter.
    // TODO(ahe): Resolve the function type.
    return visit(node.name);
  }

  LinkBuilder<Element> analyzeNodes(Link<Node> link) {
    LinkBuilder<Element> elements = new LinkBuilder<Element>();
    for (; !link.isEmpty(); link = link.tail) {
      Element element = link.head.accept(this);
      if (element != null) {
        elements.addLast(element);
      } else {
        // If parameter is null, the current node should be the last,
        // and a list of optional named parameters.
        if (!link.tail.isEmpty() || (link.head is !NodeList)) {
          internalError(link.head, "expected expected optional parameters");
        }
      }
    }
    return elements;
  }

  static FunctionParameters analyze(Compiler compiler,
                                    FunctionElement element) {
    FunctionExpression node = element.parseNode(compiler);
    SignatureResolver visitor = new SignatureResolver(compiler, element);
    Link<Node> nodes = node.parameters.nodes;
    LinkBuilder<Element> parameters = visitor.analyzeNodes(nodes);
    return new FunctionParameters(parameters.toLink(),
                                  visitor.optionalParameters,
                                  parameters.length,
                                  visitor.optionalParameterCount);
  }

  // TODO(ahe): This is temporary.
  void resolveExpression(Node node) {
    if (node == null) return;
    node.accept(new ResolverVisitor(compiler, enclosingElement));
  }

  // TODO(ahe): This is temporary.
  void resolveType(Node node) {
    if (node == null) return;
    node.accept(new ResolverVisitor(compiler, enclosingElement));
  }

  // TODO(ahe): This is temporary.
  ClassElement get currentClass() {
    return enclosingElement.isMember()
      ? enclosingElement.enclosingElement : null;
  }
}

class Scope {
  final Element element;
  final Scope parent;

  Scope(this.parent, this.element);
  abstract Element add(Element element);
  abstract Element lookup(SourceString name);
}

class MethodScope extends Scope {
  final Map<SourceString, Element> elements;

  MethodScope(Scope parent, Element element)
    : super(parent, element), this.elements = new Map<SourceString, Element>();

  Element lookup(SourceString name) {
    Element element = elements[name];
    if (element !== null) return element;
    return parent.lookup(name);
  }

  Element add(Element element) {
    if (elements.containsKey(element.name)) return elements[element.name];
    elements[element.name] = element;
    return element;
  }
}

class BlockScope extends MethodScope {
  BlockScope(Scope parent) : super(parent, parent.element);
}

class ClassScope extends Scope {
  ClassScope(ClassElement element, LibraryElement library)
    : super(new TopScope(library), element);

  Element lookup(SourceString name) {
    ClassElement cls = element;
    Element element = cls.lookupLocalMember(name);
    if (element != null) return element;
    element = parent.lookup(name);
    if (element != null) return element;
    // TODO(ngeoffray): Lookup in the super class.
    return null;
  }

  Element add(Element element) {
    throw "Cannot add an element in a class scope";
  }
}

class TopScope extends Scope {
  LibraryElement get library() => element;

  TopScope(LibraryElement library) : super(null, library);
  Element lookup(SourceString name) => library.find(name);

  Element add(Element element) {
    throw "Cannot add an element in the top scope";
  }
}
