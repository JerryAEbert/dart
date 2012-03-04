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

import com.google.dart.tools.core.DartCore;

import java.io.File;
import java.net.URI;
import java.util.ArrayList;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

/**
 * Provides analysis of Dart code for Dart editor
 */
public class AnalysisServer {

  private static PerformanceListener performanceListener;

  public static PerformanceListener getPerformanceListener() {
    return performanceListener;
  }

  public static void setPerformanceListener(PerformanceListener performanceListener) {
    AnalysisServer.performanceListener = performanceListener;
  }

  private AnalysisListener[] analysisListeners = new AnalysisListener[0];

  /**
   * The target (VM, Dartium, JS) against which user libraries are resolved. Targets are immutable
   * and can be accessed on any thread.
   */
  private final Target target;

  /**
   * The library files being analyzed by the receiver. Lock against {@link #queue} before accessing
   * this object.
   */
  private final ArrayList<File> libraryFiles = new ArrayList<File>();

  /**
   * The outstanding tasks to be performed. Lock against this object before accessing it.
   */
  private final ArrayList<Task> queue = new ArrayList<Task>();

  /**
   * The index at which the task being performed can insert new tasks. Tracking this allows new
   * tasks to take priority and be first in the queue. Lock against {@link #queue} before accessing
   * this field.
   */
  private int queueIndex = 0;

  /**
   * The current task being executed on the background thread. This should only be accessed on the
   * background thread.
   */
  private Task currentTask;

  /**
   * A context representing what is "saved on disk"
   */
  private final Context savedContext = new Context(this);

  /**
   * <code>true</code> if the background thread should continue executing analysis tasks
   */
  private boolean analyze;

  /**
   * Create a new instance that processes analysis tasks on a background thread
   * 
   * @param target The target (VM, Dartium, JS) against which user libraries are resolved
   */
  public AnalysisServer(Target target) {
    this.target = target;
    this.analyze = true;
    new Thread(new Runnable() {

      @Override
      public void run() {
        try {
          while (analyze) {

            // Find the next analysis task
            synchronized (queue) {
              if (queue.isEmpty()) {
                try {
                  queue.wait();
                } catch (InterruptedException e) {
                  //$FALL-THROUGH$
                }
                continue;
              }
              queueIndex = 0;
              currentTask = queue.remove(queueIndex);
            }

            // Perform the task
            try {
              currentTask.perform();
            } catch (Throwable e) {
              DartCore.logError("Analysis Task Exception", e);
            }
            currentTask = null;

          }
        } catch (Throwable e) {
          DartCore.logError("Analysis Server Exception", e);
        }
      }
    }, getClass().getSimpleName()).start();
  }

  public void addAnalysisListener(AnalysisListener listener) {
    for (int i = 0; i < analysisListeners.length; i++) {
      if (analysisListeners[i] == listener) {
        return;
      }
    }
    int oldLen = analysisListeners.length;
    AnalysisListener[] newListeners = new AnalysisListener[oldLen + 1];
    System.arraycopy(analysisListeners, 0, newListeners, 0, oldLen);
    newListeners[oldLen] = listener;
    analysisListeners = newListeners;
  }

  /**
   * Analyze the specified library
   * 
   * @param file the library file (not <code>null</code>)
   */
  public void analyzeLibrary(File file) {
    if (!file.isAbsolute()) {
      throw new IllegalArgumentException("File path must be absolute: " + file);
    }
    synchronized (queue) {
      if (!libraryFiles.contains(file)) {
        libraryFiles.add(file);
        queueNewTask(new AnalyzeLibraryTask(this, savedContext, file));
      }
    }
  }

  /**
   * Stop analyzing the specified library.
   * 
   * @param file the library file (not <code>null</code>)
   */
  public void discardLibrary(File file) {
    synchronized (queue) {
      if (libraryFiles.contains(file)) {
        libraryFiles.remove(file);
        // TODO (danrubel) cleanup cached libraries
      }
    }
  }

  /**
   * Called when a file has been modified
   * 
   * @param file the modified file (not <code>null</code>)
   */
  public void fileChanged(File file) {
    queueNewTask(new FileChangedTask(this, savedContext, file));
  }

  /**
   * Answer <code>true</code> if the receiver is finished analyzing.
   */
  public boolean isIdle() {
    synchronized (queue) {
      return queue.size() == 0 && currentTask == null;
    }
  }

  public void removeAnalysisListener(AnalysisListener listener) {
    int oldLen = analysisListeners.length;
    for (int i = 0; i < oldLen; i++) {
      if (analysisListeners[i] == listener) {
        AnalysisListener[] newListeners = new AnalysisListener[oldLen - 1];
        System.arraycopy(analysisListeners, 0, newListeners, 0, i);
        System.arraycopy(analysisListeners, i + 1, newListeners, i, oldLen - 1 - i);
        return;
      }
    }
  }

  public void stop() {
    final CountDownLatch stopped = new CountDownLatch(1);
    queueNewTask(new Task() {

      @Override
      void perform() {
        analyze = false;
        // TODO (danrubel) write elements to disk
        stopped.countDown();
      }
    });
    try {
      stopped.await(5, TimeUnit.SECONDS);
    } catch (InterruptedException e) {
      //$FALL-THROUGH$
    }
  }

  AnalysisListener[] getAnalysisListeners() {
    return analysisListeners;
  }

  /**
   * Answer the library files identified by {@link #analyzeLibrary(File)}
   * 
   * @return an array of files (not <code>null</code>, contains no <code>null</code>s)
   */
  File[] getSpecifiedLibraryFiles() {
    synchronized (queue) {
      return libraryFiles.toArray(new File[libraryFiles.size()]);
    }
  }

  /**
   * Answer <code>true</code> if the receiver's collection of library files identified by
   * {@link #analyzeLibrary(File)} includes the specified file.
   */
  boolean isSpecifiedLibraryFile(File file) {
    synchronized (queue) {
      return libraryFiles.contains(file);
    }
  }

  /**
   * Ensure that all libraries have been analyzed by adding an instance of
   * {@link AnalyzeContextTask} to the end of the queue if it has not already been added.
   */
  void queueAnalyzeContext() {
    if (analyze) {
      synchronized (queue) {
        int index = queue.size() - 1;
        if (index >= 0) {
          Task lastTask = queue.get(index);
          if (lastTask instanceof AnalyzeContextTask) {
            return;
          }
        }
        queue.add(queueIndex, new AnalyzeContextTask(this, savedContext));
      }
    }
  }

  /**
   * Add a priority task to the front of the queue. Should *not* be called by the
   * {@link #currentTask}... use {@link #queueSubTask(Task)} instead.
   */
  void queueNewTask(Task task) {
    if (analyze) {
      synchronized (queue) {
        queue.add(0, task);
        queueIndex++;
        queue.notifyAll();
      }
    }
  }

  /**
   * Used by the {@link #currentTask} to add subtasks in a way that will not reduce the priority of
   * new tasks that have been queued while the current task is executing
   */
  void queueSubTask(Task subtask) {
    if (analyze) {
      synchronized (queue) {
        queue.add(queueIndex, subtask);
        queueIndex++;
      }
    }
  }

  /**
   * Resolve the specified path to a file.
   * 
   * @return the file or <code>null</code> if it could not be resolved
   */
  File resolveFile(URI base, String relPath) {
    File result = new File(relPath);
    if (!result.isAbsolute()) {
      result = new File(base.resolve(relPath).getPath());
    }
    return result;
  }

  /**
   * Resolve the specified path to a library. This method resolves "dart:<libname>" where as
   * {@link #resolveFile(URI, String)} does not.
   * 
   * @return the library or <code>null</code> if it could not be resolved
   */
  File resolveImport(URI base, String relPath) {
    if (relPath.startsWith("dart:")) {
      return target.resolveImport(relPath);
    }
    return resolveFile(base, relPath);
  }
}
