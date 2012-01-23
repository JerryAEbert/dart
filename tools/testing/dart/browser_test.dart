// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

String GetHtmlContents(String title,
                       String controllerScript,
                       String scriptType,
                       String sourceScript) =>
"""
<html>
<head>
  <title> Test $title </title>
  <style>
     .unittest-table { font-family:monospace; border:1px; }
     .unittest-pass { background: #6b3;}
     .unittest-fail { background: #d55;}
     .unittest-error { background: #a11;}
  </style>
</head>
<body>
  <h1> Running $title </h1>
  <script type="text/javascript" src="$controllerScript"></script>
  <script type="text/javascript">
    // If nobody intercepts the error, finish the test.
    onerror = function() { window.layoutTestController.notifyDone() };

    document.onreadystatechange = function() {
      if (document.readyState != "loaded") return;
      // If 'startedDartTest' is not set, that means that the test did not have
      // a chance to load. This will happen when a load error occurs in the VM.
      // Give the machine time to start up.
      setTimeout(function() {
        // A window.postMessage might have been enqueued after this timeout.
        // Just sleep another time to give the browser the time to process the
        // posted message.
        setTimeout(function() {
          if (layoutTestController && !layoutTestController.startedDartTest) {
            layoutTestController.notifyDone();
          }
        }, 0);
      }, 50);
    };
  </script>
  <script type="$scriptType" src="$sourceScript"></script>
</body>
</html>
""";

String WrapDartTestInLibrary(String test) =>
"""
#library('libraryWrapper');
#source('$test');
""";

String DartTestWrapper(String domLibrary,
                       String testFramework,
                       String library) =>
"""
#library('test');

#import('${domLibrary}');
#import('${testFramework}');

#import('${library}', prefix: "Test");

waitForDone() {
  window.postMessage('unittest-suite-wait-for-done', '*');
}

pass() {
  document.body.innerHTML = 'PASS';
  window.postMessage('unittest-suite-done', '*');
}

fail(e, trace) {
  document.body.innerHTML = 'FAIL: \$e, \$trace';
  window.postMessage('unittest-suite-done', '*');
}

main() {
  bool needsToWait = false;
  bool mainIsFinished = false;
  TestRunner.waitForDoneCallback = () { needsToWait = true; };
  TestRunner.doneCallback = () {
    if (mainIsFinished) {
      pass();
    } else {
      needsToWait = false;
    }
  };
  try {
    Test.main();
    if (needsToWait) {
      waitForDone();
    } else {
      pass();
    }
    mainIsFinished = true;
  } catch(var e, var trace) {
    fail(e, trace);
  }
}
""";
