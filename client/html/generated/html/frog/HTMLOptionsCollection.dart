
class _HTMLOptionsCollectionImpl extends _HTMLCollectionImpl implements HTMLOptionsCollection native "*HTMLOptionsCollection" {

  // Shadowing definition.
  int get length() native "return this.length;";

  void set length(int value) native "this.length = value;";

  int selectedIndex;

  void remove(int index) native;
}
