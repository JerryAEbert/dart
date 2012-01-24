// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('child_process');
#import('node.dart');
#import('net.dart');

typedef void ChildProcessExitListener(int code, String signal);

// Note: This class is implemented as a wrapper class instead of
// being implemented directly on the JS ChildProcess prototype
// because of a limitation of frog:  Frog does not think that a class
// is used unless it sees one of the class's constructors being
// called. In normal use the ChildProcess objects are only
// created by the Child_process.spawn and Child_process.exec methods.

class ChildProcess implements EventEmitter native {
  var _childprocess;

  ChildProcess._from(this._childprocess);

  // EventEmitter
  void removeAllListeners(String event)
    native "this._childprocess.removeAllListeners(event);";
  void setMaxListeners(num n)
    native "this._childprocess.setMaxListeners(n);";
  _listeners(String key)
    native "return this._childprocess.listeners(key);";

  // 'exit' event
  void emitExit(int code, String signal)
      native "this._childprocess.emit('exit', code, signal);";
  void addListenerExit(ChildProcessExitListener listener)
    native "this._childprocess.addListener('exit', listener);";
  void onExit(ChildProcessExitListener listener)
    native "this._childprocess.on('exit', listener);";
  void onceExit(ChildProcessExitListener listener)
    native "this._childprocess.once('exit', listener);";
  void removeListenerExit(ChildProcessExitListener listener)
    native "this._childprocess.removeListener('exit', listener);";
  List<ChildProcessExitListener> listenersExit()
    native "return this._childprocess.listeners('exit');";

  Socket get stdin()
    native "return this._childprocess.stdin;";
  Socket get stdout()
    native "return this._childprocess.stdout;";
  Socket get stderr()
    native "return this._childprocess.stderr;";
  int get pid()
    native "return this._childprocess.pid;";
}

typedef void Child_processCallback(Error error, String stdout, String stderr);

class Child_process native {
  var _cp;

  Child_process() {
    _cp = _child_process;
  }

  // TODOO(jackpal): translate options into a Javascript dictionary
  ChildProcess spawn(String command, [List<String> args,
    Map<String, Object> options]){
    return new ChildProcess._from(_spawn(_cp, command, args));
  }

  // TODOO(jackpal): translate options into a Javascript dictionary
  ChildProcess exec(String command, Child_processCallback callback,
      [Map<String, Object> options]) {
    // Note the argument order to exec is different than to _exec,
    // because Dart can't have optional arguments in the middle of
    // an argument list.
    return new ChildProcess._from(_exec(_cp, command, options, callback));
  }

  static var _spawn(var cp, String command, List<String> args)
    native "return cp.spawn(command, args);";
  static var _exec(var cp, String command, Map<String, Object> options,
    Child_processCallback callback)
    native "return cp.exec(command, options, callback);";
  static var get _child_process() native "return require('child_process')";
}

var get child_process() {
  return new Child_process();
}
