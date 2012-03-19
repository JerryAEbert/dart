// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('mock_compiler');

#import("../../../../lib/uri/uri.dart");

#import("../../../leg/elements/elements.dart");
#import("../../../leg/io/io.dart", prefix: 'io');
#import("../../../leg/leg.dart");
#import("../../../leg/tree/tree.dart");
#import("../../../leg/util/util.dart");
#import("parser_helper.dart");

class WarningMessage {
  Node node;
  Message message;
  WarningMessage(this.node, this.message);

  toString() => message.toString();
}

final String DEFAULT_HELPERLIB = @'''
  lt() {} add(var a, var b) {} sub() {} mul() {} div() {} tdiv() {} mod() {}
  neg() {} shl() {} shr() {} eq() {} le() {} gt() {} ge() {}
  or() {} and() {} not() {} eqNull(a) {} eqq() {}
  iae(x) {throw x;} ioore(x) {throw x;}
  guard$array(x) { return x; }
  guard$num(x) { return x; }
  guard$string(x) { return x; }
  guard$stringOrArray(x) { return x; }
  builtin$add$1(receiver, value) {}
  builtin$get$length(var receiver) {}
  builtin$filter$1(receiver, predicate) {}
  builtin$removeLast$0(receiver) {}
  index(a, index) {}
  indexSet(a, index, value) {}
  class Closure {} ''';

final String DEFAULT_CORELIB = @'''
  print(var obj) {}
  class int {}
  class double {}
  class bool {}
  class String {}
  class Object {}''';

class MockCompiler extends Compiler {
  List<WarningMessage> warnings;
  List<WarningMessage> errors;
  final Map<String, String> sources;
  Node parsedTree;
  WorkItem lastBailoutWork;

  MockCompiler([String coreSource = DEFAULT_CORELIB,
                String helperSource = DEFAULT_HELPERLIB])
      : warnings = [], errors = [],
        sources = new Map<String, String>(),
        super.withCurrentDirectory(io.getCurrentDirectory()) {
    Uri uri = new Uri(scheme: "source");
    var script = new Script(uri, new MockFile(coreSource));
    coreLibrary = new LibraryElement(script);
    parseScript(coreSource, coreLibrary);
    script = new Script(uri, new MockFile(helperSource));
    jsHelperLibrary = new LibraryElement(script);
    parseScript(helperSource, jsHelperLibrary);
    scanner.importLibrary(jsHelperLibrary, coreLibrary, null);
    mainApp = mockLibrary(this, "");
    initializeSpecialClasses();
  }

  void reportWarning(Node node, var message) {
    warnings.add(new WarningMessage(node, message.message));
  }

  void reportError(Node node, var message) {
    errors.add(new WarningMessage(node, message.message));
  }

  void reportDiagnostic(SourceSpan span, String message, bool fatal) {
    print(message);
  }

  void clearWarnings() {
    warnings = [];
  }

  void clearErrors() {
    errors = [];
  }

  TreeElementMapping resolveStatement(String text) {
    parsedTree = parseStatement(text);
    return resolveNodeStatement(parsedTree, mainApp);
  }

  TreeElementMapping resolveNodeStatement(Node tree, Element element) {
    ResolverVisitor visitor = new ResolverVisitor(this, element);
    if (visitor.context is TopScope) {
      visitor.context = new BlockScope(visitor.context);
    }
    visitor.visit(tree);
    visitor.context = new TopScope(element.getLibrary());
    // Resolve the type annotations encountered in the code.
    while (!resolver.toResolve.isEmpty()) {
      resolver.toResolve.removeFirst().ensureResolved(this);
    }
    return visitor.mapping;
  }

  resolverVisitor() {
    Element mockElement =
        new Element(buildSourceString(''), ElementKind.FUNCTION, mainApp);
    ResolverVisitor visitor = new ResolverVisitor(this, mockElement);
    visitor.context = new BlockScope(visitor.context);
    return visitor;
  }

  parseScript(String text, [LibraryElement library]) {
    if (library === null) library = mainApp;
    parseUnit(text, this, library);
  }

  void enqueue(WorkItem work) {
    if (work.isBailoutVersion()) lastBailoutWork = work;
    super.enqueue(work);
  }

  resolve(ClassElement element) {
    return resolver.resolveType(element);
  }

  void scanBuiltinLibraries() {
    // Do nothing. The mock core library is already handled in the constructor.
  }

  LibraryElement scanBuiltinLibrary(String name) {
    // Do nothing. The mock core library is already handled in the constructor.
  }

  Script readScript(Uri uri, [ScriptTag node]) {
    String code = sources[uri.toString()];
    if (code === null) throw new IllegalArgumentException(uri);
    return new StringScript(code);
  }
}

void compareWarningKinds(String text, expectedWarnings, foundWarnings) {
  var fail = (message) => Expect.fail('$text: $message');
  Iterator<MessageKind> expected = expectedWarnings.iterator();
  Iterator<WarningMessage> found = foundWarnings.iterator();
  while (expected.hasNext() && found.hasNext()) {
    Expect.equals(expected.next(), found.next().message.kind);
  }
  if (expected.hasNext()) {
    do {
      print('Expected warning "${expected.next()}" did not occur');
    } while (expected.hasNext());
    fail('Too few warnings');
  }
  if (found.hasNext()) {
    do {
      print('Additional warning "${found.next()}"');
    } while (found.hasNext());
    fail('Too many warnings');
  }
}

void importLibrary(LibraryElement target, LibraryElement imported,
                   Compiler compiler) {
  for (Link<Element> link = imported.topLevelElements; !link.isEmpty();
       link = link.tail) {
    compiler.withCurrentElement(link.head, () {
        target.define(link.head, compiler);
      });
  }
}

LibraryElement mockLibrary(Compiler compiler, String source) {
  Uri uri = new Uri(scheme: "source");
  var library = new LibraryElement(new Script(uri, new MockFile(source)));
  importLibrary(library, compiler.coreLibrary, compiler);
  return library;
}

class StringScript extends Script {
  final String code;
  StringScript(this.code) : super(null, null);
  String get text() => code;
  String get name() => "mock script";
}
