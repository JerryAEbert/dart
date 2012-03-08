// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.dart.compiler.resolver.Element;

/**
 * Base class for class members (fields and methods).
 */
public abstract class DartClassMember<N extends DartExpression> extends DartDeclaration<N> {

  private final Modifiers modifiers;

  protected DartClassMember(N name, Modifiers modifiers) {
    super(name);
    this.modifiers = modifiers;
  }

  public Modifiers getModifiers() {
    return modifiers;
  }

  @Override
  public abstract Element getElement();

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
  }
}
