// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

/**
 * Provides a Map abstraction on top of data-* attributes, similar to the
 * dataSet in the old DOM.
 */
class _DataAttributeMap implements Map<String, String> {

  final Map<String, String> _attributes;

  _DataAttributeMap(this._attributes);

  // interface Map

  // TODO: Use lazy iterator when it is available on Map.
  bool containsValue(String value) => getValues().some((v) => v == value);

  bool containsKey(String key) => _attributes.containsKey(_attr(key));

  String operator [](String key) => _attributes[_attr(key)];

  void operator []=(String key, String value) {
    _attributes[_attr(key)] = value;
  }

  String putIfAbsent(String key, String ifAbsent()) {
    if (!containsKey(key)) {
      return this[key] = ifAbsent();
    }
    return this[key];
  }

  String remove(String key) => _attributes.remove(_attr(key));

  void clear() {
    // Needs to operate on a snapshot since we are mutatiting the collection.
    for (String key in getKeys()) {
      remove(key);
    }
  }

  void forEach(void f(String key, String value)) {
    _attributes.forEach((String key, String value) {
      if (_matches(key)) {
        f(_strip(key), value);
      }
    });
  }

  Collection<String> getKeys() {
    final keys = new List<String>();
    _attributes.forEach((String key, String value) {
      if (_matches(key)) {
        keys.add(_strip(key));
      }
    });
    return keys;
  }

  Collection<String> getValues() {
    final values = new List<String>();
    _attributes.forEach((String key, String value) {
      if (_matches(key)) {
        values.add(value);
      }
    });
    return values;
  }

  int get length() => getKeys().length;

  // TODO: Use lazy iterator when it is available on Map.
  bool isEmpty() => length == 0;

  // Helpers.
  String _attr(String key) => 'data-$key';
  bool _matches(String key) => key.startsWith('data-');
  String _strip(String key) => key.substring(5);
}

class _CssClassSet implements Set<String> {

  final _ElementImpl _element;

  _CssClassSet(this._element);

  String toString() {
    return _formatSet(_read());
  }

  // interface Iterable - BEGIN
  Iterator<String> iterator() {
    return _read().iterator();
  }
  // interface Iterable - END

  // interface Collection - BEGIN
  void forEach(void f(String element)) {
    _read().forEach(f);
  }

  Collection map(f(String element)) {
    return _read().map(f);
  }

  Collection<String> filter(bool f(String element)) {
    return _read().filter(f);
  }

  bool every(bool f(String element)) {
    return _read().every(f);
  }

  bool some(bool f(String element)) {
    return _read().some(f);
  }

  bool isEmpty() {
    return _read().isEmpty();
  }

  int get length() {
    return _read().length;
  }
  // interface Collection - END

  // interface Set - BEGIN
  bool contains(String value) {
    return _read().contains(value);
  }

  void add(String value) {
    // TODO - figure out if we need to do any validation here
    // or if the browser natively does enough
    _modify((s) => s.add(value));
  }

  bool remove(String value) {
    Set<String> s = _read();
    bool result = s.remove(value);
    _write(s);
    return result;
  }

  void addAll(Collection<String> collection) {
    // TODO - see comment above about validation
    _modify((s) => s.addAll(collection));
  }

  void removeAll(Collection<String> collection) {
    _modify((s) => s.removeAll(collection));
  }

  bool isSubsetOf(Collection<String> collection) {
    return _read().isSubsetOf(collection);
  }

  bool containsAll(Collection<String> collection) {
    return _read().containsAll(collection);
  }

  Set<String> intersection(Collection<String> other) {
    return _read().intersection(other);
  }

  void clear() {
    _modify((s) => s.clear());
  }
  // interface Set - END

  /**
   * Helper method used to modify the set of css classes on this element.
   *
   *   f - callback with:
   *      s - a Set of all the css class name currently on this element.
   *
   *   After f returns, the modified set is written to the
   *       className property of this element.
   */
  void _modify( f(Set<String> s)) {
    Set<String> s = _read();
    f(s);
    _write(s);
  }

  /**
   * Read the class names from the Element class property,
   * and put them into a set (duplicates are discarded).
   */
  Set<String> _read() {
    // TODO(mattsh) simplify this once split can take regex.
    Set<String> s = new Set<String>();
    for (String name in _className().split(' ')) {
      String trimmed = name.trim();
      if (!trimmed.isEmpty()) {
        s.add(trimmed);
      }
    }
    return s;
  }

  /**
   * Read the class names as a space-separated string. This is meant to be
   * overridden by subclasses.
   */
  String _className() => _element._className;

  /**
   * Join all the elements of a set into one string and write
   * back to the element.
   */
  void _write(Set s) {
    _element._className = _formatSet(s);
  }

  String _formatSet(Set<String> s) {
    // TODO(mattsh) should be able to pass Set to String.joins http:/b/5398605
    List list = new List.from(s);
    return Strings.join(list, ' ');
  }
}

interface ElementList extends List<Element> {
  // TODO(jacobr): add element batch manipulation methods.
  ElementList filter(bool f(Element element));

  ElementList getRange(int start, int length);

  Element get first();
  // TODO(jacobr): add insertAt
}

/**
 * All your element measurement needs in one place
 */
interface ElementRect {
  // Relative to offsetParent
  ClientRect get client();
  ClientRect get offset();
  ClientRect get scroll();
  // In global coords
  ClientRect get bounding();
  // In global coords
  List<ClientRect> get clientRects();
}

interface Element extends Node, NodeSelector default _ElementFactoryProvider {
// TODO(jacobr): switch back to:
// interface Element extends Node, NodeSelector, ElementTraversal default _ElementImpl {
  Element.html(String html);
  Element.tag(String tag);

  Map<String, String> get attributes();
  void set attributes(Map<String, String> value);

  /**
   * @domName querySelectorAll, getElementsByClassName, getElementsByTagName,
   *   getElementsByTagNameNS
   */
  ElementList queryAll(String selectors);

  // TODO(jacobr): remove these methods and let them be generated automatically
  // once dart supports defining fields with the same name in an interface and
  // its parent interface.
  String get title();
  void set title(String value);

  /**
   * @domName childElementCount, firstElementChild, lastElementChild,
   *   children, Node.nodes.add
   */
  ElementList get elements();

  // TODO: The type of value should be Collection<Element>. See http://b/5392897
  void set elements(value);

  /** @domName className, classList */
  Set<String> get classes();

  // TODO: The type of value should be Collection<String>. See http://b/5392897
  void set classes(value);

  Map<String, String> get dataAttributes();
  void set dataAttributes(Map<String, String> value);

  /**
   * @domName getClientRects, getBoundingClientRect, clientHeight, clientWidth,
   * clientTop, clientLeft, offsetHeight, offsetWidth, offsetTop, offsetLeft,
   * scrollHeight, scrollWidth, scrollTop, scrollLeft
   */
  Future<ElementRect> get rect();

  /** @domName Window.getComputedStyle */
  Future<CSSStyleDeclaration> get computedStyle();

  /** @domName Window.getComputedStyle */
  Future<CSSStyleDeclaration> getComputedStyle(String pseudoElement);

  Element clone(bool deep);

  Element get parent();


  static final int ALLOW_KEYBOARD_INPUT = 1;

  final int _childElementCount;

  final HTMLCollection _children;

  final DOMTokenList classList;

  String _className;

  final int _clientHeight;

  final int _clientLeft;

  final int _clientTop;

  final int _clientWidth;

  String contentEditable;

  String dir;

  bool draggable;

  final Element _firstElementChild;

  bool hidden;

  String id;

  String innerHTML;

  final bool isContentEditable;

  String lang;

  final Element lastElementChild;

  final Element nextElementSibling;

  final int _offsetHeight;

  final int _offsetLeft;

  final Element offsetParent;

  final int _offsetTop;

  final int _offsetWidth;

  final String outerHTML;

  final Element previousElementSibling;

  final int _scrollHeight;

  int _scrollLeft;

  int _scrollTop;

  final int _scrollWidth;

  bool spellcheck;

  final CSSStyleDeclaration style;

  int tabIndex;

  final String tagName;

  final String webkitRegionOverflow;

  String webkitdropzone;

  ElementEvents get on();

  void blur();

  void click();

  void focus();

  String _getAttribute(String name);

  ClientRect _getBoundingClientRect();

  ClientRectList _getClientRects();

  bool _hasAttribute(String name);

  Element insertAdjacentElement(String where, Element element);

  void insertAdjacentHTML(String where, String html);

  void insertAdjacentText(String where, String text);

  Element query(String selectors);

  NodeList _querySelectorAll(String selectors);

  void _removeAttribute(String name);

  void scrollByLines(int lines);

  void scrollByPages(int pages);

  void scrollIntoView([bool centerIfNeeded]);

  void _setAttribute(String name, String value);

  bool matchesSelector(String selectors);

  void webkitRequestFullScreen(int flags);

}

interface ElementEvents extends Events {

  EventListenerList get abort();

  EventListenerList get beforeCopy();

  EventListenerList get beforeCut();

  EventListenerList get beforePaste();

  EventListenerList get blur();

  EventListenerList get change();

  EventListenerList get click();

  EventListenerList get contextMenu();

  EventListenerList get copy();

  EventListenerList get cut();

  EventListenerList get doubleClick();

  EventListenerList get drag();

  EventListenerList get dragEnd();

  EventListenerList get dragEnter();

  EventListenerList get dragLeave();

  EventListenerList get dragOver();

  EventListenerList get dragStart();

  EventListenerList get drop();

  EventListenerList get error();

  EventListenerList get focus();

  EventListenerList get fullscreenChange();

  EventListenerList get fullscreenError();

  EventListenerList get input();

  EventListenerList get invalid();

  EventListenerList get keyDown();

  EventListenerList get keyPress();

  EventListenerList get keyUp();

  EventListenerList get load();

  EventListenerList get mouseDown();

  EventListenerList get mouseMove();

  EventListenerList get mouseOut();

  EventListenerList get mouseOver();

  EventListenerList get mouseUp();

  EventListenerList get mouseWheel();

  EventListenerList get paste();

  EventListenerList get reset();

  EventListenerList get scroll();

  EventListenerList get search();

  EventListenerList get select();

  EventListenerList get selectStart();

  EventListenerList get submit();

  EventListenerList get touchCancel();

  EventListenerList get touchEnd();

  EventListenerList get touchLeave();

  EventListenerList get touchMove();

  EventListenerList get touchStart();

  EventListenerList get transitionEnd();
}
