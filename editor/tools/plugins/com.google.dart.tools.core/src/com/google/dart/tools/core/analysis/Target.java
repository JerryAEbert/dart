/*
 * Copyright 2012 Dart project authors.
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
package com.google.dart.tools.core.analysis;

import java.io.File;

/**
 * The analysis target... standalone VM, Dartium, JS, ...
 */
public abstract class Target {

  /**
   * Resolve the specified path (e.g. "dart:io") to a file on disk
   * 
   * @return the file or <code>null</code> if unresolved
   */
  public abstract File resolvePath(String relPath);
}
