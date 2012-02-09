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

package com.google.dart.tools.ui.actions;

import com.google.dart.compiler.backend.js.AbstractJsBackend;
import com.google.dart.tools.core.DartCore;
import com.google.dart.tools.core.frog.FrogManager;
import com.google.dart.tools.core.frog.Response;
import com.google.dart.tools.core.frog.ResponseDone;
import com.google.dart.tools.core.frog.ResponseHandler;
import com.google.dart.tools.core.frog.ResponseMessage;
import com.google.dart.tools.core.model.DartElement;
import com.google.dart.tools.core.model.DartLibrary;
import com.google.dart.tools.core.model.DartModelException;
import com.google.dart.tools.ui.DartToolsPlugin;
import com.google.dart.tools.ui.ImportedDartLibraryContainer;

import org.eclipse.core.resources.IResource;
import org.eclipse.core.resources.ResourcesPlugin;
import org.eclipse.core.runtime.IPath;
import org.eclipse.core.runtime.IProgressMonitor;
import org.eclipse.core.runtime.IStatus;
import org.eclipse.core.runtime.Path;
import org.eclipse.core.runtime.Status;
import org.eclipse.core.runtime.jobs.Job;
import org.eclipse.jface.dialogs.MessageDialog;
import org.eclipse.jface.viewers.ISelection;
import org.eclipse.jface.viewers.IStructuredSelection;
import org.eclipse.jface.viewers.StructuredSelection;
import org.eclipse.osgi.util.NLS;
import org.eclipse.swt.SWT;
import org.eclipse.swt.widgets.FileDialog;
import org.eclipse.ui.IEditorPart;
import org.eclipse.ui.IEditorReference;
import org.eclipse.ui.IFileEditorInput;
import org.eclipse.ui.IPartListener;
import org.eclipse.ui.ISelectionListener;
import org.eclipse.ui.IWorkbenchPage;
import org.eclipse.ui.IWorkbenchPart;
import org.eclipse.ui.IWorkbenchWindow;
import org.eclipse.ui.actions.ActionFactory.IWorkbenchAction;

import java.io.File;
import java.util.concurrent.CountDownLatch;

/**
 * An action to create an optimized Javascript build of a Dart library.
 */
public class DeployOptimizedAction extends AbstractInstrumentedAction implements IWorkbenchAction,
    ISelectionListener, IPartListener {

  class CompileResponseHandler extends ResponseHandler {
    private CountDownLatch latch;
    private IStatus exitStatus = Status.OK_STATUS;

    public CompileResponseHandler(CountDownLatch latch) {
      this.latch = latch;
    }

    @Override
    public void handleException(Response response, Exception exception) {
      super.handleException(response, exception);
      DartCore.getConsole().println(
          "Internal compiler error: " + exception + " while processing " + response);
      latch.countDown();
    }

    @Override
    public void processDone(ResponseDone done) {
      if (!done.isSuccess()) {
        exitStatus = new Status(IStatus.ERROR, DartCore.PLUGIN_ID, 0,
            ActionMessages.DeployOptimizedAction_Fail, null);
      }
      latch.countDown();
    }

    @Override
    public void processMessage(ResponseMessage message) {
      String path = null;
      if (message.getLocation() != null) {
        path = message.getLocation().path;
        if (message.getLocation().line != -1) {
          path += ":" + message.getLocation().line;
        }
      }
      DartCore.getConsole().println(
          "[" + message.getSeverity() + "] " + (path == null ? "" : path + ", ")
              + message.getMessage());
    }

    protected IStatus getExitStatus() {
      return exitStatus;
    }
  }

  class DeployOptimizedJob extends Job {
    private File file;
    private DartLibrary library;

    public DeployOptimizedJob(IWorkbenchPage page, File file, DartLibrary library) {
      super(ActionMessages.DeployOptimizedAction_jobTitle);

      this.file = file;
      this.library = library;

      // Synchronize on the workspace root to catch any builds that are in progress.
      setRule(ResourcesPlugin.getWorkspace().getRoot());

      // Make sure we display a progress dialog if we do block.
      setUser(true);
    }

    @Override
    protected IStatus run(IProgressMonitor monitor) {
      IPath path = new Path(file.getAbsolutePath());

      if (DartCore.getPlugin().getCompileWithFrog()) {
        long startTime = System.currentTimeMillis();

        CountDownLatch latch = new CountDownLatch(1);

        CompileResponseHandler responseHandler = new CompileResponseHandler(latch);

        Exception serverException = null;

        try {
          monitor.beginTask(
              ActionMessages.DeployOptimizedAction_Compiling + library.getElementName(),
              IProgressMonitor.UNKNOWN);

          DartCore.getConsole().clear();
          DartCore.getConsole().println(ActionMessages.DeployOptimizedAction_GenerateMessage);

          FrogManager.getServer().compile(library.getCorrespondingResource().getLocation(), path,
              responseHandler);

          latch.await();

          return Status.OK_STATUS;
        } catch (Exception exception) {
          serverException = exception;

          return Status.CANCEL_STATUS;
        } finally {
          long elapsed = System.currentTimeMillis() - startTime;

          // Trim to 1/10th of a second.
          elapsed = (elapsed / 100) * 100;

          if (serverException != null) {
            DartCore.getConsole().println(
                NLS.bind(ActionMessages.DeployOptimizedAction_FailException,
                    serverException.toString()));
          } else if (!responseHandler.getExitStatus().isOK()) {
            DartCore.getConsole().println(ActionMessages.DeployOptimizedAction_Fail);
          } else {
            File outputFile = path.toFile();
            // Trim to 1/10th of a kb.
            double fileLength = ((int) ((outputFile.length() / 1024) * 10)) / 10;

            String message = fileLength + "kb";
            message += " written in " + (elapsed / 1000.0) + "sec";

            DartCore.getConsole().println(
                NLS.bind(ActionMessages.DeployOptimizedAction_DoneSuccess, outputFile.getPath(),
                    message));
          }

          monitor.done();
        }
      }
      return new Status(Status.WARNING, "Deploy optimized", "Dart SDK not installed");
    }
  }

  private IWorkbenchWindow window;

  private Object selectedObject;

  public DeployOptimizedAction(IWorkbenchWindow window) {
    this.window = window;

    setText(ActionMessages.DeployOptimizedAction_title);
    setId(DartToolsPlugin.PLUGIN_ID + ".deployOptimizedAction"); //$NON-NLS-1$
    setDescription(ActionMessages.DeployOptimizedAction_description);
    setToolTipText(ActionMessages.DeployOptimizedAction_tooltip);
    //setImageDescriptor(DartToolsPlugin.getImageDescriptor("icons/full/dart16/library_opt.png"));
    setEnabled(false);

    window.getPartService().addPartListener(this);
    window.getSelectionService().addSelectionListener(this);
  }

  @Override
  public void dispose() {

  }

  @Override
  public void partActivated(IWorkbenchPart part) {
    if (part instanceof IEditorPart) {
      handleEditorActivated((IEditorPart) part);
    }
  }

  @Override
  public void partBroughtToTop(IWorkbenchPart part) {

  }

  @Override
  public void partClosed(IWorkbenchPart part) {

  }

  @Override
  public void partDeactivated(IWorkbenchPart part) {

  }

  @Override
  public void partOpened(IWorkbenchPart part) {

  }

  @Override
  public void run() {
    EmitInstrumentationCommand();
    deployOptimized(window.getActivePage());
  }

  @Override
  public void selectionChanged(IWorkbenchPart part, ISelection selection) {
    if (selection instanceof IStructuredSelection) {
      handleSelectionChanged((IStructuredSelection) selection);
    }
  }

  private void deployOptimized(IWorkbenchPage page) {
    boolean isSaveNeeded = isSaveAllNeeded(page);

    if (isSaveNeeded) {
      if (!saveDirtyEditors(page)) {
        // The user cancelled the launch.
        return;
      }
    }

    final DartLibrary library = getCurrentLibrary();

    if (library == null) {
      MessageDialog.openError(window.getShell(),
          ActionMessages.DeployOptimizedAction_unableToLaunch,
          ActionMessages.DeployOptimizedAction_noneSelected);
    } else {
      try {
        // Get the output location
        FileDialog saveDialog = new FileDialog(window.getShell(), SWT.SAVE);
        IResource libraryResource = library.getCorrespondingResource();
        saveDialog.setFilterPath(libraryResource.getRawLocation().toFile().getParent());
        saveDialog.setFileName(libraryResource.getName() + "." + AbstractJsBackend.EXTENSION_JS); //$NON-NLS-1$

        String fileName = saveDialog.open();

        if (fileName != null) {
          DeployOptimizedJob job = new DeployOptimizedJob(page, new File(fileName), library);
          job.schedule(isSaveNeeded ? 100 : 0);
        }
      } catch (DartModelException exception) {
        DartToolsPlugin.log(exception);

        MessageDialog.openError(window.getShell(),
            ActionMessages.DeployOptimizedAction_unableToLaunch,
            NLS.bind(ActionMessages.DeployOptimizedAction_errorLaunching, exception.getMessage()));
      }
    }
  }

  private DartLibrary getCurrentLibrary() {
    IResource resource = null;
    DartElement element = null;

    if (selectedObject instanceof IResource) {
      resource = (IResource) selectedObject;
    }

    if (resource != null) {
      element = DartCore.create(resource);
    }

    if (selectedObject instanceof DartElement) {
      element = (DartElement) selectedObject;
    }

    if (selectedObject instanceof ImportedDartLibraryContainer) {
      element = ((ImportedDartLibraryContainer) selectedObject).getDartLibrary();
    }

    if (element == null) {
      return null;
    } else {
      // DartElement in a library
      DartLibrary library = element.getAncestor(DartLibrary.class);

      return library;
    }
  }

  private void handleEditorActivated(IEditorPart editorPart) {
    if (editorPart.getEditorInput() instanceof IFileEditorInput) {
      IFileEditorInput input = (IFileEditorInput) editorPart.getEditorInput();

      handleSelectionChanged(new StructuredSelection(input.getFile()));
    }
  }

  private void handleSelectionChanged(IStructuredSelection selection) {
    if (selection != null && !selection.isEmpty()) {
      selectedObject = selection.getFirstElement();

      setEnabled(true);
    } else {
      selectedObject = null;

      setEnabled(false);
    }
  }

  private boolean isSaveAllNeeded(IWorkbenchPage page) {
    IEditorReference[] editors = page.getEditorReferences();
    for (int i = 0; i < editors.length; i++) {
      IEditorReference ed = editors[i];
      if (ed.isDirty()) {
        return true;
      }
    }
    return false;
  }

  private boolean saveDirtyEditors(IWorkbenchPage page) {
    return page.saveAllEditors(false);
  }

}
