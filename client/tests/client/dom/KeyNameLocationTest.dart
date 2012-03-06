#library('KeyNameLocationTest');
#import('../../../testing/unittest/unittest_dom.dart');
#import('dart:dom');

// Test for existence of some KeyName and KeyLocation constants.

main() {

  forLayoutTests();

  test('keyNames', () {
      Expect.equals("DownLeft", KeyName.DOWN_LEFT);
      Expect.equals("Fn", KeyName.FN);
      Expect.equals("F1", KeyName.F1);
      Expect.equals("Meta", KeyName.META);
      Expect.equals("MediaNextTrack", KeyName.MEDIA_NEXT_TRACK);
      Expect.equals("NumLock", KeyName.NUM_LOCK);
      Expect.equals("PageDown", KeyName.PAGE_DOWN);
      Expect.equals("DeadIota", KeyName.DEAD_IOTA);
  });

  test('keyLocations', () {
      Expect.equals(0, KeyLocation.STANDARD);
      Expect.equals(1, KeyLocation.LEFT);
      Expect.equals(2, KeyLocation.RIGHT);
      Expect.equals(3, KeyLocation.NUMPAD);
      Expect.equals(4, KeyLocation.MOBILE);
      Expect.equals(5, KeyLocation.JOYSTICK);
  });
}
