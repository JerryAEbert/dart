/*
 * Copyright 2012 Dart project authors.
 * 
 * Licensed under the Eclipse Public License v1.0 (the "License"); you may not use this libraryFile
 * except in compliance with the License. You may obtain a copy of the License at
 * 
 * http://www.eclipse.org/legal/epl-v10.html
 * 
 * Unless required by applicable law or agreed to in writing, software distributed under the License
 * is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
 * or implied. See the License for the specific language governing permissions and limitations under
 * the License.
 */
package com.google.dart.tools.core.analysis;

import com.google.dart.compiler.LibrarySource;
import com.google.dart.compiler.ast.DartDirective;
import com.google.dart.compiler.ast.DartImportDirective;
import com.google.dart.compiler.ast.DartSourceDirective;
import com.google.dart.compiler.ast.DartUnit;
import com.google.dart.compiler.ast.LibraryUnit;

import static com.google.dart.tools.core.analysis.AnalysisUtility.toFile;

import java.io.File;
import java.net.URI;
import java.util.Collection;
import java.util.HashMap;

/**
 * Cached information about a Dart library used internally by the {@link AnalysisServer}.
 */
class Library {

  /**
   * Construct a new library from the unresolved dart unit that defines the library
   */
  static Library fromDartUnit(AnalysisServer server, File libFile, LibrarySource libSource,
      DartUnit dartUnit) {
    HashMap<String, File> imports = new HashMap<String, File>();
    HashMap<String, File> sources = new HashMap<String, File>();
    URI base = libFile.toURI();

    // Resolve all #import and #source directives

    for (DartDirective directive : dartUnit.getDirectives()) {
      String relPath;
      if (directive instanceof DartImportDirective) {
        relPath = ((DartImportDirective) directive).getLibraryUri().getValue();
        File file = server.resolvePath(base, relPath);
        if (file == null) {
          // Resolution errors reported by ResolveLibraryTask
        } else {
          imports.put(relPath, file);
        }
      } else if (directive instanceof DartSourceDirective) {
        relPath = ((DartSourceDirective) directive).getSourceUri().getValue();
        File file = server.resolvePath(base, relPath);
        if (file == null) {
          // Resolution errors reported by ResolveLibraryTask
        } else {
          sources.put(relPath, file);
        }
      }
    }

    // Import "dart:core" if it was not explicitly imported

    if (imports.get("dart:core") == null) {
      File file = server.resolvePath(base, "dart:core");
      if (file == null) {
        // Resolution errors reported by ResolveLibraryTask
      } else {
        imports.put("dart:core", file);
      }
    }

    Library library = new Library(libFile, libSource, dartUnit, imports, sources);
    return library;
  }

  private final File libraryFile;
  private final LibrarySource librarySource;
  private final HashMap<String, File> imports;
  private final HashMap<String, File> sources;
  private final HashMap<File, DartUnit> unitCache;

  private LibraryUnit libraryUnit;

  private Library(File libraryFile, LibrarySource librarySource, DartUnit libraryUnit,
      HashMap<String, File> imports, HashMap<String, File> sources) {
    this.libraryFile = libraryFile;
    this.librarySource = librarySource;
    this.imports = imports;
    this.sources = sources;
    this.unitCache = new HashMap<File, DartUnit>();
    this.unitCache.put(libraryFile, libraryUnit);
  }

  void cacheLibraryUnit(AnalysisServer server, LibraryUnit libUnit) {
    this.libraryUnit = libUnit;
    for (DartUnit dartUnit : libUnit.getUnits()) {
      File file = toFile(server, dartUnit.getSource().getUri());
      if (file != null) {
        cacheUnit(file, dartUnit);
      }
    }
  }

  void cacheUnit(File file, DartUnit unit) {
    unitCache.put(file, unit);
  }

  DartUnit getCachedUnit(File file) {
    return unitCache.get(file);
  }

  HashMap<File, DartUnit> getCachedUnits() {
    return unitCache;
  }

  File getFile() {
    return libraryFile;
  }

  Collection<File> getImportedFiles() {
    return imports.values();
  }

  LibrarySource getLibrarySource() {
    return librarySource;
  }

  LibraryUnit getLibraryUnit() {
    return libraryUnit;
  }

  Collection<File> getSourceFiles() {
    return sources.values();
  }
}
