// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// module os

#library('os');
#import('node.dart');
#import('nodeimpl.dart');

// Note: We wrap the os module in a class in order to
// override the cpus and networkInterfaces methods.

class Os {
  var _os;
  Os(this._os);
  String hostname() native "return this._os.hostname();";
  String type() native "return this._os.type();";
  String platform() native "return this._os.platform();";
  String arch() native "return this._os.arch();";
  String release() native "return this._os.release();";
  int uptime() native "return this._os.uptime();";
  List<double> loadAvg() native "return this._os.loadavg();";
  int totalmem() native "return this._os.totalmem();";
  int freemem() native "return this._os.freemem();";
  List<OsCpu> cpus() => new NativeList<OsCpu>(_cpus(),
    (cpu) => new OsCpu(cpu));
  _cpus() native "return this._os.cpus()";
  Map<String, List<OsNetworkInterface>> networkInterfaces() =>
      new NativeMap<List<OsNetworkInterface>>(_netInts(),
        (var netIntList) => new NativeList<OsNetworkInterface>(netIntList,
          (var netInt) => new OsNetworkInterface(netInt)));
  var _netInts() native "return this._os.networkInterfaces();";
}

Os get os() => new Os(require('os'));

class OsCpu {
  var _cpu;
  OsCpu(this._cpu);
  String get model() native "return this._cpu.model;";
  int get speed() native "return this._cpu.speed;";
  OsCpuTimes get times() => new OsCpuTimes(_times());
  var _times() native "return this._cpu.times;";
}

class OsCpuTimes {
  var _times;
  OsCpuTimes(this._times);
  int get user() native "return this._times.user;";
  int get nice() native "return this._times.nice;";
  int get sys() native "return this._times.sys;";
  int get idle() native "return this._times.idle;";
  int get irq() native "return this._times.irq;";
}

class OsNetworkInterface {
  var _netInt;
  OsNetworkInterface(this._netInt);
  String get address() native "return this._netInt.address;";
  String get family() native "return this._netInt.family;";
  bool get internal() native "return this._netInt.internal;";
}
