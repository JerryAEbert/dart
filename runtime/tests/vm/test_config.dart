// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("vm_test_config");

#import("../../../tools/testing/dart/test_suite.dart");

class VMTestSuite extends CCTestSuite {
  VMTestSuite(Map configuration)
      : super(configuration,
              "vm",
              "run_vm_tests",
              ["runtime/tests/vm/vm.status"]);
}

class VMDartTestSuite extends StandardTestSuite {
  VMDartTestSuite(Map configuration)
      : super(configuration,
              "vm",
              "runtime/tests/vm/src",
              ["runtime/tests/vm/vm_dart.status"]);
}
