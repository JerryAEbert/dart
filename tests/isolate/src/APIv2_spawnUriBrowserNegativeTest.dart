// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Negative test to make sure that we are reaching all assertions.
// Note: the following comment is used by test.dart to additionally compile the
// other isolate's code.
// OtherScripts=APIv2_spawnUriChildIsolate.dart
#library('spawn_tests');
#import('../../../client/testing/unittest/unittest.dart');
#import('dart:dom'); // import added so test.dart can treat this as a webtest.
#import('dart:isolate');

main() {
  asyncTest('isolate fromUri - negative test', 1, () {
    ReceivePort port = new ReceivePort();
    port.receive((msg, _) {
      expect(msg).equals('re: hello'); // should be hi, not hello
      port.close();
      callbackDone();
    });

    // TODO(eub): make this work for non-JS targets.
    Isolate2 c = new Isolate2.fromUri('APIv2_spawnUriChildIsolate.js');
    c.sendPort.send('hi', port.toSendPort());
  });
}
