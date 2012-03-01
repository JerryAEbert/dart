
class _SVGImageElementImpl extends _SVGElementImpl implements SVGImageElement {
  _SVGImageElementImpl._wrap(ptr) : super._wrap(ptr);

  SVGAnimatedLength get height() => _wrap(_ptr.height);

  SVGAnimatedPreserveAspectRatio get preserveAspectRatio() => _wrap(_ptr.preserveAspectRatio);

  SVGAnimatedLength get width() => _wrap(_ptr.width);

  SVGAnimatedLength get x() => _wrap(_ptr.x);

  SVGAnimatedLength get y() => _wrap(_ptr.y);

  // From SVGURIReference

  SVGAnimatedString get href() => _wrap(_ptr.href);

  // From SVGTests

  SVGStringList get requiredExtensions() => _wrap(_ptr.requiredExtensions);

  SVGStringList get requiredFeatures() => _wrap(_ptr.requiredFeatures);

  SVGStringList get systemLanguage() => _wrap(_ptr.systemLanguage);

  bool hasExtension(String extension) {
    return _wrap(_ptr.hasExtension(_unwrap(extension)));
  }

  // From SVGLangSpace

  String get xmllang() => _wrap(_ptr.xmllang);

  void set xmllang(String value) { _ptr.xmllang = _unwrap(value); }

  String get xmlspace() => _wrap(_ptr.xmlspace);

  void set xmlspace(String value) { _ptr.xmlspace = _unwrap(value); }

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() => _wrap(_ptr.externalResourcesRequired);

  // From SVGStylable

  SVGAnimatedString get _className() => _wrap(_ptr.className);

  CSSStyleDeclaration get style() => _wrap(_ptr.style);

  CSSValue getPresentationAttribute(String name) {
    return _wrap(_ptr.getPresentationAttribute(_unwrap(name)));
  }

  // From SVGTransformable

  SVGAnimatedTransformList get transform() => _wrap(_ptr.transform);

  // From SVGLocatable

  SVGElement get farthestViewportElement() => _wrap(_ptr.farthestViewportElement);

  SVGElement get nearestViewportElement() => _wrap(_ptr.nearestViewportElement);

  SVGRect getBBox() {
    return _wrap(_ptr.getBBox());
  }

  SVGMatrix getCTM() {
    return _wrap(_ptr.getCTM());
  }

  SVGMatrix getScreenCTM() {
    return _wrap(_ptr.getScreenCTM());
  }

  SVGMatrix getTransformToElement(SVGElement element) {
    return _wrap(_ptr.getTransformToElement(_unwrap(element)));
  }
}
