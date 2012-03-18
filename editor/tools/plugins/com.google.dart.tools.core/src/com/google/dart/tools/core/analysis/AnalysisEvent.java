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

import com.google.dart.compiler.DartCompilationError;
import com.google.dart.compiler.ast.DartUnit;

import static com.google.dart.tools.core.analysis.AnalysisUtility.toFile;

import java.io.File;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.HashSet;

/**
 * Collected analysis information.
 * 
 * @see AnalysisListener#parsed(AnalysisEvent)
 */
public class AnalysisEvent {

  private final File libraryFile;
  private final Collection<File> files;
  private final HashMap<File, DartUnit> units;
  private final ArrayList<DartCompilationError> errors;

  public AnalysisEvent(File libraryFile) {
    this(libraryFile, new ArrayList<DartCompilationError>());
  }

  public AnalysisEvent(File libraryFile, ArrayList<DartCompilationError> errors) {
    this.libraryFile = libraryFile;
    this.files = new ArrayList<File>();
    this.units = new HashMap<File, DartUnit>();
    this.errors = errors;
  }

  /**
   * Answer the errors for the analyzed files
   * 
   * @return a collection of errors (not <code>null</code>, contains no <code>null</code>s)
   */
  public ArrayList<DartCompilationError> getErrors() {
    return errors;
  }

  /**
   * Answer the files that were analyzed.
   * 
   * @return a collection of files (not <code>null</code>, contains no <code>null</code>s)
   */
  public Collection<File> getFiles() {
    return files;
  }

  /**
   * Answer the file defining the library that contains the files being analyzed.
   * 
   * @return the file (not <code>null</code>)
   */
  public File getLibraryFile() {
    return libraryFile;
  }

  /**
   * Answer the {@link DartUnit}s for the analyzed files
   */
  public HashMap<File, DartUnit> getUnits() {
    return units;
  }

  /**
   * Add errors reported on the analyzed files, discarding all other errors
   */
  void addErrors(AnalysisServer server, Collection<DartCompilationError> newErrors) {
    if (newErrors.size() == 0) {
      return;
    }
    HashSet<File> fileSet = new HashSet<File>(files);
    for (DartCompilationError error : newErrors) {
      File file = toFile(server, error.getSource().getUri());
      if (fileSet.contains(file)) {
        errors.add(error);
      }
    }
  }

  void addFileAndDartUnit(File file, DartUnit unit) {
    files.add(file);
    units.put(file, unit);
  }
}
