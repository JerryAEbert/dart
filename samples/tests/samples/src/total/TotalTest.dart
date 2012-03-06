// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('total_tests');

#import('dart:html');
#import('../../../../../samples/total/client/TotalLib.dart');
#import('../../../../../client/testing/unittest/unittest_html.dart');
#source('../../../../../samples/total/server/SYLKProducer.dart');
#source('total_test_lib.dart');

void main() {
  totalTests();
}
