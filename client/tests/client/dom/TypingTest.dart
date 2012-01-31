#library('TypingTest');
#import('../../../testing/unittest/unittest.dart');
#import('dart:dom');

main() {
  forLayoutTests();
  test('NodeList', () {
    List<Node> asList = window.document.getElementsByTagName('body');
    // Check it's Iterable
    int counter = 0;
    for (Node node in window.document.getElementsByTagName('body')) {
      counter++;
    }
    Expect.equals(1, counter);
    counter = 0;
    window.document.getElementsByTagName('body').forEach((e) { counter++; });
    Expect.equals(1, counter);
  });
  test('StyleSheetList', () {
    List<StyleSheet> asList = window.document.styleSheets;
    // Check it's Iterable.
    int counter = 0;
    for (StyleSheet styleSheet in window.document.styleSheets) {
      counter++;
    }
    Expect.equals(0, counter);
  });
}
