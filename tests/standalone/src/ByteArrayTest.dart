// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing native byte arrays.

void testCreateByteArray() {
  ByteArray byteArray;

  byteArray = new ByteArray(0);
  Expect.equals(0, byteArray.length);

  byteArray = new ByteArray(10);
  Expect.equals(10, byteArray.length);
  for (int i = 0; i < 10; i++) {
    Expect.equals(0, byteArray[i]);
  }
}

void testSetRange() {
  ByteArray byteArray = new ByteArray(3);

  List<int> list = [10, 11, 12];
  byteArray.setRange(0, 3, list);
  for (int i = 0; i < 3; i++) {
    Expect.equals(10 + i, byteArray[i]);
  }

  byteArray[0] = 20;
  byteArray[1] = 21;
  byteArray[2] = 22;
  list.setRange(0, 3, byteArray);
  for (int i = 0; i < 3; i++) {
    Expect.equals(20 + i, list[i]);
  }

  byteArray.setRange(1, 2, const [8, 9]);
  Expect.equals(20, byteArray[0]);
  Expect.equals(8, byteArray[1]);
  Expect.equals(9, byteArray[2]);
}

void testIndexOutOfRange() {
  ByteArray byteArray = new ByteArray(3);
  List<int> list = const [0, 1, 2, 3];

  Expect.throws(() {
    byteArray.setRange(0, 4, list);
  });

  Expect.throws(() {
    byteArray.setRange(3, 1, list);
  });
}

main() {
  testCreateByteArray();
  testSetRange();
  testIndexOutOfRange();
}
