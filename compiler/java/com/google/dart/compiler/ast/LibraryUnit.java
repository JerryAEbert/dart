// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.common.io.CharStreams;
import com.google.dart.compiler.DartCompiler;
import com.google.dart.compiler.DartCompilerContext;
import com.google.dart.compiler.DartCompilerListener;
import com.google.dart.compiler.DartSource;
import com.google.dart.compiler.LibraryDeps;
import com.google.dart.compiler.LibrarySource;
import com.google.dart.compiler.common.SourceInfo;
import com.google.dart.compiler.metrics.DartEventType;
import com.google.dart.compiler.metrics.Tracer;
import com.google.dart.compiler.metrics.Tracer.TraceEvent;
import com.google.dart.compiler.parser.DartParser;
import com.google.dart.compiler.parser.DartScannerParserContext;
import com.google.dart.compiler.resolver.Elements;
import com.google.dart.compiler.resolver.LibraryElement;

import java.io.IOException;
import java.io.Reader;
import java.io.Writer;
import java.net.URI;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Set;
import java.util.concurrent.ConcurrentSkipListMap;

/**
 * Represents the parsed source from a {@link LibrarySource}.
 */
public class LibraryUnit {

  // This is intentionally unparseable as Dart.
  private static final String UNIT_SEPARATOR_NAME = "--- unit-name: ";
  private static final String UNIT_SEPARATOR_URI = "--- unit-uri: ";

  private final LibrarySource libSource;
  private final LibraryNode selfSourcePath;
  private final Collection<LibraryNode> importPaths = new ArrayList<LibraryNode>();
  private final Collection<LibraryNode> sourcePaths = new ArrayList<LibraryNode>();
  private final Collection<LibraryNode> resourcePaths = new ArrayList<LibraryNode>();
  private final Collection<LibraryNode> nativePaths = new ArrayList<LibraryNode>();

  private final Map<String, DartUnit> units = new ConcurrentSkipListMap<String, DartUnit>();
  private final Collection<LibraryUnit> imports = new ArrayList<LibraryUnit>();
  private final Map<LibraryUnit, String> prefixes = new HashMap<LibraryUnit, String>();

  private final LibraryElement element;

  private Map<String, DartNode> topLevelNodes;
  private LibraryDeps deps;

  private LibraryNode entryNode;
  private DartUnit selfDartUnit;

  private String name;

  private DartExpression entryPoint;

  private int sourceCount;

  public void setName(String name) {
    this.name = name;
  }

  public String getName() {
    return name;
  }

  public LibraryUnit(LibrarySource libSource) {
    assert libSource != null;
    this.libSource = libSource;
    element = Elements.libraryElement(this);

    // get the name part of the path, since it needs to be relative
    // TODO(jbrosenberg): change this to use lazy init
    // Note: We don't want an encoded relative path.
    String self = libSource.getUri().getSchemeSpecificPart();
    int lastSlash;
    if ((lastSlash = self.lastIndexOf('/')) > -1) {
      self = self.substring(lastSlash + 1);
    }
    selfSourcePath = new LibraryNode(self); 
  }

  public void addImportPath(LibraryNode path) {
    assert path != null;
    importPaths.add(path);
  }

  public void addSourcePath(LibraryNode path) {
    assert path != null;
    sourcePaths.add(path);
    sourceCount++;
  }

  public void addResourcePath(LibraryNode path) {
    assert path != null;
    resourcePaths.add(path);
  }

  public int getSourceCount() {
    return sourceCount;
  }

  public void addNativePath(LibraryNode path) {
    assert path != null;
    nativePaths.add(path);
  }

  public void putUnit(DartUnit unit) {
    unit.setLibrary(this);
    units.put(unit.getSourceName(), unit);
  }

  public DartUnit getUnit(String sourceName) {
    return units.get(sourceName);
  }

  public void addImport(LibraryUnit unit, LibraryNode node) {
    imports.add(unit);
    if (node != null && node.getPrefix() != null) {
      prefixes.put(unit, node.getPrefix());
    }
  }

  public String getPrefixOf(LibraryUnit library) {
    return prefixes.get(library);
  }

  public LibraryElement getElement() {
    return element;
  }

  public Iterable<DartUnit> getUnits() {
    return units.values();
  }

  public Iterable<LibraryUnit> getImports() {
    return imports;
  }

  public boolean hasImport(LibraryUnit unit) {
    return imports.contains(unit);
  }

  public DartExpression getEntryPoint() {
    return entryPoint;
  }

  public void setEntryPoint(DartExpression entry) {
    this.entryPoint = entry;
  }

  public DartUnit getSelfDartUnit() {
    return this.selfDartUnit;
  }

  public void setSelfDartUnit(DartUnit unit) {
    this.selfDartUnit = unit;
  }

  /**
   * Return a collection of paths to {@link LibrarySource}s upon which this
   * library or application depends.
   *
   * @return the paths (not <code>null</code>, contains no <code>null</code>)
   */
  public Iterable<LibraryNode> getImportPaths() {
    return importPaths;
  }

  /**
   * Return all prefixes used by this library.
   */
  public Set<String> getPrefixes() {
    return new HashSet<String>(prefixes.values());
  }

  /**
   * Return the path for dart source that corresponds to the same dart file as
   * this library unit. This is added to the set of sourcePaths for this unit.
   * 
   * @return the self source path for this unit.
   */
  public LibraryNode getSelfSourcePath() {
    return selfSourcePath;
  }

  /**
   * Answer the source associated with this unit
   *
   * @return the library source (not <code>null</code>)
   */
  public LibrarySource getSource() {
    return libSource;
  }

  /**
   * Return a collection of paths to {@link DartSource}s that are included in
   * this library or application.
   *
   * @return the paths (not <code>null</code>, contains no <code>null</code>)
   */
  public Iterable<LibraryNode> getSourcePaths() {
    return sourcePaths;
  }

  /**
   * Return a collection of paths to resources that are included in
   * this library or application.
   *
   * @return the paths (not <code>null</code>, contains no <code>null</code>)
   */
  public Iterable<LibraryNode> getResourcePaths() {
    return resourcePaths;
  }

  /**
   * Returns a collection of paths to native {@link DartSource}s that are included in this library.
   *
   * @return the paths (not <code>null</code>, contains no <code>null</code>)
   */
  public Iterable<LibraryNode> getNativePaths() {
    return nativePaths;
  }

  /**
   * Loads this library's associated api. If the api file exists, this will result in the library
   * being populated with "diet" units (i.e., {@link DartUnit#isDiet()} will return
   * <code>true</code>).
   *
   * @return <code>true</code> if the library was loaded from its api
   */
  public boolean loadApi(DartCompilerContext context, DartCompilerListener listener)
      throws IOException {
    TraceEvent parseEvent =
        Tracer.canTrace() ? Tracer.start(DartEventType.PARSE_API, "src", getSource().getUri()
            .toString()) : null;
    try {
      final Reader r = context.getArtifactReader(libSource, "", DartCompiler.EXTENSION_API);
      if (r == null) {
        return false;
      }

      // Read the API file.
      String srcCode = CharStreams.toString(r);
      r.close();

      // Split it up by unit.
      int idx = srcCode.indexOf(UNIT_SEPARATOR_NAME);
      while (idx != -1) {
        int endIdx;

        // Prepare unit name.
        idx += UNIT_SEPARATOR_NAME.length();
        endIdx = srcCode.indexOf('\n', idx);
        String unitName = srcCode.substring(idx, endIdx);
        idx = endIdx;

        // Prepare unit URI.
        idx = srcCode.indexOf(UNIT_SEPARATOR_URI, endIdx);
        idx += UNIT_SEPARATOR_URI.length();
        endIdx = srcCode.indexOf('\n', idx);
        String unitUri = srcCode.substring(idx, endIdx);
        idx = endIdx;

        // Find next unit, may be end string.
        endIdx = srcCode.indexOf(UNIT_SEPARATOR_NAME, idx);

        // Parse diet source unit.
        String code = endIdx != -1 ? srcCode.substring(idx, endIdx) : srcCode.substring(idx);
        parseApiUnit(unitName, unitUri, code, libSource, listener);

        // Process next unit.
        idx = endIdx;
      }

      return true;
    } finally {
      Tracer.end(parseEvent);
    }
  }

  /**
   * Saves this library's contents to its associated api file.
   */
  public void saveApi(DartCompilerContext context) throws IOException {
    Writer w = context.getArtifactWriter(libSource, "", DartCompiler.EXTENSION_API);
    for (Entry<String, DartUnit> entry : units.entrySet()) {
      String unitName = entry.getKey();
      DartUnit unit = entry.getValue();
      w.write(UNIT_SEPARATOR_NAME + unitName + "\n");
      w.write(UNIT_SEPARATOR_URI + unit.getSource().getUri() + "\n");
      w.write(unit.toDietSource());
    }
    w.close();
  }

  /**
   * Populates this unit's class map. This can be called only once per unit, and must be called
   * before {@link #getTopLevelNode(String)} and {@link #getTopLevelNodes()}.
   */
  public void populateTopLevelNodes() {
    assert topLevelNodes == null;
    topLevelNodes = new HashMap<String, DartNode>();

    DartNodeTraverser<Void> visitor = new DartNodeTraverser<Void>() {
      @Override
      public Void visitClass(DartClass node) {
        topLevelNodes.put(node.getClassName(), node);
        return null;
      }

      @Override
      public Void visitMethodDefinition(DartMethodDefinition node) {
        // Method names are always identifiers, except for factories, which cannot appear
        // in this context.
        DartExpression name = node.getName();
        if(name instanceof DartIdentifier) {
          topLevelNodes.put(((DartIdentifier) name).getTargetName(), node);
        } else {
          // Visit the unknown node to generate a string for our use.
          topLevelNodes.put(node.getName().toSource(), node);
        }
        return null;
      }

      @Override
      public Void visitField(DartField node) {
        topLevelNodes.put(node.getName().getTargetName(), node);
        return null;
      }
    };

    for (DartUnit unit : units.values()) {
      visitor.visitUnit(unit);
    }
  }

  /**
   * Get an unmodifiable collection of the classes in this library. You must call
   * {@link #populateTopLevelNodes()} before this method will work.
   */
  public Collection<DartNode> getTopLevelNodes() {
    return Collections.unmodifiableCollection(topLevelNodes.values());
  }

  /**
   * Gets the {@link DartClass} associated with the given name. You must call
   * {@link #populateTopLevelNodes()} before this method will work.
   */
  public DartNode getTopLevelNode(String name) {
    assert topLevelNodes != null;
    return topLevelNodes.get(name);
  }

  /**
   * Return the declared entry method, if any
   *
   * @return the entry method or <code>null</code> if not defined
   */
  public LibraryNode getEntryNode() {
    return entryNode;
  }

  /**
   * Set the declared entry method.
   *
   * @param libraryNode the entry method or <code>null</code> if none
   */
  public void setEntryNode(LibraryNode libraryNode) {
    this.entryNode = libraryNode;
  }

  /**
   * Gets the dependencies associated with this library. If no dependencies artifact exists,
   * or the file is invalid, it will return an empty deps object.
   */
  public LibraryDeps getDeps(DartCompilerContext context) throws IOException {
    if (deps != null) {
      return deps;
    }

    Reader reader = context.getArtifactReader(libSource, "", DartCompiler.EXTENSION_DEPS);
    if (reader != null) {
      deps = LibraryDeps.fromReader(reader);
      reader.close();
    }

    if (deps == null) {
      deps = new LibraryDeps();
    }
    return deps;
  }

  /**
   * Writes this library's associated dependencies.
   */
  public void writeDeps(DartCompilerContext context) throws IOException {
    Writer writer = context.getArtifactWriter(libSource, "", DartCompiler.EXTENSION_DEPS);
    deps.write(writer);
    writer.close();
  }

  private void parseApiUnit(final String unitName,
      final String unitUri,
      String srcCode,
      final LibrarySource libSrc,
      DartCompilerListener listener) {
    // Dummy source for the api unit.
    DartSource src = new DartSource() {
      @Override
      public LibrarySource getLibrary() {
        return libSrc;
      }

      @Override
      public String getName() {
        return unitName;
      }

      @Override
      public Reader getSourceReader() {
        return null;
      }

      @Override
      public URI getUri() {
        return URI.create(unitUri);
      }

      @Override
      public boolean exists() {
        return true;
      }

      @Override
      public long getLastModified() {
        return 0;
      }

      @Override
      public String getRelativePath() {
        return unitName;
      }
    };

    DartScannerParserContext parserContext = new DartScannerParserContext(src, srcCode, listener);
    DartParser parser = new DartParser(parserContext, true);
    DartUnit unit = parser.parseUnit(src);

    // When parsing from an API file, generate and store the hash for top level
    // classes while we have the string available.  Reduces the time needed to
    // recompute this later with a visitor.
    for (DartNode node : unit.getTopLevelNodes()) {
      if (node instanceof DartClass) {
        SourceInfo nodeInfo = node.getSourceInfo();
        String nodeString = srcCode.substring(nodeInfo.getSourceStart(),
                                              nodeInfo.getSourceStart()+nodeInfo.getSourceLength());
        ((DartClass)node).setHash(nodeString.hashCode());
      }
    }
    putUnit(unit);
  }
}
