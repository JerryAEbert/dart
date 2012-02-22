// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class RegExpWrapper {
  final re;

  // TODO(ahe): This constructor is clearly not const. We need some
  // better way to handle constant regular expressions. One might
  // question if regular expressions are really constant as we have
  // tests that expect an exception from the constructor.
  const RegExpWrapper(pattern, multiLine, ignoreCase, global)
    : re = makeRegExp(pattern, "${multiLine == true ? 'm' : ''}${
                                  ignoreCase == true ? 'i' : ''}${
                                  global == true ? 'g' : ''}");

  exec(str) {
    var result = JS('List', @'$0.exec($1)', re, checkString(str));
    if (JS('bool', @'$0 === null', result)) return null;
    return result;
  }

  lastIndex() => JS('List', @'$0.lastIndex', re);

  test(str) => JS('List', @'$0.test($1)', re, checkString(str));

  static matchStart(m) => JS('int', @'$0.index', m);

  static makeRegExp(pattern, flags) {
    checkString(pattern);
    try {
      return JS('Object', @'new RegExp($0, $1)', pattern, flags);
    } catch (var e) {
      throw new IllegalJSRegExpException(pattern,
                                         JS('String', @'String($0)', e));
    }
  }
}
