/*
 * Copyright (c) 2012, the Dart project authors.
 * 
 * Licensed under the Eclipse Public License v1.0 (the "License"); you may not use this file except
 * in compliance with the License. You may obtain a copy of the License at
 * 
 * http://www.eclipse.org/legal/epl-v10.html
 * 
 * Unless required by applicable law or agreed to in writing, software distributed under the License
 * is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
 * or implied. See the License for the specific language governing permissions and limitations under
 * the License.
 */
package com.google.dart.tools.ui.refactoring;

import com.google.dart.tools.core.internal.model.SourceRangeImpl;
import com.google.dart.tools.core.model.DartVariableDeclaration;
import com.google.dart.tools.internal.corext.refactoring.rename.RenameLocalVariableProcessor;
import com.google.dart.tools.ui.internal.refactoring.RenameSupport;

import org.eclipse.ui.IWorkbenchWindow;
import org.eclipse.ui.PlatformUI;

import static org.fest.assertions.Assertions.assertThat;

import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Method;
import java.lang.reflect.Proxy;

/**
 * Test for {@link RenameLocalVariableProcessor}.
 */
public final class RenameLocalVariableProcessorTest extends RefactoringTest {
  /**
   * Uses {@link RenameSupport} to rename {@link DartVariableDeclaration}.
   */
  private static void renameLocalVariable(DartVariableDeclaration variable, String newName)
      throws Exception {
    RenameSupport renameSupport = RenameSupport.create(variable, newName);
    IWorkbenchWindow workbenchWindow = PlatformUI.getWorkbench().getActiveWorkbenchWindow();
    renameSupport.perform(workbenchWindow.getShell(), workbenchWindow);
  }

  /**
   * Just for coverage of {@link RenameLocalVariableProcessor} accessors.
   */
  public void test_accessors() throws Exception {
    setTestUnitContent(
        "// filler filler filler filler filler filler filler filler filler filler",
        "f() {",
        "  int test = 1;",
        "}");
    DartVariableDeclaration variable = findElement("test = 1;");
    // do check
    RenameLocalVariableProcessor processor = new RenameLocalVariableProcessor(variable);
    assertEquals(RenameLocalVariableProcessor.IDENTIFIER, processor.getIdentifier());
    assertEquals("test", processor.getCurrentElementName());
    // new name
    processor.setNewElementName("newName");
    assertEquals("newName", processor.getNewElementName());
  }

  public void test_badNewName_notIdentifier() throws Exception {
    setTestUnitContent(
        "// filler filler filler filler filler filler filler filler filler filler",
        "f() {",
        "  int test = 1;",
        "  int foo = 2;",
        "  test = 3;",
        "  foo = 4;",
        "}");
    DartVariableDeclaration variable = findElement("test = 1;");
    // try to rename
    String source = testUnit.getSource();
    try {
      renameLocalVariable(variable, "-notIdentifier");
      fail();
    } catch (InterruptedException e) {
    }
    // error should be displayed
    assertThat(openInformationMessages).isEmpty();
    assertThat(showStatusMessages).hasSize(1);
    assertEquals(
        "The variable name '-notIdentifier' is not a valid identifier",
        showStatusMessages.get(0));
    assertThat(showStatusMessages.get(0)).contains(
        "The variable name '-notIdentifier' is not a valid identifier");
    // no source changes
    assertEquals(source, testUnit.getSource());
  }

  public void test_badNewName_shouldBeLowerCase() throws Exception {
    setTestUnitContent(
        "// filler filler filler filler filler filler filler filler filler filler",
        "f() {",
        "  int test = 1;",
        "  int foo = 2;",
        "  test = 3;",
        "  foo = 4;",
        "}");
    DartVariableDeclaration variable = findElement("test = 1;");
    // try to rename
    showStatusCancel = false;
    renameLocalVariable(variable, "NotLowerCase");
    // warning should be displayed
    assertThat(openInformationMessages).isEmpty();
    assertThat(showStatusMessages).hasSize(1);
    assertEquals(
        "By convention, variable names usually start with a lowercase letter",
        showStatusMessages.get(0));
    // status was warning, so rename was done
    assertTestUnitContent(
        "// filler filler filler filler filler filler filler filler filler filler",
        "f() {",
        "  int NotLowerCase = 1;",
        "  int foo = 2;",
        "  NotLowerCase = 3;",
        "  foo = 4;",
        "}");
  }

  public void test_notAvailable_noElement() throws Exception {
    setTestUnitContent(
        "// filler filler filler filler filler filler filler filler filler filler",
        "f() {",
        "  int test = 1;",
        "}");
    final DartVariableDeclaration actualVariable = findElement("test = 1;");
    // emulate that variable does not exist
    DartVariableDeclaration variable = (DartVariableDeclaration) Proxy.newProxyInstance(
        RenameLocalVariableProcessorTest.class.getClassLoader(),
        new Class[] {DartVariableDeclaration.class},
        new InvocationHandler() {
          @Override
          public Object invoke(Object o, Method method, Object[] args) throws Throwable {
            if (method.getName().equals("exists")) {
              return false;
            }
            return method.invoke(actualVariable, args);
          }
        });
    // try to rename
    String source = testUnit.getSource();
    renameLocalVariable(variable, "newName");
    // error should be displayed
    assertThat(openInformationMessages).hasSize(1);
    assertEquals("The refactoring operation is not available", openInformationMessages.get(0));
    // no source changes
    assertEquals(source, testUnit.getSource());
  }

  public void test_OK_local_onDeclaration() throws Exception {
    setTestUnitContent(
        "// filler filler filler filler filler filler filler filler filler filler",
        "f() {",
        "  int test = 1;",
        "  int foo = 2;",
        "  test = 3;",
        "  foo = 4;",
        "}");
    DartVariableDeclaration variable = findElement("test = 1;");
    // do rename
    renameLocalVariable(variable, "newName");
    assertTestUnitContent(
        "// filler filler filler filler filler filler filler filler filler filler",
        "f() {",
        "  int newName = 1;",
        "  int foo = 2;",
        "  newName = 3;",
        "  foo = 4;",
        "}");
  }

  public void test_OK_local_onReference() throws Exception {
    setTestUnitContent(
        "// filler filler filler filler filler filler filler filler filler filler",
        "f() {",
        "  int test = 1;",
        "  int foo = 2;",
        "  test = 3;",
        "  foo = 4;",
        "}");
    DartVariableDeclaration variable = findElement("test = 3;");
    // do rename
    renameLocalVariable(variable, "newName");
    assertTestUnitContent(
        "// filler filler filler filler filler filler filler filler filler filler",
        "f() {",
        "  int newName = 1;",
        "  int foo = 2;",
        "  newName = 3;",
        "  foo = 4;",
        "}");
  }

  public void test_OK_parameter_onDeclaration() throws Exception {
    setTestUnitContent(
        "// filler filler filler filler filler filler filler filler filler filler",
        "f(test) {",
        "  test = 1;",
        "  int foo = 2;",
        "}");
    DartVariableDeclaration variable = findElement("test)");
    // do rename
    renameLocalVariable(variable, "newName");
    assertTestUnitContent(
        "// filler filler filler filler filler filler filler filler filler filler",
        "f(newName) {",
        "  newName = 1;",
        "  int foo = 2;",
        "}");
  }

  public void test_postCondition_localVariable_sameDeclaredAfter() throws Exception {
    setTestUnitContent(
        "// filler filler filler filler filler filler filler filler filler filler",
        "f() {",
        "  int test = 1;",
        "  int newName = 2;",
        "}");
    DartVariableDeclaration variable = findElement("test = 1;");
    // try to rename
    String source = testUnit.getSource();
    try {
      renameLocalVariable(variable, "newName");
      fail();
    } catch (InterruptedException e) {
    }
    // error should be displayed
    assertThat(openInformationMessages).isEmpty();
    assertThat(showStatusMessages).hasSize(1);
    assertEquals("Duplicate local variable 'newName'", showStatusMessages.get(0));
    // no source changes
    assertEquals(source, testUnit.getSource());
  }

  public void test_postCondition_localVariable_sameDeclaredBefore() throws Exception {
    setTestUnitContent(
        "// filler filler filler filler filler filler filler filler filler filler",
        "f() {",
        "  int newName = 2;",
        "  int test = 1;",
        "}");
    DartVariableDeclaration variable = findElement("test = 1;");
    // try to rename
    String source = testUnit.getSource();
    try {
      renameLocalVariable(variable, "newName");
      fail();
    } catch (InterruptedException e) {
    }
    // error should be displayed
    assertThat(openInformationMessages).isEmpty();
    assertThat(showStatusMessages).hasSize(1);
    assertEquals("Duplicate local variable 'newName'", showStatusMessages.get(0));
    // no source changes
    assertEquals(source, testUnit.getSource());
  }

  public void test_postCondition_localVariable_sameNotVisible() throws Exception {
    setTestUnitContent(
        "// filler filler filler filler filler filler filler filler filler filler",
        "f() {",
        "  {",
        "    int newName;",
        "  }",
        "  var test = 1;",
        "}");
    DartVariableDeclaration variable = findElement("test = 1;");
    // do rename
    renameLocalVariable(variable, "newName");
    assertTestUnitContent(
        "// filler filler filler filler filler filler filler filler filler filler",
        "f() {",
        "  {",
        "    int newName;",
        "  }",
        "  var newName = 1;",
        "}");
  }

  public void test_postCondition_superType_field() throws Exception {
    setTestUnitContent(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {",
        "  var newName;",
        "}",
        "class B extends A {",
        "  f() {",
        "    var test = 1;",
        "  }",
        "}",
        "");
    DartVariableDeclaration variable = findElement("test = 1;");
    // try to rename
    String source = testUnit.getSource();
    try {
      renameLocalVariable(variable, "newName");
      fail();
    } catch (InterruptedException e) {
    }
    // error should be displayed
    assertThat(openInformationMessages).isEmpty();
    assertThat(showStatusMessages).hasSize(1);
    assertEquals(
        "Type 'A' in 'Test/Test.dart' declares field 'newName' which will be shadowed by renamed variable",
        showStatusMessages.get(0));
    // no source changes
    assertEquals(source, testUnit.getSource());
  }

  public void test_postCondition_topLevel() throws Exception {
    setTestUnitContent(
        "// filler filler filler filler filler filler filler filler filler filler",
        "var newName;",
        "f() {",
        "  var test = 1;",
        "}",
        "");
    DartVariableDeclaration variable = findElement("test = 1;");
    // try to rename
    String source = testUnit.getSource();
    try {
      renameLocalVariable(variable, "newName");
      fail();
    } catch (InterruptedException e) {
    }
    // error should be displayed
    assertThat(openInformationMessages).isEmpty();
    assertThat(showStatusMessages).hasSize(1);
    assertEquals(
        "File 'Test/Test.dart' in library 'Test' declares top-level variable 'newName' which will be shadowed by renamed variable",
        showStatusMessages.get(0));
    // no source changes
    assertEquals(source, testUnit.getSource());
  }

  /**
   * We artificially return wrong {@link DartVariableDeclaration#getNameRange()} to simulate this.
   */
  public void test_preCondition_canNotFindNode() throws Exception {
    setTestUnitContent(
        "// filler filler filler filler filler filler filler filler filler filler",
        "var newName;",
        "f() {",
        "  var test = 1;",
        "}",
        "");
    final DartVariableDeclaration actualVariable = findElement("test = 1;");
    DartVariableDeclaration variable = (DartVariableDeclaration) Proxy.newProxyInstance(
        RenameLocalVariableProcessorTest.class.getClassLoader(),
        new Class[] {DartVariableDeclaration.class},
        new InvocationHandler() {
          @Override
          public Object invoke(Object o, Method method, Object[] args) throws Throwable {
            if (method.getName().equals("getNameRange")) {
              return new SourceRangeImpl(0, 0);
            }
            return method.invoke(actualVariable, args);
          }
        });
    // try to rename
    String source = testUnit.getSource();
    try {
      renameLocalVariable(variable, "newName");
      fail();
    } catch (InterruptedException e) {
    }
    // error should be displayed
    assertThat(openInformationMessages).isEmpty();
    assertThat(showStatusMessages).hasSize(1);
    assertEquals(
        "A local variable declaration or reference must be selected to activate this refactoring",
        showStatusMessages.get(0));
    // no source changes
    assertEquals(source, testUnit.getSource());
  }

}
