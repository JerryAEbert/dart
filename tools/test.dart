#!/usr/bin/env dart
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This file is the entrypoint of the dart test suite.  This suite is used
 * to test:
 *
 *     1. the dart vm
 *     2. the frog compiler (compiles dart to js)
 *     3. the leg compiler (also compiles dart to js)
 *     4. the dartc static analyzer
 *     5. the dart core library
 *     6. other standard dart libraries (DOM bindings, ui libraries,
 *            io libraries etc.)
 *
 * This script is normally invoked by test.py.  (test.py finds the dart vm
 * and passses along all command line arguments to this script.)
 *
 * The command line args of this script are documented in
 * "tools/testing/test_options.dart".
 *
 */

#library("test");

#import("testing/dart/test_runner.dart");
#import("testing/dart/test_options.dart");

#import("../tests/co19/test_config.dart");
#import("../tests/corelib/test_config.dart");
#import("../tests/isolate/test_config.dart");
#import("../tests/language/test_config.dart");
#import("../tests/standalone/test_config.dart");
#import("../tests/utils/test_config.dart");
#import("../runtime/tests/vm/test_config.dart");
#import("../samples/tests/samples/test_config.dart");
#import("../client/tests/dartc/test_config.dart");
#import("../compiler/tests/dartc/test_config.dart");
#import("../client/tests/client/test_config.dart");
#import("../frog/tests/frog/test_config.dart");
#import("../frog/tests/leg/test_config.dart");
#import("../frog/tests/leg_only/test_config.dart");
#import("../frog/tests/native/test_config.dart");
#import("../frog/tests/await/test_config.dart");
#import("../utils/tests/css/test_config.dart");
#import("../utils/tests/import_mapper/test_config.dart");
#import("../utils/tests/peg/test_config.dart");

main() {
  var startTime = new Date.now();
  var optionsParser = new TestOptionsParser();
  List<Map> configurations = optionsParser.parse(new Options().arguments);
  if (configurations == null) return;

  // Extract global options from first configuration.
  var firstConf = configurations[0];
  Map<String, RegExp> selectors = firstConf['selectors'];
  var maxProcesses = firstConf['tasks'];
  var progressIndicator = firstConf['progress'];
  var verbose = firstConf['verbose'];
  var printTiming = firstConf['time'];
  var listTests = firstConf['list'];
  var keepGeneratedTests = firstConf['keep-generated-tests'];

  var configurationIterator = configurations.iterator();
  bool enqueueConfiguration(ProcessQueue queue) {
    if (!configurationIterator.hasNext()) {
      return false;
    }

    var conf = configurationIterator.next();
    if (selectors.containsKey('samples')) {
      queue.addTestSuite(new SamplesTestSuite(conf));
    }
    if (selectors.containsKey('standalone')) {
      queue.addTestSuite(new StandaloneTestSuite(conf));
    }
    if (selectors.containsKey('corelib')) {
      queue.addTestSuite(new CorelibTestSuite(conf));
    }
    if (selectors.containsKey('co19')) {
      queue.addTestSuite(new Co19TestSuite(conf));
    }
    if (selectors.containsKey('language')) {
      queue.addTestSuite(new LanguageTestSuite(conf));
    }
    if (selectors.containsKey('isolate')) {
      queue.addTestSuite(new IsolateTestSuite(conf));
    }
    if (selectors.containsKey('utils')) {
      queue.addTestSuite(new UtilsTestSuite(conf));
    }
    if (conf['component'] == 'vm' && selectors.containsKey('vm')) {
      queue.addTestSuite(new VMTestSuite(conf));
      queue.addTestSuite(new VMDartTestSuite(conf));
    }
    if (selectors.containsKey('frog')) {
      queue.addTestSuite(new FrogTestSuite(conf));
    }
    if (selectors.containsKey('leg')) {
      queue.addTestSuite(new LegTestSuite(conf));
    }
    if (selectors.containsKey('leg_only')) {
      queue.addTestSuite(new LegOnlyTestSuite(conf));
    }
    if (selectors.containsKey('frog_native')) {
      queue.addTestSuite(new FrogNativeTestSuite(conf));
    }
    if (conf['component'] == 'dartc' && selectors.containsKey('dartc')) {
      queue.addTestSuite(new ClientDartcTestSuite(conf));
    }
    if (conf['component'] == 'dartc' && selectors.containsKey('dartc')) {
      queue.addTestSuite(new JUnitDartcTestSuite(conf));
    }
    if (selectors.containsKey('css')) {
      queue.addTestSuite(new CssTestSuite(conf));
    }
    if (selectors.containsKey('import_mapper')) {
      queue.addTestSuite(new ImportMapperTestSuite(conf));
    }
    if (selectors.containsKey('peg')) {
      queue.addTestSuite(new PegTestSuite(conf));
    }
    if (selectors.containsKey('await')) {
      queue.addTestSuite(new AwaitTestSuite(conf));
    }
    if (selectors.containsKey('client')) {
      queue.addTestSuite(new ClientTestSuite(conf));
    }

    return true;
  }

  // Start process queue.
  var queue = new ProcessQueue(maxProcesses,
                               progressIndicator,
                               startTime,
                               printTiming,
                               enqueueConfiguration,
                               verbose,
                               listTests,
                               keepGeneratedTests);
}
