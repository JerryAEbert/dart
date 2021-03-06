// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.dart.compiler.parser.Token;
import com.google.dart.compiler.resolver.Element;
import com.google.dart.compiler.resolver.MethodNodeElement;

/**
 * Represents a Dart binary expression.
 */
public class DartBinaryExpression extends DartExpression {

  private final Token op;
  private DartExpression arg1;
  private DartExpression arg2;
  private MethodNodeElement element;

  public DartBinaryExpression(Token op, DartExpression arg1, DartExpression arg2) {
    assert op.isBinaryOperator() : op;

    this.op = op;
    this.arg1 = becomeParentOf(arg1 != null ? arg1 : new DartSyntheticErrorExpression());
    this.arg2 = becomeParentOf(arg2 != null ? arg2 : new DartSyntheticErrorExpression());
  }

  public DartExpression getArg1() {
    return arg1;
  }

  public DartExpression getArg2() {
    return arg2;
  }

  public Token getOperator() {
    return op;
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
    arg1.accept(visitor);
    arg2.accept(visitor);
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitBinaryExpression(this);
  }

  @Override
  public MethodNodeElement getElement() {
    return element;
  }

  @Override
  public void setElement(Element element) {
    this.element = (MethodNodeElement) element;
  }
}
