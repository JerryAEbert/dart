// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('html_tests');

#import('dart:html');
#import('../../../testing/unittest/unittest_html.dart');

#source('util.dart');
#source('CSSStyleDeclarationTests.dart');
#source('DocumentFragmentTests.dart');
#source('ElementTests.dart');
// #source('EventTests.dart');
#source('LocalStorageTests.dart');
#source('MeasurementTests.dart');
#source('NodeTests.dart');
// #source('SVGElementTests.dart');
#source('XHRTests.dart');

main() {
  group('CSSStyleDeclaration', testCSSStyleDeclaration);
  group('DocumentFragment', testDocumentFragment);
  group('Element', testElement);
  // TODO(nweiz): enable once event constructors are ported -- Dart issue 1996.
  // group('Event', testEvents);
  group('LocalStorage', testLocalStorage);
  group('Measurement', testMeasurement);
  group('Node', testNode);
  // TODO(nweiz): enable once this code is ported -- Dart issue 1997.
  // group('SVGElement', testSVGElement);
  group('XHR', testXHR);
}
