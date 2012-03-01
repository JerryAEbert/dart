// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

String _cachedBrowserPrefix;

String get _browserPrefix() {
  if (_cachedBrowserPrefix === null) {
    if (_Device.isFirefox) {
      _cachedBrowserPrefix = '-moz-';
    } else {
      _cachedBrowserPrefix = '-webkit-';
    }
    // TODO(jacobr): support IE 9.0 and Opera as well.
  }
  return _cachedBrowserPrefix;
}

class _CSSStyleDeclarationImpl implements CSSStyleDeclaration native "*CSSStyleDeclaration" {


  String cssText;

  final int length;

  final _CSSRuleImpl parentRule;

  _CSSValueImpl getPropertyCSSValue(String propertyName) native;

  String getPropertyPriority(String propertyName) native;

  String getPropertyShorthand(String propertyName) native;

  String getPropertyValue(String propertyName) native;

  bool isPropertyImplicit(String propertyName) native;

  String item(int index) native;

  String removeProperty(String propertyName) native;

  void setProperty(String propertyName, String value, [String priority = null]) native;


  // TODO(jacobr): generate this list of properties using the existing script.
    /** Gets the value of "animation" */
  String get animation() =>
    getPropertyValue('${_browserPrefix}animation');

  /** Sets the value of "animation" */
  void set animation(var value) {
    setProperty('${_browserPrefix}animation', value, '');
  }

  /** Gets the value of "animation-delay" */
  String get animationDelay() =>
    getPropertyValue('${_browserPrefix}animation-delay');

  /** Sets the value of "animation-delay" */
  void set animationDelay(var value) {
    setProperty('${_browserPrefix}animation-delay', value, '');
  }

  /** Gets the value of "animation-direction" */
  String get animationDirection() =>
    getPropertyValue('${_browserPrefix}animation-direction');

  /** Sets the value of "animation-direction" */
  void set animationDirection(var value) {
    setProperty('${_browserPrefix}animation-direction', value, '');
  }

  /** Gets the value of "animation-duration" */
  String get animationDuration() =>
    getPropertyValue('${_browserPrefix}animation-duration');

  /** Sets the value of "animation-duration" */
  void set animationDuration(var value) {
    setProperty('${_browserPrefix}animation-duration', value, '');
  }

  /** Gets the value of "animation-fill-mode" */
  String get animationFillMode() =>
    getPropertyValue('${_browserPrefix}animation-fill-mode');

  /** Sets the value of "animation-fill-mode" */
  void set animationFillMode(var value) {
    setProperty('${_browserPrefix}animation-fill-mode', value, '');
  }

  /** Gets the value of "animation-iteration-count" */
  String get animationIterationCount() =>
    getPropertyValue('${_browserPrefix}animation-iteration-count');

  /** Sets the value of "animation-iteration-count" */
  void set animationIterationCount(var value) {
    setProperty('${_browserPrefix}animation-iteration-count', value, '');
  }

  /** Gets the value of "animation-name" */
  String get animationName() =>
    getPropertyValue('${_browserPrefix}animation-name');

  /** Sets the value of "animation-name" */
  void set animationName(var value) {
    setProperty('${_browserPrefix}animation-name', value, '');
  }

  /** Gets the value of "animation-play-state" */
  String get animationPlayState() =>
    getPropertyValue('${_browserPrefix}animation-play-state');

  /** Sets the value of "animation-play-state" */
  void set animationPlayState(var value) {
    setProperty('${_browserPrefix}animation-play-state', value, '');
  }

  /** Gets the value of "animation-timing-function" */
  String get animationTimingFunction() =>
    getPropertyValue('${_browserPrefix}animation-timing-function');

  /** Sets the value of "animation-timing-function" */
  void set animationTimingFunction(var value) {
    setProperty('${_browserPrefix}animation-timing-function', value, '');
  }

  /** Gets the value of "appearance" */
  String get appearance() =>
    getPropertyValue('${_browserPrefix}appearance');

  /** Sets the value of "appearance" */
  void set appearance(var value) {
    setProperty('${_browserPrefix}appearance', value, '');
  }

  /** Gets the value of "backface-visibility" */
  String get backfaceVisibility() =>
    getPropertyValue('${_browserPrefix}backface-visibility');

  /** Sets the value of "backface-visibility" */
  void set backfaceVisibility(var value) {
    setProperty('${_browserPrefix}backface-visibility', value, '');
  }

  /** Gets the value of "background" */
  String get background() =>
    getPropertyValue('background');

  /** Sets the value of "background" */
  void set background(var value) {
    setProperty('background', value, '');
  }

  /** Gets the value of "background-attachment" */
  String get backgroundAttachment() =>
    getPropertyValue('background-attachment');

  /** Sets the value of "background-attachment" */
  void set backgroundAttachment(var value) {
    setProperty('background-attachment', value, '');
  }

  /** Gets the value of "background-clip" */
  String get backgroundClip() =>
    getPropertyValue('background-clip');

  /** Sets the value of "background-clip" */
  void set backgroundClip(var value) {
    setProperty('background-clip', value, '');
  }

  /** Gets the value of "background-color" */
  String get backgroundColor() =>
    getPropertyValue('background-color');

  /** Sets the value of "background-color" */
  void set backgroundColor(var value) {
    setProperty('background-color', value, '');
  }

  /** Gets the value of "background-composite" */
  String get backgroundComposite() =>
    getPropertyValue('${_browserPrefix}background-composite');

  /** Sets the value of "background-composite" */
  void set backgroundComposite(var value) {
    setProperty('${_browserPrefix}background-composite', value, '');
  }

  /** Gets the value of "background-image" */
  String get backgroundImage() =>
    getPropertyValue('background-image');

  /** Sets the value of "background-image" */
  void set backgroundImage(var value) {
    setProperty('background-image', value, '');
  }

  /** Gets the value of "background-origin" */
  String get backgroundOrigin() =>
    getPropertyValue('background-origin');

  /** Sets the value of "background-origin" */
  void set backgroundOrigin(var value) {
    setProperty('background-origin', value, '');
  }

  /** Gets the value of "background-position" */
  String get backgroundPosition() =>
    getPropertyValue('background-position');

  /** Sets the value of "background-position" */
  void set backgroundPosition(var value) {
    setProperty('background-position', value, '');
  }

  /** Gets the value of "background-position-x" */
  String get backgroundPositionX() =>
    getPropertyValue('background-position-x');

  /** Sets the value of "background-position-x" */
  void set backgroundPositionX(var value) {
    setProperty('background-position-x', value, '');
  }

  /** Gets the value of "background-position-y" */
  String get backgroundPositionY() =>
    getPropertyValue('background-position-y');

  /** Sets the value of "background-position-y" */
  void set backgroundPositionY(var value) {
    setProperty('background-position-y', value, '');
  }

  /** Gets the value of "background-repeat" */
  String get backgroundRepeat() =>
    getPropertyValue('background-repeat');

  /** Sets the value of "background-repeat" */
  void set backgroundRepeat(var value) {
    setProperty('background-repeat', value, '');
  }

  /** Gets the value of "background-repeat-x" */
  String get backgroundRepeatX() =>
    getPropertyValue('background-repeat-x');

  /** Sets the value of "background-repeat-x" */
  void set backgroundRepeatX(var value) {
    setProperty('background-repeat-x', value, '');
  }

  /** Gets the value of "background-repeat-y" */
  String get backgroundRepeatY() =>
    getPropertyValue('background-repeat-y');

  /** Sets the value of "background-repeat-y" */
  void set backgroundRepeatY(var value) {
    setProperty('background-repeat-y', value, '');
  }

  /** Gets the value of "background-size" */
  String get backgroundSize() =>
    getPropertyValue('background-size');

  /** Sets the value of "background-size" */
  void set backgroundSize(var value) {
    setProperty('background-size', value, '');
  }

  /** Gets the value of "border" */
  String get border() =>
    getPropertyValue('border');

  /** Sets the value of "border" */
  void set border(var value) {
    setProperty('border', value, '');
  }

  /** Gets the value of "border-after" */
  String get borderAfter() =>
    getPropertyValue('${_browserPrefix}border-after');

  /** Sets the value of "border-after" */
  void set borderAfter(var value) {
    setProperty('${_browserPrefix}border-after', value, '');
  }

  /** Gets the value of "border-after-color" */
  String get borderAfterColor() =>
    getPropertyValue('${_browserPrefix}border-after-color');

  /** Sets the value of "border-after-color" */
  void set borderAfterColor(var value) {
    setProperty('${_browserPrefix}border-after-color', value, '');
  }

  /** Gets the value of "border-after-style" */
  String get borderAfterStyle() =>
    getPropertyValue('${_browserPrefix}border-after-style');

  /** Sets the value of "border-after-style" */
  void set borderAfterStyle(var value) {
    setProperty('${_browserPrefix}border-after-style', value, '');
  }

  /** Gets the value of "border-after-width" */
  String get borderAfterWidth() =>
    getPropertyValue('${_browserPrefix}border-after-width');

  /** Sets the value of "border-after-width" */
  void set borderAfterWidth(var value) {
    setProperty('${_browserPrefix}border-after-width', value, '');
  }

  /** Gets the value of "border-before" */
  String get borderBefore() =>
    getPropertyValue('${_browserPrefix}border-before');

  /** Sets the value of "border-before" */
  void set borderBefore(var value) {
    setProperty('${_browserPrefix}border-before', value, '');
  }

  /** Gets the value of "border-before-color" */
  String get borderBeforeColor() =>
    getPropertyValue('${_browserPrefix}border-before-color');

  /** Sets the value of "border-before-color" */
  void set borderBeforeColor(var value) {
    setProperty('${_browserPrefix}border-before-color', value, '');
  }

  /** Gets the value of "border-before-style" */
  String get borderBeforeStyle() =>
    getPropertyValue('${_browserPrefix}border-before-style');

  /** Sets the value of "border-before-style" */
  void set borderBeforeStyle(var value) {
    setProperty('${_browserPrefix}border-before-style', value, '');
  }

  /** Gets the value of "border-before-width" */
  String get borderBeforeWidth() =>
    getPropertyValue('${_browserPrefix}border-before-width');

  /** Sets the value of "border-before-width" */
  void set borderBeforeWidth(var value) {
    setProperty('${_browserPrefix}border-before-width', value, '');
  }

  /** Gets the value of "border-bottom" */
  String get borderBottom() =>
    getPropertyValue('border-bottom');

  /** Sets the value of "border-bottom" */
  void set borderBottom(var value) {
    setProperty('border-bottom', value, '');
  }

  /** Gets the value of "border-bottom-color" */
  String get borderBottomColor() =>
    getPropertyValue('border-bottom-color');

  /** Sets the value of "border-bottom-color" */
  void set borderBottomColor(var value) {
    setProperty('border-bottom-color', value, '');
  }

  /** Gets the value of "border-bottom-left-radius" */
  String get borderBottomLeftRadius() =>
    getPropertyValue('border-bottom-left-radius');

  /** Sets the value of "border-bottom-left-radius" */
  void set borderBottomLeftRadius(var value) {
    setProperty('border-bottom-left-radius', value, '');
  }

  /** Gets the value of "border-bottom-right-radius" */
  String get borderBottomRightRadius() =>
    getPropertyValue('border-bottom-right-radius');

  /** Sets the value of "border-bottom-right-radius" */
  void set borderBottomRightRadius(var value) {
    setProperty('border-bottom-right-radius', value, '');
  }

  /** Gets the value of "border-bottom-style" */
  String get borderBottomStyle() =>
    getPropertyValue('border-bottom-style');

  /** Sets the value of "border-bottom-style" */
  void set borderBottomStyle(var value) {
    setProperty('border-bottom-style', value, '');
  }

  /** Gets the value of "border-bottom-width" */
  String get borderBottomWidth() =>
    getPropertyValue('border-bottom-width');

  /** Sets the value of "border-bottom-width" */
  void set borderBottomWidth(var value) {
    setProperty('border-bottom-width', value, '');
  }

  /** Gets the value of "border-collapse" */
  String get borderCollapse() =>
    getPropertyValue('border-collapse');

  /** Sets the value of "border-collapse" */
  void set borderCollapse(var value) {
    setProperty('border-collapse', value, '');
  }

  /** Gets the value of "border-color" */
  String get borderColor() =>
    getPropertyValue('border-color');

  /** Sets the value of "border-color" */
  void set borderColor(var value) {
    setProperty('border-color', value, '');
  }

  /** Gets the value of "border-end" */
  String get borderEnd() =>
    getPropertyValue('${_browserPrefix}border-end');

  /** Sets the value of "border-end" */
  void set borderEnd(var value) {
    setProperty('${_browserPrefix}border-end', value, '');
  }

  /** Gets the value of "border-end-color" */
  String get borderEndColor() =>
    getPropertyValue('${_browserPrefix}border-end-color');

  /** Sets the value of "border-end-color" */
  void set borderEndColor(var value) {
    setProperty('${_browserPrefix}border-end-color', value, '');
  }

  /** Gets the value of "border-end-style" */
  String get borderEndStyle() =>
    getPropertyValue('${_browserPrefix}border-end-style');

  /** Sets the value of "border-end-style" */
  void set borderEndStyle(var value) {
    setProperty('${_browserPrefix}border-end-style', value, '');
  }

  /** Gets the value of "border-end-width" */
  String get borderEndWidth() =>
    getPropertyValue('${_browserPrefix}border-end-width');

  /** Sets the value of "border-end-width" */
  void set borderEndWidth(var value) {
    setProperty('${_browserPrefix}border-end-width', value, '');
  }

  /** Gets the value of "border-fit" */
  String get borderFit() =>
    getPropertyValue('${_browserPrefix}border-fit');

  /** Sets the value of "border-fit" */
  void set borderFit(var value) {
    setProperty('${_browserPrefix}border-fit', value, '');
  }

  /** Gets the value of "border-horizontal-spacing" */
  String get borderHorizontalSpacing() =>
    getPropertyValue('${_browserPrefix}border-horizontal-spacing');

  /** Sets the value of "border-horizontal-spacing" */
  void set borderHorizontalSpacing(var value) {
    setProperty('${_browserPrefix}border-horizontal-spacing', value, '');
  }

  /** Gets the value of "border-image" */
  String get borderImage() =>
    getPropertyValue('border-image');

  /** Sets the value of "border-image" */
  void set borderImage(var value) {
    setProperty('border-image', value, '');
  }

  /** Gets the value of "border-image-outset" */
  String get borderImageOutset() =>
    getPropertyValue('border-image-outset');

  /** Sets the value of "border-image-outset" */
  void set borderImageOutset(var value) {
    setProperty('border-image-outset', value, '');
  }

  /** Gets the value of "border-image-repeat" */
  String get borderImageRepeat() =>
    getPropertyValue('border-image-repeat');

  /** Sets the value of "border-image-repeat" */
  void set borderImageRepeat(var value) {
    setProperty('border-image-repeat', value, '');
  }

  /** Gets the value of "border-image-slice" */
  String get borderImageSlice() =>
    getPropertyValue('border-image-slice');

  /** Sets the value of "border-image-slice" */
  void set borderImageSlice(var value) {
    setProperty('border-image-slice', value, '');
  }

  /** Gets the value of "border-image-source" */
  String get borderImageSource() =>
    getPropertyValue('border-image-source');

  /** Sets the value of "border-image-source" */
  void set borderImageSource(var value) {
    setProperty('border-image-source', value, '');
  }

  /** Gets the value of "border-image-width" */
  String get borderImageWidth() =>
    getPropertyValue('border-image-width');

  /** Sets the value of "border-image-width" */
  void set borderImageWidth(var value) {
    setProperty('border-image-width', value, '');
  }

  /** Gets the value of "border-left" */
  String get borderLeft() =>
    getPropertyValue('border-left');

  /** Sets the value of "border-left" */
  void set borderLeft(var value) {
    setProperty('border-left', value, '');
  }

  /** Gets the value of "border-left-color" */
  String get borderLeftColor() =>
    getPropertyValue('border-left-color');

  /** Sets the value of "border-left-color" */
  void set borderLeftColor(var value) {
    setProperty('border-left-color', value, '');
  }

  /** Gets the value of "border-left-style" */
  String get borderLeftStyle() =>
    getPropertyValue('border-left-style');

  /** Sets the value of "border-left-style" */
  void set borderLeftStyle(var value) {
    setProperty('border-left-style', value, '');
  }

  /** Gets the value of "border-left-width" */
  String get borderLeftWidth() =>
    getPropertyValue('border-left-width');

  /** Sets the value of "border-left-width" */
  void set borderLeftWidth(var value) {
    setProperty('border-left-width', value, '');
  }

  /** Gets the value of "border-radius" */
  String get borderRadius() =>
    getPropertyValue('border-radius');

  /** Sets the value of "border-radius" */
  void set borderRadius(var value) {
    setProperty('border-radius', value, '');
  }

  /** Gets the value of "border-right" */
  String get borderRight() =>
    getPropertyValue('border-right');

  /** Sets the value of "border-right" */
  void set borderRight(var value) {
    setProperty('border-right', value, '');
  }

  /** Gets the value of "border-right-color" */
  String get borderRightColor() =>
    getPropertyValue('border-right-color');

  /** Sets the value of "border-right-color" */
  void set borderRightColor(var value) {
    setProperty('border-right-color', value, '');
  }

  /** Gets the value of "border-right-style" */
  String get borderRightStyle() =>
    getPropertyValue('border-right-style');

  /** Sets the value of "border-right-style" */
  void set borderRightStyle(var value) {
    setProperty('border-right-style', value, '');
  }

  /** Gets the value of "border-right-width" */
  String get borderRightWidth() =>
    getPropertyValue('border-right-width');

  /** Sets the value of "border-right-width" */
  void set borderRightWidth(var value) {
    setProperty('border-right-width', value, '');
  }

  /** Gets the value of "border-spacing" */
  String get borderSpacing() =>
    getPropertyValue('border-spacing');

  /** Sets the value of "border-spacing" */
  void set borderSpacing(var value) {
    setProperty('border-spacing', value, '');
  }

  /** Gets the value of "border-start" */
  String get borderStart() =>
    getPropertyValue('${_browserPrefix}border-start');

  /** Sets the value of "border-start" */
  void set borderStart(var value) {
    setProperty('${_browserPrefix}border-start', value, '');
  }

  /** Gets the value of "border-start-color" */
  String get borderStartColor() =>
    getPropertyValue('${_browserPrefix}border-start-color');

  /** Sets the value of "border-start-color" */
  void set borderStartColor(var value) {
    setProperty('${_browserPrefix}border-start-color', value, '');
  }

  /** Gets the value of "border-start-style" */
  String get borderStartStyle() =>
    getPropertyValue('${_browserPrefix}border-start-style');

  /** Sets the value of "border-start-style" */
  void set borderStartStyle(var value) {
    setProperty('${_browserPrefix}border-start-style', value, '');
  }

  /** Gets the value of "border-start-width" */
  String get borderStartWidth() =>
    getPropertyValue('${_browserPrefix}border-start-width');

  /** Sets the value of "border-start-width" */
  void set borderStartWidth(var value) {
    setProperty('${_browserPrefix}border-start-width', value, '');
  }

  /** Gets the value of "border-style" */
  String get borderStyle() =>
    getPropertyValue('border-style');

  /** Sets the value of "border-style" */
  void set borderStyle(var value) {
    setProperty('border-style', value, '');
  }

  /** Gets the value of "border-top" */
  String get borderTop() =>
    getPropertyValue('border-top');

  /** Sets the value of "border-top" */
  void set borderTop(var value) {
    setProperty('border-top', value, '');
  }

  /** Gets the value of "border-top-color" */
  String get borderTopColor() =>
    getPropertyValue('border-top-color');

  /** Sets the value of "border-top-color" */
  void set borderTopColor(var value) {
    setProperty('border-top-color', value, '');
  }

  /** Gets the value of "border-top-left-radius" */
  String get borderTopLeftRadius() =>
    getPropertyValue('border-top-left-radius');

  /** Sets the value of "border-top-left-radius" */
  void set borderTopLeftRadius(var value) {
    setProperty('border-top-left-radius', value, '');
  }

  /** Gets the value of "border-top-right-radius" */
  String get borderTopRightRadius() =>
    getPropertyValue('border-top-right-radius');

  /** Sets the value of "border-top-right-radius" */
  void set borderTopRightRadius(var value) {
    setProperty('border-top-right-radius', value, '');
  }

  /** Gets the value of "border-top-style" */
  String get borderTopStyle() =>
    getPropertyValue('border-top-style');

  /** Sets the value of "border-top-style" */
  void set borderTopStyle(var value) {
    setProperty('border-top-style', value, '');
  }

  /** Gets the value of "border-top-width" */
  String get borderTopWidth() =>
    getPropertyValue('border-top-width');

  /** Sets the value of "border-top-width" */
  void set borderTopWidth(var value) {
    setProperty('border-top-width', value, '');
  }

  /** Gets the value of "border-vertical-spacing" */
  String get borderVerticalSpacing() =>
    getPropertyValue('${_browserPrefix}border-vertical-spacing');

  /** Sets the value of "border-vertical-spacing" */
  void set borderVerticalSpacing(var value) {
    setProperty('${_browserPrefix}border-vertical-spacing', value, '');
  }

  /** Gets the value of "border-width" */
  String get borderWidth() =>
    getPropertyValue('border-width');

  /** Sets the value of "border-width" */
  void set borderWidth(var value) {
    setProperty('border-width', value, '');
  }

  /** Gets the value of "bottom" */
  String get bottom() =>
    getPropertyValue('bottom');

  /** Sets the value of "bottom" */
  void set bottom(var value) {
    setProperty('bottom', value, '');
  }

  /** Gets the value of "box-align" */
  String get boxAlign() =>
    getPropertyValue('${_browserPrefix}box-align');

  /** Sets the value of "box-align" */
  void set boxAlign(var value) {
    setProperty('${_browserPrefix}box-align', value, '');
  }

  /** Gets the value of "box-direction" */
  String get boxDirection() =>
    getPropertyValue('${_browserPrefix}box-direction');

  /** Sets the value of "box-direction" */
  void set boxDirection(var value) {
    setProperty('${_browserPrefix}box-direction', value, '');
  }

  /** Gets the value of "box-flex" */
  String get boxFlex() =>
    getPropertyValue('${_browserPrefix}box-flex');

  /** Sets the value of "box-flex" */
  void set boxFlex(var value) {
    setProperty('${_browserPrefix}box-flex', value, '');
  }

  /** Gets the value of "box-flex-group" */
  String get boxFlexGroup() =>
    getPropertyValue('${_browserPrefix}box-flex-group');

  /** Sets the value of "box-flex-group" */
  void set boxFlexGroup(var value) {
    setProperty('${_browserPrefix}box-flex-group', value, '');
  }

  /** Gets the value of "box-lines" */
  String get boxLines() =>
    getPropertyValue('${_browserPrefix}box-lines');

  /** Sets the value of "box-lines" */
  void set boxLines(var value) {
    setProperty('${_browserPrefix}box-lines', value, '');
  }

  /** Gets the value of "box-ordinal-group" */
  String get boxOrdinalGroup() =>
    getPropertyValue('${_browserPrefix}box-ordinal-group');

  /** Sets the value of "box-ordinal-group" */
  void set boxOrdinalGroup(var value) {
    setProperty('${_browserPrefix}box-ordinal-group', value, '');
  }

  /** Gets the value of "box-orient" */
  String get boxOrient() =>
    getPropertyValue('${_browserPrefix}box-orient');

  /** Sets the value of "box-orient" */
  void set boxOrient(var value) {
    setProperty('${_browserPrefix}box-orient', value, '');
  }

  /** Gets the value of "box-pack" */
  String get boxPack() =>
    getPropertyValue('${_browserPrefix}box-pack');

  /** Sets the value of "box-pack" */
  void set boxPack(var value) {
    setProperty('${_browserPrefix}box-pack', value, '');
  }

  /** Gets the value of "box-reflect" */
  String get boxReflect() =>
    getPropertyValue('${_browserPrefix}box-reflect');

  /** Sets the value of "box-reflect" */
  void set boxReflect(var value) {
    setProperty('${_browserPrefix}box-reflect', value, '');
  }

  /** Gets the value of "box-shadow" */
  String get boxShadow() =>
    getPropertyValue('box-shadow');

  /** Sets the value of "box-shadow" */
  void set boxShadow(var value) {
    setProperty('box-shadow', value, '');
  }

  /** Gets the value of "box-sizing" */
  String get boxSizing() =>
    getPropertyValue('box-sizing');

  /** Sets the value of "box-sizing" */
  void set boxSizing(var value) {
    setProperty('box-sizing', value, '');
  }

  /** Gets the value of "caption-side" */
  String get captionSide() =>
    getPropertyValue('caption-side');

  /** Sets the value of "caption-side" */
  void set captionSide(var value) {
    setProperty('caption-side', value, '');
  }

  /** Gets the value of "clear" */
  String get clear() =>
    getPropertyValue('clear');

  /** Sets the value of "clear" */
  void set clear(var value) {
    setProperty('clear', value, '');
  }

  /** Gets the value of "clip" */
  String get clip() =>
    getPropertyValue('clip');

  /** Sets the value of "clip" */
  void set clip(var value) {
    setProperty('clip', value, '');
  }

  /** Gets the value of "color" */
  String get color() =>
    getPropertyValue('color');

  /** Sets the value of "color" */
  void set color(var value) {
    setProperty('color', value, '');
  }

  /** Gets the value of "color-correction" */
  String get colorCorrection() =>
    getPropertyValue('${_browserPrefix}color-correction');

  /** Sets the value of "color-correction" */
  void set colorCorrection(var value) {
    setProperty('${_browserPrefix}color-correction', value, '');
  }

  /** Gets the value of "column-break-after" */
  String get columnBreakAfter() =>
    getPropertyValue('${_browserPrefix}column-break-after');

  /** Sets the value of "column-break-after" */
  void set columnBreakAfter(var value) {
    setProperty('${_browserPrefix}column-break-after', value, '');
  }

  /** Gets the value of "column-break-before" */
  String get columnBreakBefore() =>
    getPropertyValue('${_browserPrefix}column-break-before');

  /** Sets the value of "column-break-before" */
  void set columnBreakBefore(var value) {
    setProperty('${_browserPrefix}column-break-before', value, '');
  }

  /** Gets the value of "column-break-inside" */
  String get columnBreakInside() =>
    getPropertyValue('${_browserPrefix}column-break-inside');

  /** Sets the value of "column-break-inside" */
  void set columnBreakInside(var value) {
    setProperty('${_browserPrefix}column-break-inside', value, '');
  }

  /** Gets the value of "column-count" */
  String get columnCount() =>
    getPropertyValue('${_browserPrefix}column-count');

  /** Sets the value of "column-count" */
  void set columnCount(var value) {
    setProperty('${_browserPrefix}column-count', value, '');
  }

  /** Gets the value of "column-gap" */
  String get columnGap() =>
    getPropertyValue('${_browserPrefix}column-gap');

  /** Sets the value of "column-gap" */
  void set columnGap(var value) {
    setProperty('${_browserPrefix}column-gap', value, '');
  }

  /** Gets the value of "column-rule" */
  String get columnRule() =>
    getPropertyValue('${_browserPrefix}column-rule');

  /** Sets the value of "column-rule" */
  void set columnRule(var value) {
    setProperty('${_browserPrefix}column-rule', value, '');
  }

  /** Gets the value of "column-rule-color" */
  String get columnRuleColor() =>
    getPropertyValue('${_browserPrefix}column-rule-color');

  /** Sets the value of "column-rule-color" */
  void set columnRuleColor(var value) {
    setProperty('${_browserPrefix}column-rule-color', value, '');
  }

  /** Gets the value of "column-rule-style" */
  String get columnRuleStyle() =>
    getPropertyValue('${_browserPrefix}column-rule-style');

  /** Sets the value of "column-rule-style" */
  void set columnRuleStyle(var value) {
    setProperty('${_browserPrefix}column-rule-style', value, '');
  }

  /** Gets the value of "column-rule-width" */
  String get columnRuleWidth() =>
    getPropertyValue('${_browserPrefix}column-rule-width');

  /** Sets the value of "column-rule-width" */
  void set columnRuleWidth(var value) {
    setProperty('${_browserPrefix}column-rule-width', value, '');
  }

  /** Gets the value of "column-span" */
  String get columnSpan() =>
    getPropertyValue('${_browserPrefix}column-span');

  /** Sets the value of "column-span" */
  void set columnSpan(var value) {
    setProperty('${_browserPrefix}column-span', value, '');
  }

  /** Gets the value of "column-width" */
  String get columnWidth() =>
    getPropertyValue('${_browserPrefix}column-width');

  /** Sets the value of "column-width" */
  void set columnWidth(var value) {
    setProperty('${_browserPrefix}column-width', value, '');
  }

  /** Gets the value of "columns" */
  String get columns() =>
    getPropertyValue('${_browserPrefix}columns');

  /** Sets the value of "columns" */
  void set columns(var value) {
    setProperty('${_browserPrefix}columns', value, '');
  }

  /** Gets the value of "content" */
  String get content() =>
    getPropertyValue('content');

  /** Sets the value of "content" */
  void set content(var value) {
    setProperty('content', value, '');
  }

  /** Gets the value of "counter-increment" */
  String get counterIncrement() =>
    getPropertyValue('counter-increment');

  /** Sets the value of "counter-increment" */
  void set counterIncrement(var value) {
    setProperty('counter-increment', value, '');
  }

  /** Gets the value of "counter-reset" */
  String get counterReset() =>
    getPropertyValue('counter-reset');

  /** Sets the value of "counter-reset" */
  void set counterReset(var value) {
    setProperty('counter-reset', value, '');
  }

  /** Gets the value of "cursor" */
  String get cursor() =>
    getPropertyValue('cursor');

  /** Sets the value of "cursor" */
  void set cursor(var value) {
    setProperty('cursor', value, '');
  }

  /** Gets the value of "direction" */
  String get direction() =>
    getPropertyValue('direction');

  /** Sets the value of "direction" */
  void set direction(var value) {
    setProperty('direction', value, '');
  }

  /** Gets the value of "display" */
  String get display() =>
    getPropertyValue('display');

  /** Sets the value of "display" */
  void set display(var value) {
    setProperty('display', value, '');
  }

  /** Gets the value of "empty-cells" */
  String get emptyCells() =>
    getPropertyValue('empty-cells');

  /** Sets the value of "empty-cells" */
  void set emptyCells(var value) {
    setProperty('empty-cells', value, '');
  }

  /** Gets the value of "filter" */
  String get filter() =>
    getPropertyValue('${_browserPrefix}filter');

  /** Sets the value of "filter" */
  void set filter(var value) {
    setProperty('${_browserPrefix}filter', value, '');
  }

  /** Gets the value of "flex-align" */
  String get flexAlign() =>
    getPropertyValue('${_browserPrefix}flex-align');

  /** Sets the value of "flex-align" */
  void set flexAlign(var value) {
    setProperty('${_browserPrefix}flex-align', value, '');
  }

  /** Gets the value of "flex-flow" */
  String get flexFlow() =>
    getPropertyValue('${_browserPrefix}flex-flow');

  /** Sets the value of "flex-flow" */
  void set flexFlow(var value) {
    setProperty('${_browserPrefix}flex-flow', value, '');
  }

  /** Gets the value of "flex-order" */
  String get flexOrder() =>
    getPropertyValue('${_browserPrefix}flex-order');

  /** Sets the value of "flex-order" */
  void set flexOrder(var value) {
    setProperty('${_browserPrefix}flex-order', value, '');
  }

  /** Gets the value of "flex-pack" */
  String get flexPack() =>
    getPropertyValue('${_browserPrefix}flex-pack');

  /** Sets the value of "flex-pack" */
  void set flexPack(var value) {
    setProperty('${_browserPrefix}flex-pack', value, '');
  }

  /** Gets the value of "float" */
  String get float() =>
    getPropertyValue('float');

  /** Sets the value of "float" */
  void set float(var value) {
    setProperty('float', value, '');
  }

  /** Gets the value of "flow-from" */
  String get flowFrom() =>
    getPropertyValue('${_browserPrefix}flow-from');

  /** Sets the value of "flow-from" */
  void set flowFrom(var value) {
    setProperty('${_browserPrefix}flow-from', value, '');
  }

  /** Gets the value of "flow-into" */
  String get flowInto() =>
    getPropertyValue('${_browserPrefix}flow-into');

  /** Sets the value of "flow-into" */
  void set flowInto(var value) {
    setProperty('${_browserPrefix}flow-into', value, '');
  }

  /** Gets the value of "font" */
  String get font() =>
    getPropertyValue('font');

  /** Sets the value of "font" */
  void set font(var value) {
    setProperty('font', value, '');
  }

  /** Gets the value of "font-family" */
  String get fontFamily() =>
    getPropertyValue('font-family');

  /** Sets the value of "font-family" */
  void set fontFamily(var value) {
    setProperty('font-family', value, '');
  }

  /** Gets the value of "font-feature-settings" */
  String get fontFeatureSettings() =>
    getPropertyValue('${_browserPrefix}font-feature-settings');

  /** Sets the value of "font-feature-settings" */
  void set fontFeatureSettings(var value) {
    setProperty('${_browserPrefix}font-feature-settings', value, '');
  }

  /** Gets the value of "font-size" */
  String get fontSize() =>
    getPropertyValue('font-size');

  /** Sets the value of "font-size" */
  void set fontSize(var value) {
    setProperty('font-size', value, '');
  }

  /** Gets the value of "font-size-delta" */
  String get fontSizeDelta() =>
    getPropertyValue('${_browserPrefix}font-size-delta');

  /** Sets the value of "font-size-delta" */
  void set fontSizeDelta(var value) {
    setProperty('${_browserPrefix}font-size-delta', value, '');
  }

  /** Gets the value of "font-smoothing" */
  String get fontSmoothing() =>
    getPropertyValue('${_browserPrefix}font-smoothing');

  /** Sets the value of "font-smoothing" */
  void set fontSmoothing(var value) {
    setProperty('${_browserPrefix}font-smoothing', value, '');
  }

  /** Gets the value of "font-stretch" */
  String get fontStretch() =>
    getPropertyValue('font-stretch');

  /** Sets the value of "font-stretch" */
  void set fontStretch(var value) {
    setProperty('font-stretch', value, '');
  }

  /** Gets the value of "font-style" */
  String get fontStyle() =>
    getPropertyValue('font-style');

  /** Sets the value of "font-style" */
  void set fontStyle(var value) {
    setProperty('font-style', value, '');
  }

  /** Gets the value of "font-variant" */
  String get fontVariant() =>
    getPropertyValue('font-variant');

  /** Sets the value of "font-variant" */
  void set fontVariant(var value) {
    setProperty('font-variant', value, '');
  }

  /** Gets the value of "font-weight" */
  String get fontWeight() =>
    getPropertyValue('font-weight');

  /** Sets the value of "font-weight" */
  void set fontWeight(var value) {
    setProperty('font-weight', value, '');
  }

  /** Gets the value of "height" */
  String get height() =>
    getPropertyValue('height');

  /** Sets the value of "height" */
  void set height(var value) {
    setProperty('height', value, '');
  }

  /** Gets the value of "highlight" */
  String get highlight() =>
    getPropertyValue('${_browserPrefix}highlight');

  /** Sets the value of "highlight" */
  void set highlight(var value) {
    setProperty('${_browserPrefix}highlight', value, '');
  }

  /** Gets the value of "hyphenate-character" */
  String get hyphenateCharacter() =>
    getPropertyValue('${_browserPrefix}hyphenate-character');

  /** Sets the value of "hyphenate-character" */
  void set hyphenateCharacter(var value) {
    setProperty('${_browserPrefix}hyphenate-character', value, '');
  }

  /** Gets the value of "hyphenate-limit-after" */
  String get hyphenateLimitAfter() =>
    getPropertyValue('${_browserPrefix}hyphenate-limit-after');

  /** Sets the value of "hyphenate-limit-after" */
  void set hyphenateLimitAfter(var value) {
    setProperty('${_browserPrefix}hyphenate-limit-after', value, '');
  }

  /** Gets the value of "hyphenate-limit-before" */
  String get hyphenateLimitBefore() =>
    getPropertyValue('${_browserPrefix}hyphenate-limit-before');

  /** Sets the value of "hyphenate-limit-before" */
  void set hyphenateLimitBefore(var value) {
    setProperty('${_browserPrefix}hyphenate-limit-before', value, '');
  }

  /** Gets the value of "hyphenate-limit-lines" */
  String get hyphenateLimitLines() =>
    getPropertyValue('${_browserPrefix}hyphenate-limit-lines');

  /** Sets the value of "hyphenate-limit-lines" */
  void set hyphenateLimitLines(var value) {
    setProperty('${_browserPrefix}hyphenate-limit-lines', value, '');
  }

  /** Gets the value of "hyphens" */
  String get hyphens() =>
    getPropertyValue('${_browserPrefix}hyphens');

  /** Sets the value of "hyphens" */
  void set hyphens(var value) {
    setProperty('${_browserPrefix}hyphens', value, '');
  }

  /** Gets the value of "image-rendering" */
  String get imageRendering() =>
    getPropertyValue('image-rendering');

  /** Sets the value of "image-rendering" */
  void set imageRendering(var value) {
    setProperty('image-rendering', value, '');
  }

  /** Gets the value of "left" */
  String get left() =>
    getPropertyValue('left');

  /** Sets the value of "left" */
  void set left(var value) {
    setProperty('left', value, '');
  }

  /** Gets the value of "letter-spacing" */
  String get letterSpacing() =>
    getPropertyValue('letter-spacing');

  /** Sets the value of "letter-spacing" */
  void set letterSpacing(var value) {
    setProperty('letter-spacing', value, '');
  }

  /** Gets the value of "line-box-contain" */
  String get lineBoxContain() =>
    getPropertyValue('${_browserPrefix}line-box-contain');

  /** Sets the value of "line-box-contain" */
  void set lineBoxContain(var value) {
    setProperty('${_browserPrefix}line-box-contain', value, '');
  }

  /** Gets the value of "line-break" */
  String get lineBreak() =>
    getPropertyValue('${_browserPrefix}line-break');

  /** Sets the value of "line-break" */
  void set lineBreak(var value) {
    setProperty('${_browserPrefix}line-break', value, '');
  }

  /** Gets the value of "line-clamp" */
  String get lineClamp() =>
    getPropertyValue('${_browserPrefix}line-clamp');

  /** Sets the value of "line-clamp" */
  void set lineClamp(var value) {
    setProperty('${_browserPrefix}line-clamp', value, '');
  }

  /** Gets the value of "line-height" */
  String get lineHeight() =>
    getPropertyValue('line-height');

  /** Sets the value of "line-height" */
  void set lineHeight(var value) {
    setProperty('line-height', value, '');
  }

  /** Gets the value of "list-style" */
  String get listStyle() =>
    getPropertyValue('list-style');

  /** Sets the value of "list-style" */
  void set listStyle(var value) {
    setProperty('list-style', value, '');
  }

  /** Gets the value of "list-style-image" */
  String get listStyleImage() =>
    getPropertyValue('list-style-image');

  /** Sets the value of "list-style-image" */
  void set listStyleImage(var value) {
    setProperty('list-style-image', value, '');
  }

  /** Gets the value of "list-style-position" */
  String get listStylePosition() =>
    getPropertyValue('list-style-position');

  /** Sets the value of "list-style-position" */
  void set listStylePosition(var value) {
    setProperty('list-style-position', value, '');
  }

  /** Gets the value of "list-style-type" */
  String get listStyleType() =>
    getPropertyValue('list-style-type');

  /** Sets the value of "list-style-type" */
  void set listStyleType(var value) {
    setProperty('list-style-type', value, '');
  }

  /** Gets the value of "locale" */
  String get locale() =>
    getPropertyValue('${_browserPrefix}locale');

  /** Sets the value of "locale" */
  void set locale(var value) {
    setProperty('${_browserPrefix}locale', value, '');
  }

  /** Gets the value of "logical-height" */
  String get logicalHeight() =>
    getPropertyValue('${_browserPrefix}logical-height');

  /** Sets the value of "logical-height" */
  void set logicalHeight(var value) {
    setProperty('${_browserPrefix}logical-height', value, '');
  }

  /** Gets the value of "logical-width" */
  String get logicalWidth() =>
    getPropertyValue('${_browserPrefix}logical-width');

  /** Sets the value of "logical-width" */
  void set logicalWidth(var value) {
    setProperty('${_browserPrefix}logical-width', value, '');
  }

  /** Gets the value of "margin" */
  String get margin() =>
    getPropertyValue('margin');

  /** Sets the value of "margin" */
  void set margin(var value) {
    setProperty('margin', value, '');
  }

  /** Gets the value of "margin-after" */
  String get marginAfter() =>
    getPropertyValue('${_browserPrefix}margin-after');

  /** Sets the value of "margin-after" */
  void set marginAfter(var value) {
    setProperty('${_browserPrefix}margin-after', value, '');
  }

  /** Gets the value of "margin-after-collapse" */
  String get marginAfterCollapse() =>
    getPropertyValue('${_browserPrefix}margin-after-collapse');

  /** Sets the value of "margin-after-collapse" */
  void set marginAfterCollapse(var value) {
    setProperty('${_browserPrefix}margin-after-collapse', value, '');
  }

  /** Gets the value of "margin-before" */
  String get marginBefore() =>
    getPropertyValue('${_browserPrefix}margin-before');

  /** Sets the value of "margin-before" */
  void set marginBefore(var value) {
    setProperty('${_browserPrefix}margin-before', value, '');
  }

  /** Gets the value of "margin-before-collapse" */
  String get marginBeforeCollapse() =>
    getPropertyValue('${_browserPrefix}margin-before-collapse');

  /** Sets the value of "margin-before-collapse" */
  void set marginBeforeCollapse(var value) {
    setProperty('${_browserPrefix}margin-before-collapse', value, '');
  }

  /** Gets the value of "margin-bottom" */
  String get marginBottom() =>
    getPropertyValue('margin-bottom');

  /** Sets the value of "margin-bottom" */
  void set marginBottom(var value) {
    setProperty('margin-bottom', value, '');
  }

  /** Gets the value of "margin-bottom-collapse" */
  String get marginBottomCollapse() =>
    getPropertyValue('${_browserPrefix}margin-bottom-collapse');

  /** Sets the value of "margin-bottom-collapse" */
  void set marginBottomCollapse(var value) {
    setProperty('${_browserPrefix}margin-bottom-collapse', value, '');
  }

  /** Gets the value of "margin-collapse" */
  String get marginCollapse() =>
    getPropertyValue('${_browserPrefix}margin-collapse');

  /** Sets the value of "margin-collapse" */
  void set marginCollapse(var value) {
    setProperty('${_browserPrefix}margin-collapse', value, '');
  }

  /** Gets the value of "margin-end" */
  String get marginEnd() =>
    getPropertyValue('${_browserPrefix}margin-end');

  /** Sets the value of "margin-end" */
  void set marginEnd(var value) {
    setProperty('${_browserPrefix}margin-end', value, '');
  }

  /** Gets the value of "margin-left" */
  String get marginLeft() =>
    getPropertyValue('margin-left');

  /** Sets the value of "margin-left" */
  void set marginLeft(var value) {
    setProperty('margin-left', value, '');
  }

  /** Gets the value of "margin-right" */
  String get marginRight() =>
    getPropertyValue('margin-right');

  /** Sets the value of "margin-right" */
  void set marginRight(var value) {
    setProperty('margin-right', value, '');
  }

  /** Gets the value of "margin-start" */
  String get marginStart() =>
    getPropertyValue('${_browserPrefix}margin-start');

  /** Sets the value of "margin-start" */
  void set marginStart(var value) {
    setProperty('${_browserPrefix}margin-start', value, '');
  }

  /** Gets the value of "margin-top" */
  String get marginTop() =>
    getPropertyValue('margin-top');

  /** Sets the value of "margin-top" */
  void set marginTop(var value) {
    setProperty('margin-top', value, '');
  }

  /** Gets the value of "margin-top-collapse" */
  String get marginTopCollapse() =>
    getPropertyValue('${_browserPrefix}margin-top-collapse');

  /** Sets the value of "margin-top-collapse" */
  void set marginTopCollapse(var value) {
    setProperty('${_browserPrefix}margin-top-collapse', value, '');
  }

  /** Gets the value of "marquee" */
  String get marquee() =>
    getPropertyValue('${_browserPrefix}marquee');

  /** Sets the value of "marquee" */
  void set marquee(var value) {
    setProperty('${_browserPrefix}marquee', value, '');
  }

  /** Gets the value of "marquee-direction" */
  String get marqueeDirection() =>
    getPropertyValue('${_browserPrefix}marquee-direction');

  /** Sets the value of "marquee-direction" */
  void set marqueeDirection(var value) {
    setProperty('${_browserPrefix}marquee-direction', value, '');
  }

  /** Gets the value of "marquee-increment" */
  String get marqueeIncrement() =>
    getPropertyValue('${_browserPrefix}marquee-increment');

  /** Sets the value of "marquee-increment" */
  void set marqueeIncrement(var value) {
    setProperty('${_browserPrefix}marquee-increment', value, '');
  }

  /** Gets the value of "marquee-repetition" */
  String get marqueeRepetition() =>
    getPropertyValue('${_browserPrefix}marquee-repetition');

  /** Sets the value of "marquee-repetition" */
  void set marqueeRepetition(var value) {
    setProperty('${_browserPrefix}marquee-repetition', value, '');
  }

  /** Gets the value of "marquee-speed" */
  String get marqueeSpeed() =>
    getPropertyValue('${_browserPrefix}marquee-speed');

  /** Sets the value of "marquee-speed" */
  void set marqueeSpeed(var value) {
    setProperty('${_browserPrefix}marquee-speed', value, '');
  }

  /** Gets the value of "marquee-style" */
  String get marqueeStyle() =>
    getPropertyValue('${_browserPrefix}marquee-style');

  /** Sets the value of "marquee-style" */
  void set marqueeStyle(var value) {
    setProperty('${_browserPrefix}marquee-style', value, '');
  }

  /** Gets the value of "mask" */
  String get mask() =>
    getPropertyValue('${_browserPrefix}mask');

  /** Sets the value of "mask" */
  void set mask(var value) {
    setProperty('${_browserPrefix}mask', value, '');
  }

  /** Gets the value of "mask-attachment" */
  String get maskAttachment() =>
    getPropertyValue('${_browserPrefix}mask-attachment');

  /** Sets the value of "mask-attachment" */
  void set maskAttachment(var value) {
    setProperty('${_browserPrefix}mask-attachment', value, '');
  }

  /** Gets the value of "mask-box-image" */
  String get maskBoxImage() =>
    getPropertyValue('${_browserPrefix}mask-box-image');

  /** Sets the value of "mask-box-image" */
  void set maskBoxImage(var value) {
    setProperty('${_browserPrefix}mask-box-image', value, '');
  }

  /** Gets the value of "mask-box-image-outset" */
  String get maskBoxImageOutset() =>
    getPropertyValue('${_browserPrefix}mask-box-image-outset');

  /** Sets the value of "mask-box-image-outset" */
  void set maskBoxImageOutset(var value) {
    setProperty('${_browserPrefix}mask-box-image-outset', value, '');
  }

  /** Gets the value of "mask-box-image-repeat" */
  String get maskBoxImageRepeat() =>
    getPropertyValue('${_browserPrefix}mask-box-image-repeat');

  /** Sets the value of "mask-box-image-repeat" */
  void set maskBoxImageRepeat(var value) {
    setProperty('${_browserPrefix}mask-box-image-repeat', value, '');
  }

  /** Gets the value of "mask-box-image-slice" */
  String get maskBoxImageSlice() =>
    getPropertyValue('${_browserPrefix}mask-box-image-slice');

  /** Sets the value of "mask-box-image-slice" */
  void set maskBoxImageSlice(var value) {
    setProperty('${_browserPrefix}mask-box-image-slice', value, '');
  }

  /** Gets the value of "mask-box-image-source" */
  String get maskBoxImageSource() =>
    getPropertyValue('${_browserPrefix}mask-box-image-source');

  /** Sets the value of "mask-box-image-source" */
  void set maskBoxImageSource(var value) {
    setProperty('${_browserPrefix}mask-box-image-source', value, '');
  }

  /** Gets the value of "mask-box-image-width" */
  String get maskBoxImageWidth() =>
    getPropertyValue('${_browserPrefix}mask-box-image-width');

  /** Sets the value of "mask-box-image-width" */
  void set maskBoxImageWidth(var value) {
    setProperty('${_browserPrefix}mask-box-image-width', value, '');
  }

  /** Gets the value of "mask-clip" */
  String get maskClip() =>
    getPropertyValue('${_browserPrefix}mask-clip');

  /** Sets the value of "mask-clip" */
  void set maskClip(var value) {
    setProperty('${_browserPrefix}mask-clip', value, '');
  }

  /** Gets the value of "mask-composite" */
  String get maskComposite() =>
    getPropertyValue('${_browserPrefix}mask-composite');

  /** Sets the value of "mask-composite" */
  void set maskComposite(var value) {
    setProperty('${_browserPrefix}mask-composite', value, '');
  }

  /** Gets the value of "mask-image" */
  String get maskImage() =>
    getPropertyValue('${_browserPrefix}mask-image');

  /** Sets the value of "mask-image" */
  void set maskImage(var value) {
    setProperty('${_browserPrefix}mask-image', value, '');
  }

  /** Gets the value of "mask-origin" */
  String get maskOrigin() =>
    getPropertyValue('${_browserPrefix}mask-origin');

  /** Sets the value of "mask-origin" */
  void set maskOrigin(var value) {
    setProperty('${_browserPrefix}mask-origin', value, '');
  }

  /** Gets the value of "mask-position" */
  String get maskPosition() =>
    getPropertyValue('${_browserPrefix}mask-position');

  /** Sets the value of "mask-position" */
  void set maskPosition(var value) {
    setProperty('${_browserPrefix}mask-position', value, '');
  }

  /** Gets the value of "mask-position-x" */
  String get maskPositionX() =>
    getPropertyValue('${_browserPrefix}mask-position-x');

  /** Sets the value of "mask-position-x" */
  void set maskPositionX(var value) {
    setProperty('${_browserPrefix}mask-position-x', value, '');
  }

  /** Gets the value of "mask-position-y" */
  String get maskPositionY() =>
    getPropertyValue('${_browserPrefix}mask-position-y');

  /** Sets the value of "mask-position-y" */
  void set maskPositionY(var value) {
    setProperty('${_browserPrefix}mask-position-y', value, '');
  }

  /** Gets the value of "mask-repeat" */
  String get maskRepeat() =>
    getPropertyValue('${_browserPrefix}mask-repeat');

  /** Sets the value of "mask-repeat" */
  void set maskRepeat(var value) {
    setProperty('${_browserPrefix}mask-repeat', value, '');
  }

  /** Gets the value of "mask-repeat-x" */
  String get maskRepeatX() =>
    getPropertyValue('${_browserPrefix}mask-repeat-x');

  /** Sets the value of "mask-repeat-x" */
  void set maskRepeatX(var value) {
    setProperty('${_browserPrefix}mask-repeat-x', value, '');
  }

  /** Gets the value of "mask-repeat-y" */
  String get maskRepeatY() =>
    getPropertyValue('${_browserPrefix}mask-repeat-y');

  /** Sets the value of "mask-repeat-y" */
  void set maskRepeatY(var value) {
    setProperty('${_browserPrefix}mask-repeat-y', value, '');
  }

  /** Gets the value of "mask-size" */
  String get maskSize() =>
    getPropertyValue('${_browserPrefix}mask-size');

  /** Sets the value of "mask-size" */
  void set maskSize(var value) {
    setProperty('${_browserPrefix}mask-size', value, '');
  }

  /** Gets the value of "match-nearest-mail-blockquote-color" */
  String get matchNearestMailBlockquoteColor() =>
    getPropertyValue('${_browserPrefix}match-nearest-mail-blockquote-color');

  /** Sets the value of "match-nearest-mail-blockquote-color" */
  void set matchNearestMailBlockquoteColor(var value) {
    setProperty('${_browserPrefix}match-nearest-mail-blockquote-color', value, '');
  }

  /** Gets the value of "max-height" */
  String get maxHeight() =>
    getPropertyValue('max-height');

  /** Sets the value of "max-height" */
  void set maxHeight(var value) {
    setProperty('max-height', value, '');
  }

  /** Gets the value of "max-logical-height" */
  String get maxLogicalHeight() =>
    getPropertyValue('${_browserPrefix}max-logical-height');

  /** Sets the value of "max-logical-height" */
  void set maxLogicalHeight(var value) {
    setProperty('${_browserPrefix}max-logical-height', value, '');
  }

  /** Gets the value of "max-logical-width" */
  String get maxLogicalWidth() =>
    getPropertyValue('${_browserPrefix}max-logical-width');

  /** Sets the value of "max-logical-width" */
  void set maxLogicalWidth(var value) {
    setProperty('${_browserPrefix}max-logical-width', value, '');
  }

  /** Gets the value of "max-width" */
  String get maxWidth() =>
    getPropertyValue('max-width');

  /** Sets the value of "max-width" */
  void set maxWidth(var value) {
    setProperty('max-width', value, '');
  }

  /** Gets the value of "min-height" */
  String get minHeight() =>
    getPropertyValue('min-height');

  /** Sets the value of "min-height" */
  void set minHeight(var value) {
    setProperty('min-height', value, '');
  }

  /** Gets the value of "min-logical-height" */
  String get minLogicalHeight() =>
    getPropertyValue('${_browserPrefix}min-logical-height');

  /** Sets the value of "min-logical-height" */
  void set minLogicalHeight(var value) {
    setProperty('${_browserPrefix}min-logical-height', value, '');
  }

  /** Gets the value of "min-logical-width" */
  String get minLogicalWidth() =>
    getPropertyValue('${_browserPrefix}min-logical-width');

  /** Sets the value of "min-logical-width" */
  void set minLogicalWidth(var value) {
    setProperty('${_browserPrefix}min-logical-width', value, '');
  }

  /** Gets the value of "min-width" */
  String get minWidth() =>
    getPropertyValue('min-width');

  /** Sets the value of "min-width" */
  void set minWidth(var value) {
    setProperty('min-width', value, '');
  }

  /** Gets the value of "nbsp-mode" */
  String get nbspMode() =>
    getPropertyValue('${_browserPrefix}nbsp-mode');

  /** Sets the value of "nbsp-mode" */
  void set nbspMode(var value) {
    setProperty('${_browserPrefix}nbsp-mode', value, '');
  }

  /** Gets the value of "opacity" */
  String get opacity() =>
    getPropertyValue('opacity');

  /** Sets the value of "opacity" */
  void set opacity(var value) {
    setProperty('opacity', value, '');
  }

  /** Gets the value of "orphans" */
  String get orphans() =>
    getPropertyValue('orphans');

  /** Sets the value of "orphans" */
  void set orphans(var value) {
    setProperty('orphans', value, '');
  }

  /** Gets the value of "outline" */
  String get outline() =>
    getPropertyValue('outline');

  /** Sets the value of "outline" */
  void set outline(var value) {
    setProperty('outline', value, '');
  }

  /** Gets the value of "outline-color" */
  String get outlineColor() =>
    getPropertyValue('outline-color');

  /** Sets the value of "outline-color" */
  void set outlineColor(var value) {
    setProperty('outline-color', value, '');
  }

  /** Gets the value of "outline-offset" */
  String get outlineOffset() =>
    getPropertyValue('outline-offset');

  /** Sets the value of "outline-offset" */
  void set outlineOffset(var value) {
    setProperty('outline-offset', value, '');
  }

  /** Gets the value of "outline-style" */
  String get outlineStyle() =>
    getPropertyValue('outline-style');

  /** Sets the value of "outline-style" */
  void set outlineStyle(var value) {
    setProperty('outline-style', value, '');
  }

  /** Gets the value of "outline-width" */
  String get outlineWidth() =>
    getPropertyValue('outline-width');

  /** Sets the value of "outline-width" */
  void set outlineWidth(var value) {
    setProperty('outline-width', value, '');
  }

  /** Gets the value of "overflow" */
  String get overflow() =>
    getPropertyValue('overflow');

  /** Sets the value of "overflow" */
  void set overflow(var value) {
    setProperty('overflow', value, '');
  }

  /** Gets the value of "overflow-x" */
  String get overflowX() =>
    getPropertyValue('overflow-x');

  /** Sets the value of "overflow-x" */
  void set overflowX(var value) {
    setProperty('overflow-x', value, '');
  }

  /** Gets the value of "overflow-y" */
  String get overflowY() =>
    getPropertyValue('overflow-y');

  /** Sets the value of "overflow-y" */
  void set overflowY(var value) {
    setProperty('overflow-y', value, '');
  }

  /** Gets the value of "padding" */
  String get padding() =>
    getPropertyValue('padding');

  /** Sets the value of "padding" */
  void set padding(var value) {
    setProperty('padding', value, '');
  }

  /** Gets the value of "padding-after" */
  String get paddingAfter() =>
    getPropertyValue('${_browserPrefix}padding-after');

  /** Sets the value of "padding-after" */
  void set paddingAfter(var value) {
    setProperty('${_browserPrefix}padding-after', value, '');
  }

  /** Gets the value of "padding-before" */
  String get paddingBefore() =>
    getPropertyValue('${_browserPrefix}padding-before');

  /** Sets the value of "padding-before" */
  void set paddingBefore(var value) {
    setProperty('${_browserPrefix}padding-before', value, '');
  }

  /** Gets the value of "padding-bottom" */
  String get paddingBottom() =>
    getPropertyValue('padding-bottom');

  /** Sets the value of "padding-bottom" */
  void set paddingBottom(var value) {
    setProperty('padding-bottom', value, '');
  }

  /** Gets the value of "padding-end" */
  String get paddingEnd() =>
    getPropertyValue('${_browserPrefix}padding-end');

  /** Sets the value of "padding-end" */
  void set paddingEnd(var value) {
    setProperty('${_browserPrefix}padding-end', value, '');
  }

  /** Gets the value of "padding-left" */
  String get paddingLeft() =>
    getPropertyValue('padding-left');

  /** Sets the value of "padding-left" */
  void set paddingLeft(var value) {
    setProperty('padding-left', value, '');
  }

  /** Gets the value of "padding-right" */
  String get paddingRight() =>
    getPropertyValue('padding-right');

  /** Sets the value of "padding-right" */
  void set paddingRight(var value) {
    setProperty('padding-right', value, '');
  }

  /** Gets the value of "padding-start" */
  String get paddingStart() =>
    getPropertyValue('${_browserPrefix}padding-start');

  /** Sets the value of "padding-start" */
  void set paddingStart(var value) {
    setProperty('${_browserPrefix}padding-start', value, '');
  }

  /** Gets the value of "padding-top" */
  String get paddingTop() =>
    getPropertyValue('padding-top');

  /** Sets the value of "padding-top" */
  void set paddingTop(var value) {
    setProperty('padding-top', value, '');
  }

  /** Gets the value of "page" */
  String get page() =>
    getPropertyValue('page');

  /** Sets the value of "page" */
  void set page(var value) {
    setProperty('page', value, '');
  }

  /** Gets the value of "page-break-after" */
  String get pageBreakAfter() =>
    getPropertyValue('page-break-after');

  /** Sets the value of "page-break-after" */
  void set pageBreakAfter(var value) {
    setProperty('page-break-after', value, '');
  }

  /** Gets the value of "page-break-before" */
  String get pageBreakBefore() =>
    getPropertyValue('page-break-before');

  /** Sets the value of "page-break-before" */
  void set pageBreakBefore(var value) {
    setProperty('page-break-before', value, '');
  }

  /** Gets the value of "page-break-inside" */
  String get pageBreakInside() =>
    getPropertyValue('page-break-inside');

  /** Sets the value of "page-break-inside" */
  void set pageBreakInside(var value) {
    setProperty('page-break-inside', value, '');
  }

  /** Gets the value of "perspective" */
  String get perspective() =>
    getPropertyValue('${_browserPrefix}perspective');

  /** Sets the value of "perspective" */
  void set perspective(var value) {
    setProperty('${_browserPrefix}perspective', value, '');
  }

  /** Gets the value of "perspective-origin" */
  String get perspectiveOrigin() =>
    getPropertyValue('${_browserPrefix}perspective-origin');

  /** Sets the value of "perspective-origin" */
  void set perspectiveOrigin(var value) {
    setProperty('${_browserPrefix}perspective-origin', value, '');
  }

  /** Gets the value of "perspective-origin-x" */
  String get perspectiveOriginX() =>
    getPropertyValue('${_browserPrefix}perspective-origin-x');

  /** Sets the value of "perspective-origin-x" */
  void set perspectiveOriginX(var value) {
    setProperty('${_browserPrefix}perspective-origin-x', value, '');
  }

  /** Gets the value of "perspective-origin-y" */
  String get perspectiveOriginY() =>
    getPropertyValue('${_browserPrefix}perspective-origin-y');

  /** Sets the value of "perspective-origin-y" */
  void set perspectiveOriginY(var value) {
    setProperty('${_browserPrefix}perspective-origin-y', value, '');
  }

  /** Gets the value of "pointer-events" */
  String get pointerEvents() =>
    getPropertyValue('pointer-events');

  /** Sets the value of "pointer-events" */
  void set pointerEvents(var value) {
    setProperty('pointer-events', value, '');
  }

  /** Gets the value of "position" */
  String get position() =>
    getPropertyValue('position');

  /** Sets the value of "position" */
  void set position(var value) {
    setProperty('position', value, '');
  }

  /** Gets the value of "quotes" */
  String get quotes() =>
    getPropertyValue('quotes');

  /** Sets the value of "quotes" */
  void set quotes(var value) {
    setProperty('quotes', value, '');
  }

  /** Gets the value of "region-break-after" */
  String get regionBreakAfter() =>
    getPropertyValue('${_browserPrefix}region-break-after');

  /** Sets the value of "region-break-after" */
  void set regionBreakAfter(var value) {
    setProperty('${_browserPrefix}region-break-after', value, '');
  }

  /** Gets the value of "region-break-before" */
  String get regionBreakBefore() =>
    getPropertyValue('${_browserPrefix}region-break-before');

  /** Sets the value of "region-break-before" */
  void set regionBreakBefore(var value) {
    setProperty('${_browserPrefix}region-break-before', value, '');
  }

  /** Gets the value of "region-break-inside" */
  String get regionBreakInside() =>
    getPropertyValue('${_browserPrefix}region-break-inside');

  /** Sets the value of "region-break-inside" */
  void set regionBreakInside(var value) {
    setProperty('${_browserPrefix}region-break-inside', value, '');
  }

  /** Gets the value of "region-overflow" */
  String get regionOverflow() =>
    getPropertyValue('${_browserPrefix}region-overflow');

  /** Sets the value of "region-overflow" */
  void set regionOverflow(var value) {
    setProperty('${_browserPrefix}region-overflow', value, '');
  }

  /** Gets the value of "resize" */
  String get resize() =>
    getPropertyValue('resize');

  /** Sets the value of "resize" */
  void set resize(var value) {
    setProperty('resize', value, '');
  }

  /** Gets the value of "right" */
  String get right() =>
    getPropertyValue('right');

  /** Sets the value of "right" */
  void set right(var value) {
    setProperty('right', value, '');
  }

  /** Gets the value of "rtl-ordering" */
  String get rtlOrdering() =>
    getPropertyValue('${_browserPrefix}rtl-ordering');

  /** Sets the value of "rtl-ordering" */
  void set rtlOrdering(var value) {
    setProperty('${_browserPrefix}rtl-ordering', value, '');
  }

  /** Gets the value of "size" */
  String get size() =>
    getPropertyValue('size');

  /** Sets the value of "size" */
  void set size(var value) {
    setProperty('size', value, '');
  }

  /** Gets the value of "speak" */
  String get speak() =>
    getPropertyValue('speak');

  /** Sets the value of "speak" */
  void set speak(var value) {
    setProperty('speak', value, '');
  }

  /** Gets the value of "src" */
  String get src() =>
    getPropertyValue('src');

  /** Sets the value of "src" */
  void set src(var value) {
    setProperty('src', value, '');
  }

  /** Gets the value of "table-layout" */
  String get tableLayout() =>
    getPropertyValue('table-layout');

  /** Sets the value of "table-layout" */
  void set tableLayout(var value) {
    setProperty('table-layout', value, '');
  }

  /** Gets the value of "tap-highlight-color" */
  String get tapHighlightColor() =>
    getPropertyValue('${_browserPrefix}tap-highlight-color');

  /** Sets the value of "tap-highlight-color" */
  void set tapHighlightColor(var value) {
    setProperty('${_browserPrefix}tap-highlight-color', value, '');
  }

  /** Gets the value of "text-align" */
  String get textAlign() =>
    getPropertyValue('text-align');

  /** Sets the value of "text-align" */
  void set textAlign(var value) {
    setProperty('text-align', value, '');
  }

  /** Gets the value of "text-combine" */
  String get textCombine() =>
    getPropertyValue('${_browserPrefix}text-combine');

  /** Sets the value of "text-combine" */
  void set textCombine(var value) {
    setProperty('${_browserPrefix}text-combine', value, '');
  }

  /** Gets the value of "text-decoration" */
  String get textDecoration() =>
    getPropertyValue('text-decoration');

  /** Sets the value of "text-decoration" */
  void set textDecoration(var value) {
    setProperty('text-decoration', value, '');
  }

  /** Gets the value of "text-decorations-in-effect" */
  String get textDecorationsInEffect() =>
    getPropertyValue('${_browserPrefix}text-decorations-in-effect');

  /** Sets the value of "text-decorations-in-effect" */
  void set textDecorationsInEffect(var value) {
    setProperty('${_browserPrefix}text-decorations-in-effect', value, '');
  }

  /** Gets the value of "text-emphasis" */
  String get textEmphasis() =>
    getPropertyValue('${_browserPrefix}text-emphasis');

  /** Sets the value of "text-emphasis" */
  void set textEmphasis(var value) {
    setProperty('${_browserPrefix}text-emphasis', value, '');
  }

  /** Gets the value of "text-emphasis-color" */
  String get textEmphasisColor() =>
    getPropertyValue('${_browserPrefix}text-emphasis-color');

  /** Sets the value of "text-emphasis-color" */
  void set textEmphasisColor(var value) {
    setProperty('${_browserPrefix}text-emphasis-color', value, '');
  }

  /** Gets the value of "text-emphasis-position" */
  String get textEmphasisPosition() =>
    getPropertyValue('${_browserPrefix}text-emphasis-position');

  /** Sets the value of "text-emphasis-position" */
  void set textEmphasisPosition(var value) {
    setProperty('${_browserPrefix}text-emphasis-position', value, '');
  }

  /** Gets the value of "text-emphasis-style" */
  String get textEmphasisStyle() =>
    getPropertyValue('${_browserPrefix}text-emphasis-style');

  /** Sets the value of "text-emphasis-style" */
  void set textEmphasisStyle(var value) {
    setProperty('${_browserPrefix}text-emphasis-style', value, '');
  }

  /** Gets the value of "text-fill-color" */
  String get textFillColor() =>
    getPropertyValue('${_browserPrefix}text-fill-color');

  /** Sets the value of "text-fill-color" */
  void set textFillColor(var value) {
    setProperty('${_browserPrefix}text-fill-color', value, '');
  }

  /** Gets the value of "text-indent" */
  String get textIndent() =>
    getPropertyValue('text-indent');

  /** Sets the value of "text-indent" */
  void set textIndent(var value) {
    setProperty('text-indent', value, '');
  }

  /** Gets the value of "text-line-through" */
  String get textLineThrough() =>
    getPropertyValue('text-line-through');

  /** Sets the value of "text-line-through" */
  void set textLineThrough(var value) {
    setProperty('text-line-through', value, '');
  }

  /** Gets the value of "text-line-through-color" */
  String get textLineThroughColor() =>
    getPropertyValue('text-line-through-color');

  /** Sets the value of "text-line-through-color" */
  void set textLineThroughColor(var value) {
    setProperty('text-line-through-color', value, '');
  }

  /** Gets the value of "text-line-through-mode" */
  String get textLineThroughMode() =>
    getPropertyValue('text-line-through-mode');

  /** Sets the value of "text-line-through-mode" */
  void set textLineThroughMode(var value) {
    setProperty('text-line-through-mode', value, '');
  }

  /** Gets the value of "text-line-through-style" */
  String get textLineThroughStyle() =>
    getPropertyValue('text-line-through-style');

  /** Sets the value of "text-line-through-style" */
  void set textLineThroughStyle(var value) {
    setProperty('text-line-through-style', value, '');
  }

  /** Gets the value of "text-line-through-width" */
  String get textLineThroughWidth() =>
    getPropertyValue('text-line-through-width');

  /** Sets the value of "text-line-through-width" */
  void set textLineThroughWidth(var value) {
    setProperty('text-line-through-width', value, '');
  }

  /** Gets the value of "text-orientation" */
  String get textOrientation() =>
    getPropertyValue('${_browserPrefix}text-orientation');

  /** Sets the value of "text-orientation" */
  void set textOrientation(var value) {
    setProperty('${_browserPrefix}text-orientation', value, '');
  }

  /** Gets the value of "text-overflow" */
  String get textOverflow() =>
    getPropertyValue('text-overflow');

  /** Sets the value of "text-overflow" */
  void set textOverflow(var value) {
    setProperty('text-overflow', value, '');
  }

  /** Gets the value of "text-overline" */
  String get textOverline() =>
    getPropertyValue('text-overline');

  /** Sets the value of "text-overline" */
  void set textOverline(var value) {
    setProperty('text-overline', value, '');
  }

  /** Gets the value of "text-overline-color" */
  String get textOverlineColor() =>
    getPropertyValue('text-overline-color');

  /** Sets the value of "text-overline-color" */
  void set textOverlineColor(var value) {
    setProperty('text-overline-color', value, '');
  }

  /** Gets the value of "text-overline-mode" */
  String get textOverlineMode() =>
    getPropertyValue('text-overline-mode');

  /** Sets the value of "text-overline-mode" */
  void set textOverlineMode(var value) {
    setProperty('text-overline-mode', value, '');
  }

  /** Gets the value of "text-overline-style" */
  String get textOverlineStyle() =>
    getPropertyValue('text-overline-style');

  /** Sets the value of "text-overline-style" */
  void set textOverlineStyle(var value) {
    setProperty('text-overline-style', value, '');
  }

  /** Gets the value of "text-overline-width" */
  String get textOverlineWidth() =>
    getPropertyValue('text-overline-width');

  /** Sets the value of "text-overline-width" */
  void set textOverlineWidth(var value) {
    setProperty('text-overline-width', value, '');
  }

  /** Gets the value of "text-rendering" */
  String get textRendering() =>
    getPropertyValue('text-rendering');

  /** Sets the value of "text-rendering" */
  void set textRendering(var value) {
    setProperty('text-rendering', value, '');
  }

  /** Gets the value of "text-security" */
  String get textSecurity() =>
    getPropertyValue('${_browserPrefix}text-security');

  /** Sets the value of "text-security" */
  void set textSecurity(var value) {
    setProperty('${_browserPrefix}text-security', value, '');
  }

  /** Gets the value of "text-shadow" */
  String get textShadow() =>
    getPropertyValue('text-shadow');

  /** Sets the value of "text-shadow" */
  void set textShadow(var value) {
    setProperty('text-shadow', value, '');
  }

  /** Gets the value of "text-size-adjust" */
  String get textSizeAdjust() =>
    getPropertyValue('${_browserPrefix}text-size-adjust');

  /** Sets the value of "text-size-adjust" */
  void set textSizeAdjust(var value) {
    setProperty('${_browserPrefix}text-size-adjust', value, '');
  }

  /** Gets the value of "text-stroke" */
  String get textStroke() =>
    getPropertyValue('${_browserPrefix}text-stroke');

  /** Sets the value of "text-stroke" */
  void set textStroke(var value) {
    setProperty('${_browserPrefix}text-stroke', value, '');
  }

  /** Gets the value of "text-stroke-color" */
  String get textStrokeColor() =>
    getPropertyValue('${_browserPrefix}text-stroke-color');

  /** Sets the value of "text-stroke-color" */
  void set textStrokeColor(var value) {
    setProperty('${_browserPrefix}text-stroke-color', value, '');
  }

  /** Gets the value of "text-stroke-width" */
  String get textStrokeWidth() =>
    getPropertyValue('${_browserPrefix}text-stroke-width');

  /** Sets the value of "text-stroke-width" */
  void set textStrokeWidth(var value) {
    setProperty('${_browserPrefix}text-stroke-width', value, '');
  }

  /** Gets the value of "text-transform" */
  String get textTransform() =>
    getPropertyValue('text-transform');

  /** Sets the value of "text-transform" */
  void set textTransform(var value) {
    setProperty('text-transform', value, '');
  }

  /** Gets the value of "text-underline" */
  String get textUnderline() =>
    getPropertyValue('text-underline');

  /** Sets the value of "text-underline" */
  void set textUnderline(var value) {
    setProperty('text-underline', value, '');
  }

  /** Gets the value of "text-underline-color" */
  String get textUnderlineColor() =>
    getPropertyValue('text-underline-color');

  /** Sets the value of "text-underline-color" */
  void set textUnderlineColor(var value) {
    setProperty('text-underline-color', value, '');
  }

  /** Gets the value of "text-underline-mode" */
  String get textUnderlineMode() =>
    getPropertyValue('text-underline-mode');

  /** Sets the value of "text-underline-mode" */
  void set textUnderlineMode(var value) {
    setProperty('text-underline-mode', value, '');
  }

  /** Gets the value of "text-underline-style" */
  String get textUnderlineStyle() =>
    getPropertyValue('text-underline-style');

  /** Sets the value of "text-underline-style" */
  void set textUnderlineStyle(var value) {
    setProperty('text-underline-style', value, '');
  }

  /** Gets the value of "text-underline-width" */
  String get textUnderlineWidth() =>
    getPropertyValue('text-underline-width');

  /** Sets the value of "text-underline-width" */
  void set textUnderlineWidth(var value) {
    setProperty('text-underline-width', value, '');
  }

  /** Gets the value of "top" */
  String get top() =>
    getPropertyValue('top');

  /** Sets the value of "top" */
  void set top(var value) {
    setProperty('top', value, '');
  }

  /** Gets the value of "transform" */
  String get transform() =>
    getPropertyValue('${_browserPrefix}transform');

  /** Sets the value of "transform" */
  void set transform(var value) {
    setProperty('${_browserPrefix}transform', value, '');
  }

  /** Gets the value of "transform-origin" */
  String get transformOrigin() =>
    getPropertyValue('${_browserPrefix}transform-origin');

  /** Sets the value of "transform-origin" */
  void set transformOrigin(var value) {
    setProperty('${_browserPrefix}transform-origin', value, '');
  }

  /** Gets the value of "transform-origin-x" */
  String get transformOriginX() =>
    getPropertyValue('${_browserPrefix}transform-origin-x');

  /** Sets the value of "transform-origin-x" */
  void set transformOriginX(var value) {
    setProperty('${_browserPrefix}transform-origin-x', value, '');
  }

  /** Gets the value of "transform-origin-y" */
  String get transformOriginY() =>
    getPropertyValue('${_browserPrefix}transform-origin-y');

  /** Sets the value of "transform-origin-y" */
  void set transformOriginY(var value) {
    setProperty('${_browserPrefix}transform-origin-y', value, '');
  }

  /** Gets the value of "transform-origin-z" */
  String get transformOriginZ() =>
    getPropertyValue('${_browserPrefix}transform-origin-z');

  /** Sets the value of "transform-origin-z" */
  void set transformOriginZ(var value) {
    setProperty('${_browserPrefix}transform-origin-z', value, '');
  }

  /** Gets the value of "transform-style" */
  String get transformStyle() =>
    getPropertyValue('${_browserPrefix}transform-style');

  /** Sets the value of "transform-style" */
  void set transformStyle(var value) {
    setProperty('${_browserPrefix}transform-style', value, '');
  }

  /** Gets the value of "transition" */
  String get transition() =>
    getPropertyValue('${_browserPrefix}transition');

  /** Sets the value of "transition" */
  void set transition(var value) {
    setProperty('${_browserPrefix}transition', value, '');
  }

  /** Gets the value of "transition-delay" */
  String get transitionDelay() =>
    getPropertyValue('${_browserPrefix}transition-delay');

  /** Sets the value of "transition-delay" */
  void set transitionDelay(var value) {
    setProperty('${_browserPrefix}transition-delay', value, '');
  }

  /** Gets the value of "transition-duration" */
  String get transitionDuration() =>
    getPropertyValue('${_browserPrefix}transition-duration');

  /** Sets the value of "transition-duration" */
  void set transitionDuration(var value) {
    setProperty('${_browserPrefix}transition-duration', value, '');
  }

  /** Gets the value of "transition-property" */
  String get transitionProperty() =>
    getPropertyValue('${_browserPrefix}transition-property');

  /** Sets the value of "transition-property" */
  void set transitionProperty(var value) {
    setProperty('${_browserPrefix}transition-property', value, '');
  }

  /** Gets the value of "transition-timing-function" */
  String get transitionTimingFunction() =>
    getPropertyValue('${_browserPrefix}transition-timing-function');

  /** Sets the value of "transition-timing-function" */
  void set transitionTimingFunction(var value) {
    setProperty('${_browserPrefix}transition-timing-function', value, '');
  }

  /** Gets the value of "unicode-bidi" */
  String get unicodeBidi() =>
    getPropertyValue('unicode-bidi');

  /** Sets the value of "unicode-bidi" */
  void set unicodeBidi(var value) {
    setProperty('unicode-bidi', value, '');
  }

  /** Gets the value of "unicode-range" */
  String get unicodeRange() =>
    getPropertyValue('unicode-range');

  /** Sets the value of "unicode-range" */
  void set unicodeRange(var value) {
    setProperty('unicode-range', value, '');
  }

  /** Gets the value of "user-drag" */
  String get userDrag() =>
    getPropertyValue('${_browserPrefix}user-drag');

  /** Sets the value of "user-drag" */
  void set userDrag(var value) {
    setProperty('${_browserPrefix}user-drag', value, '');
  }

  /** Gets the value of "user-modify" */
  String get userModify() =>
    getPropertyValue('${_browserPrefix}user-modify');

  /** Sets the value of "user-modify" */
  void set userModify(var value) {
    setProperty('${_browserPrefix}user-modify', value, '');
  }

  /** Gets the value of "user-select" */
  String get userSelect() =>
    getPropertyValue('${_browserPrefix}user-select');

  /** Sets the value of "user-select" */
  void set userSelect(var value) {
    setProperty('${_browserPrefix}user-select', value, '');
  }

  /** Gets the value of "vertical-align" */
  String get verticalAlign() =>
    getPropertyValue('vertical-align');

  /** Sets the value of "vertical-align" */
  void set verticalAlign(var value) {
    setProperty('vertical-align', value, '');
  }

  /** Gets the value of "visibility" */
  String get visibility() =>
    getPropertyValue('visibility');

  /** Sets the value of "visibility" */
  void set visibility(var value) {
    setProperty('visibility', value, '');
  }

  /** Gets the value of "white-space" */
  String get whiteSpace() =>
    getPropertyValue('white-space');

  /** Sets the value of "white-space" */
  void set whiteSpace(var value) {
    setProperty('white-space', value, '');
  }

  /** Gets the value of "widows" */
  String get widows() =>
    getPropertyValue('widows');

  /** Sets the value of "widows" */
  void set widows(var value) {
    setProperty('widows', value, '');
  }

  /** Gets the value of "width" */
  String get width() =>
    getPropertyValue('width');

  /** Sets the value of "width" */
  void set width(var value) {
    setProperty('width', value, '');
  }

  /** Gets the value of "word-break" */
  String get wordBreak() =>
    getPropertyValue('word-break');

  /** Sets the value of "word-break" */
  void set wordBreak(var value) {
    setProperty('word-break', value, '');
  }

  /** Gets the value of "word-spacing" */
  String get wordSpacing() =>
    getPropertyValue('word-spacing');

  /** Sets the value of "word-spacing" */
  void set wordSpacing(var value) {
    setProperty('word-spacing', value, '');
  }

  /** Gets the value of "word-wrap" */
  String get wordWrap() =>
    getPropertyValue('word-wrap');

  /** Sets the value of "word-wrap" */
  void set wordWrap(var value) {
    setProperty('word-wrap', value, '');
  }

  /** Gets the value of "wrap-shape" */
  String get wrapShape() =>
    getPropertyValue('${_browserPrefix}wrap-shape');

  /** Sets the value of "wrap-shape" */
  void set wrapShape(var value) {
    setProperty('${_browserPrefix}wrap-shape', value, '');
  }

  /** Gets the value of "writing-mode" */
  String get writingMode() =>
    getPropertyValue('${_browserPrefix}writing-mode');

  /** Sets the value of "writing-mode" */
  void set writingMode(var value) {
    setProperty('${_browserPrefix}writing-mode', value, '');
  }

  /** Gets the value of "z-index" */
  String get zIndex() =>
    getPropertyValue('z-index');

  /** Sets the value of "z-index" */
  void set zIndex(var value) {
    setProperty('z-index', value, '');
  }

  /** Gets the value of "zoom" */
  String get zoom() =>
    getPropertyValue('zoom');

  /** Sets the value of "zoom" */
  void set zoom(var value) {
    setProperty('zoom', value, '');
  }
}
