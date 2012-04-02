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

import com.google.dart.compiler.ast.DartUnit;

import static com.google.dart.tools.core.analysis.AnalysisUtility.parse;

import java.io.File;

/**
 * Parse a Dart source file and cache the result
 */
class ParseFileTask extends Task {
  private final AnalysisServer server;
  private final Context context;
  private final File libraryFile;
  private final File dartFile;

  ParseFileTask(AnalysisServer server, Context context, File libraryFile, File dartFile) {
    this.server = server;
    this.context = context;
    this.libraryFile = libraryFile;
    this.dartFile = dartFile;
  }

  @Override
  void perform() {
    if (!dartFile.exists()) {
      return;
    }
    Library library = context.getCachedLibrary(libraryFile);
    if (library == null) {
      return;
    }
    DartUnit dartUnit = library.getCachedUnit(dartFile);
    if (dartUnit != null) {
      return;
    }
    dartUnit = parse(server, library.getFile(), library.getLibrarySource(), dartFile);
    library.cacheUnit(dartFile, dartUnit);
  }
}
