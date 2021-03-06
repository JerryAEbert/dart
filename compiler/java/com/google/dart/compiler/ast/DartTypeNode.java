// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.dart.compiler.type.Type;

import java.util.List;

/**
 * Representation of a Dart type name.
 */
public class DartTypeNode extends DartNode {

  private DartNode identifier;
  private NodeList<DartTypeNode> typeArguments = NodeList.create(this);
  private Type type;

  public DartTypeNode(DartNode identifier) {
    this(identifier, null);
  }

  public DartTypeNode(DartNode identifier, List<DartTypeNode> typeArguments) {
    this.identifier = becomeParentOf(identifier);
    this.typeArguments.addAll(typeArguments);
  }

  public DartNode getIdentifier() {
    return identifier;
  }

  public List<DartTypeNode> getTypeArguments() {
    return typeArguments;
  }

  @Override
  public void setType(Type type) {
    this.type = type;
  }

  @Override
  public Type getType() {
    return type;
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
    identifier.accept(visitor);
    typeArguments.accept(visitor);
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitTypeNode(this);
  }
}
