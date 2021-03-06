// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

/**
 * Represents a Dart 'while' statement.
 */
public class DartWhileStatement extends DartStatement {

  private DartExpression condition;
  private DartStatement body;

  public DartWhileStatement(DartExpression condition, DartStatement body) {
    this.condition = becomeParentOf(condition);
    this.body = becomeParentOf(body);
  }

  public DartStatement getBody() {
    return body;
  }

  public DartExpression getCondition() {
    return condition;
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
    condition.accept(visitor);
    body.accept(visitor);
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitWhileStatement(this);
  }
}
