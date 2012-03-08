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
package com.google.dart.tools.core.internal.search;

import com.google.dart.tools.core.DartCore;
import com.google.dart.tools.core.index.Element;
import com.google.dart.tools.core.index.Index;
import com.google.dart.tools.core.index.Location;
import com.google.dart.tools.core.index.Relationship;
import com.google.dart.tools.core.index.RelationshipCallback;
import com.google.dart.tools.core.index.Resource;
import com.google.dart.tools.core.internal.index.contributor.IndexConstants;
import com.google.dart.tools.core.internal.index.util.ResourceFactory;
import com.google.dart.tools.core.internal.model.ExternalCompilationUnitImpl;
import com.google.dart.tools.core.internal.model.SourceRangeImpl;
import com.google.dart.tools.core.internal.search.listener.FilteredSearchListener;
import com.google.dart.tools.core.internal.search.listener.GatheringSearchListener;
import com.google.dart.tools.core.internal.search.listener.NameMatchingSearchListener;
import com.google.dart.tools.core.internal.search.listener.WrappedSearchListener;
import com.google.dart.tools.core.internal.util.ResourceUtil;
import com.google.dart.tools.core.model.CompilationUnit;
import com.google.dart.tools.core.model.DartElement;
import com.google.dart.tools.core.model.DartFunction;
import com.google.dart.tools.core.model.DartFunctionTypeAlias;
import com.google.dart.tools.core.model.DartLibrary;
import com.google.dart.tools.core.model.DartModelException;
import com.google.dart.tools.core.model.Field;
import com.google.dart.tools.core.model.Method;
import com.google.dart.tools.core.model.ParentElement;
import com.google.dart.tools.core.model.SourceRange;
import com.google.dart.tools.core.model.Type;
import com.google.dart.tools.core.search.MatchKind;
import com.google.dart.tools.core.search.MatchQuality;
import com.google.dart.tools.core.search.SearchEngine;
import com.google.dart.tools.core.search.SearchException;
import com.google.dart.tools.core.search.SearchFilter;
import com.google.dart.tools.core.search.SearchListener;
import com.google.dart.tools.core.search.SearchMatch;
import com.google.dart.tools.core.search.SearchPattern;
import com.google.dart.tools.core.search.SearchScope;

import org.eclipse.core.resources.IFile;
import org.eclipse.core.resources.IResource;
import org.eclipse.core.runtime.IProgressMonitor;

import java.net.URI;
import java.net.URISyntaxException;
import java.util.ArrayList;
import java.util.List;

/**
 * Instances of the class <code>NewSearchEngineImpl</code> implement a search engine that used the
 * new index to obtain results.
 */
public class NewSearchEngineImpl implements SearchEngine {
  /**
   * Instances of the class <code>ConstructorConverter</code> implement a listener that listens for
   * matches to classes and reports matches to all of the constructors in those classes.
   */
  private static class ConstructorConverter extends WrappedSearchListener {
    public ConstructorConverter(SearchListener listener) {
      super(listener);
    }

    @Override
    public void matchFound(SearchMatch match) {
      DartElement element = match.getElement();
      if (element instanceof Type) {
        Type type = (Type) element;
        try {
          for (Method method : type.getMethods()) {
            if (method.isConstructor()) {
              SearchMatch constructorMatch = new SearchMatch(match.getQuality(), method,
                  method.getNameRange());
              propagateMatch(constructorMatch);
            }
          }
        } catch (DartModelException exception) {
          DartCore.logError(
              "Could not access methods associated with the type " + type.getElementName(),
              exception);
        }
      }
    }
  }

  /**
   * Instances of the class <code>RelationshipCallbackImpl</code> implement a callback that can be
   * used to report results to a search listener.
   */
  private static class RelationshipCallbackImpl implements RelationshipCallback {
    /**
     * The kind of matches that are represented by the results that will be provided to this
     * callback.
     */
    private MatchKind matchKind;

    /**
     * The search listener that should be notified when results are found.
     */
    private SearchListener listener;

    /**
     * Initialize a newly created callback to report matches of the given kind to the given listener
     * when results are found.
     * 
     * @param matchKind the kind of matches that are represented by the results
     * @param listener the search listener that should be notified when results are found
     */
    public RelationshipCallbackImpl(MatchKind matchKind, SearchListener listener) {
      this.matchKind = matchKind;
      this.listener = listener;
    }

    @Override
    public void hasRelationships(Element element, Relationship relationship, Location[] locations) {
      for (Location location : locations) {
        Element targetElement = location.getElement();
        CompilationUnit unit = getCompilationUnit(targetElement.getResource());
        if (unit != null) {
          DartElement dartElement = findElement(unit, targetElement);
          SourceRange range = new SourceRangeImpl(location.getOffset(), location.getLength());
          listener.matchFound(new SearchMatch(MatchQuality.EXACT, matchKind, dartElement, range));
        }
      }
      listener.searchComplete();
    }

    private DartElement findElement(CompilationUnit unit, Element element) {
      String elementId = element.getElementId();
      if (elementId.equals("#library")) {
        return unit.getLibrary();
      }
      IResource resource = unit.getResource();
      if (resource != null && elementId.equals(resource.getLocationURI())) {
        return unit;
      }
      ArrayList<String> elementComponents = getComponents(elementId);
      DartElement dartElement = unit;
      for (String component : elementComponents) {
        dartElement = findElement(dartElement, component);
        if (dartElement == null) {
          return unit;
        }
      }
      return dartElement;
    }

    private DartElement findElement(DartElement parentElement, String component) {
      if (!(parentElement instanceof ParentElement)) {
        DartCore.logError("Cannot find " + component + " as a child of " + parentElement);
        return null;
      }
      try {
        for (DartElement childElement : ((ParentElement) parentElement).getChildren()) {
          if (childElement.getElementName().equals(component)) {
            return childElement;
          }
        }
      } catch (DartModelException exception) {
        DartCore.logError("Cannot find children of " + parentElement);
        return null;
      }
      DartCore.logError("Cannot find " + component + " as a child of " + parentElement);
      return null;
    }

    private CompilationUnit getCompilationUnit(Resource resource) {
      String resourceId = resource.getResourceId();
      ArrayList<String> resourceComponents = getComponents(resourceId);
      if (resourceComponents.size() != 2) {
        DartCore.logError("Invalid resource id found " + resourceId);
        return null;
      }
      String unitUri = resourceComponents.get(1);
      if (unitUri.startsWith("dart:")) {
        String libraryUri = resourceComponents.get(0);
        try {
          ExternalCompilationUnitImpl unit = com.google.dart.tools.core.internal.model.DartModelManager.getInstance().getDartModel().getBundledCompilationUnit(
              new URI(libraryUri));
          if (unit != null) {
            int index = unitUri.lastIndexOf('/');
            return unit.getLibrary().getCompilationUnit(unitUri.substring(index + 1));
          }
        } catch (Exception exception) {
          DartCore.logError("Could not get bundled resource " + resourceId, exception);
        }
        return null;
      }
      IFile[] unitFiles = getFilesForUri(unitUri);
      if (unitFiles == null) {
        return null;
      } else if (unitFiles.length == 0) {
        DartCore.logError("No files linked to URI " + unitUri);
        return null;
      } else if (unitFiles.length == 1) {
        DartElement unitElement = DartCore.create(unitFiles[0]);
        if (unitElement instanceof CompilationUnit) {
          return (CompilationUnit) unitElement;
        } else if (unitElement instanceof DartLibrary) {
          try {
            return ((DartLibrary) unitElement).getDefiningCompilationUnit();
          } catch (DartModelException exception) {
            DartCore.logError("Could not access defining compilation unit for library " + unitUri,
                exception);
          }
        }
        return null;
      }
      String libraryUri = resourceComponents.get(0);
      IFile[] libraryFiles = getFilesForUri(libraryUri);
      if (libraryFiles == null) {
        return null;
      } else if (libraryFiles.length == 0) {
        DartCore.logError("No files linked to URI " + libraryUri);
        return null;
      } else if (libraryFiles.length > 1) {
        DartCore.logError("Multiple files linked to URI's " + libraryUri + " and " + unitUri);
        return null;
      }
      DartElement libraryElement = DartCore.create(libraryFiles[0]);
      DartLibrary library = null;
      if (libraryElement instanceof DartLibrary) {
        library = (DartLibrary) libraryElement;
      } else if (libraryElement instanceof CompilationUnit) {
        library = ((CompilationUnit) libraryElement).getLibrary();
      }
      if (library == null) {
        DartCore.logError("Could not find library for URI " + libraryUri);
        return null;
      }
      try {
        return library.getCompilationUnit(new URI(unitUri));
      } catch (URISyntaxException exception) {
        DartCore.logError("Could not find compilation unit for URI " + unitUri + " in library "
            + libraryUri);
      }
      return null;
    }

    private ArrayList<String> getComponents(String identifier) {
      ArrayList<String> components = new ArrayList<String>();
      boolean previousWasSeparator = false;
      StringBuilder builder = new StringBuilder();
      for (int i = 0; i < identifier.length(); i++) {
        char currentChar = identifier.charAt(i);
        if (previousWasSeparator) {
          if (currentChar == '^') {
            builder.append(currentChar);
          } else {
            components.add(builder.toString());
            builder.setLength(0);
            builder.append(currentChar);
          }
          previousWasSeparator = false;
        } else {
          if (currentChar == '^') {
            previousWasSeparator = true;
          } else {
            builder.append(currentChar);
          }
        }
      }
      components.add(builder.toString());
      return components;
    }

    private IFile[] getFilesForUri(String uri) {
      try {
        ArrayList<IFile> files = new ArrayList<IFile>();
        for (IResource resource : ResourceUtil.getResources(new URI(uri))) {
          if (resource instanceof IFile) {
            files.add((IFile) resource);
          }
        }
        return files.toArray(new IFile[files.size()]);
      } catch (URISyntaxException exception) {
        DartCore.logError("Invalid URI stored in resource id " + uri, exception);
      }
      return null;
    }
  }

  /**
   * The interface <code>SearchRunner</code> defines the behavior of objects that can be used to
   * perform an asynchronous search.
   */
  private interface SearchRunner {
    /**
     * Perform an asynchronous search, passing the results to the given listener.
     * 
     * @param listener the listener to which search results should be passed
     * @throws SearchException if the results could not be computed
     */
    public void performSearch(SearchListener listener) throws SearchException;
  }

  /**
   * The index used to respond to the search requests.
   */
  private Index index;

  /**
   * Initialize a newly created search engine to use the given index.
   * 
   * @param index the index used to respond to the search requests
   */
  public NewSearchEngineImpl(Index index) {
    this.index = index;
  }

  @Override
  public void searchConstructorDeclarations(SearchScope scope, SearchPattern pattern,
      SearchFilter filter, SearchListener listener, IProgressMonitor monitor)
      throws SearchException {
    if (listener == null) {
      throw new IllegalArgumentException("listener cannot be null");
    }
    Element scopeElement = createElement(scope);
    index.getRelationships(
        scopeElement,
        IndexConstants.DEFINES_CLASS,
        new RelationshipCallbackImpl(MatchKind.NOT_A_REFERENCE, applyFilter(filter,
            applyPattern(pattern, new ConstructorConverter(listener)))));
  }

  @Override
  public void searchImplementors(Type type, SearchScope scope, SearchFilter filter,
      SearchListener listener, IProgressMonitor monitor) throws SearchException {
    if (listener == null) {
      throw new IllegalArgumentException("listener cannot be null");
    }
    index.getRelationships(
        createElement(type),
        IndexConstants.IS_IMPLEMENTED_BY,
        new RelationshipCallbackImpl(MatchKind.INTERFACE_IMPLEMENTED, applyFilter(filter, listener)));
  }

  @Override
  public void searchReferences(DartFunction function, SearchScope scope, SearchFilter filter,
      SearchListener listener, IProgressMonitor monitor) throws SearchException {
    if (listener == null) {
      throw new IllegalArgumentException("listener cannot be null");
    }
    index.getRelationships(createElement(function), IndexConstants.IS_REFERENCED_BY,
        new RelationshipCallbackImpl(MatchKind.FUNCTION_EXECUTION, applyFilter(filter, listener)));
  }

  @Override
  public void searchReferences(DartFunctionTypeAlias alias, SearchScope scope, SearchFilter filter,
      SearchListener listener, IProgressMonitor monitor) throws SearchException {
    if (listener == null) {
      throw new IllegalArgumentException("listener cannot be null");
    }
    index.getRelationships(
        createElement(alias),
        IndexConstants.IS_REFERENCED_BY,
        new RelationshipCallbackImpl(MatchKind.FUNCTION_TYPE_REFERENCE, applyFilter(filter,
            listener)));
  }

  @Override
  public void searchReferences(Field field, SearchScope scope, SearchFilter filter,
      SearchListener listener, IProgressMonitor monitor) throws SearchException {
    if (listener == null) {
      throw new IllegalArgumentException("listener cannot be null");
    }
    Element fieldElement = createElement(field);
    index.getRelationships(fieldElement, IndexConstants.IS_ACCESSED_BY,
        new RelationshipCallbackImpl(MatchKind.FIELD_READ, applyFilter(filter, listener)));
    index.getRelationships(fieldElement, IndexConstants.IS_MODIFIED_BY,
        new RelationshipCallbackImpl(MatchKind.FIELD_WRITE, applyFilter(filter, listener)));
  }

  @Override
  public void searchReferences(Method method, SearchScope scope, SearchFilter filter,
      SearchListener listener, IProgressMonitor monitor) throws SearchException {
    if (listener == null) {
      throw new IllegalArgumentException("listener cannot be null");
    }
    index.getRelationships(createElement(method), IndexConstants.IS_REFERENCED_BY,
        new RelationshipCallbackImpl(MatchKind.METHOD_INVOCATION, applyFilter(filter, listener)));
  }

  @Override
  public void searchReferences(Type type, SearchScope scope, SearchFilter filter,
      SearchListener listener, IProgressMonitor monitor) throws SearchException {
    if (listener == null) {
      throw new IllegalArgumentException("listener cannot be null");
    }
    index.getRelationships(createElement(type), IndexConstants.IS_REFERENCED_BY,
        new RelationshipCallbackImpl(MatchKind.TYPE_REFERENCE, applyFilter(filter, listener)));
  }

  @Override
  public List<SearchMatch> searchTypeDeclarations(final SearchScope scope,
      final SearchPattern pattern, final SearchFilter filter, final IProgressMonitor monitor)
      throws SearchException {
    return gatherResults(3, new SearchRunner() {
      @Override
      public void performSearch(SearchListener listener) throws SearchException {
        searchTypeDeclarations(scope, pattern, filter, listener, monitor);
      }
    });
  }

  @Override
  public void searchTypeDeclarations(SearchScope scope, SearchPattern pattern, SearchFilter filter,
      SearchListener listener, IProgressMonitor monitor) throws SearchException {
    if (listener == null) {
      throw new IllegalArgumentException("listener cannot be null");
    }
    Element scopeElement = createElement(scope);
    SearchListener filteredListener = applyFilter(filter, applyPattern(pattern, listener));
    index.getRelationships(scopeElement, IndexConstants.DEFINES_CLASS,
        new RelationshipCallbackImpl(MatchKind.NOT_A_REFERENCE, filteredListener));
    index.getRelationships(scopeElement, IndexConstants.DEFINES_FUNCTION_TYPE,
        new RelationshipCallbackImpl(MatchKind.NOT_A_REFERENCE, filteredListener));
    index.getRelationships(scopeElement, IndexConstants.DEFINES_INTERFACE,
        new RelationshipCallbackImpl(MatchKind.NOT_A_REFERENCE, filteredListener));
  }

  @Override
  public void searchTypeDeclarations(SearchScope scope, SearchPattern pattern,
      SearchListener listener, IProgressMonitor monitor) throws SearchException {
    searchTypeDeclarations(scope, pattern, null, listener, monitor);
  }

  /**
   * Apply the given filter to the given listener.
   * 
   * @param filter the filter to be used before passing matches on to the listener, or
   *          <code>null</code> if all matches should be passed on
   * @param listener the listener that will only be given matches that pass the filter
   * @return a search listener that will pass to the given listener any matches that pass the given
   *         filter
   */
  private SearchListener applyFilter(SearchFilter filter, SearchListener listener) {
    if (filter == null) {
      return listener;
    }
    return new FilteredSearchListener(filter, listener);
  }

  /**
   * Apply the given pattern to the given listener.
   * 
   * @param pattern the pattern to be used before passing matches on to the listener, or
   *          <code>null</code> if all matches should be passed on
   * @param listener the listener that will only be given matches that match the pattern
   * @return a search listener that will pass to the given listener any matches that match the given
   *         pattern
   */
  private SearchListener applyPattern(SearchPattern pattern, SearchListener listener) {
    if (pattern == null) {
      return listener;
    }
    return new NameMatchingSearchListener(pattern, listener);
  }

  private Element createElement(DartFunction function) {
    // TODO Auto-generated method stub
    DartCore.notYetImplemented();
    return null;
  }

  private Element createElement(DartFunctionTypeAlias alias) {
    // TODO Auto-generated method stub
    DartCore.notYetImplemented();
    return null;
  }

  private Element createElement(Field field) throws SearchException {
    Type type = field.getDeclaringType();
    if (type == null) {
      return new Element(getResource(field.getCompilationUnit()), field.getElementName());
    }
    return new Element(getResource(field.getCompilationUnit()), type.getElementName() + "^"
        + field.getElementName());
  }

  private Element createElement(Method method) throws SearchException {
    Type type = method.getDeclaringType();
    if (type == null) {
      return new Element(getResource(method.getCompilationUnit()), method.getElementName());
    }
    return new Element(getResource(method.getCompilationUnit()), type.getElementName() + "^"
        + method.getElementName());
  }

  private Element createElement(SearchScope scope) {
    // TODO(brianwilkerson) Figure out how to handle scope information
    return IndexConstants.UNIVERSE;
  }

  private Element createElement(Type type) throws SearchException {
    return new Element(getResource(type.getCompilationUnit()), type.getElementName());
  }

  /**
   * Use the given runner to perform the given number of asynchronous searches, then wait until the
   * search has completed and return the results that were produced.
   * 
   * @param runner the runner used to perform an asynchronous search
   * @return the results that were produced
   * @throws SearchException if the results of at least one of the searched could not be computed
   */
  private List<SearchMatch> gatherResults(int searchCount, SearchRunner runner)
      throws SearchException {
    GatheringSearchListener listener = new GatheringSearchListener();
    runner.performSearch(listener);
    while (listener.getCompletedCount() < searchCount) {
      Thread.yield();
    }
    return listener.getMatches();
  }

  private Resource getResource(CompilationUnit compilationUnit) throws SearchException {
    try {
      return ResourceFactory.getResource(compilationUnit);
    } catch (DartModelException exception) {
      throw new SearchException(exception);
    }
  }
}
