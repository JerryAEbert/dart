#!/usr/bin/python

# Copyright (c) 2011 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Dart frog buildbot steps

Runs tests for the frog compiler (running on the vm or the self-hosting version)
"""

import os
import re
import shutil
import subprocess
import sys

BUILDER_NAME = 'BUILDBOT_BUILDERNAME'

FROG_PATH = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

FROG_BUILDER = r'(frog|frogsh)-(linux|mac|windows)-(debug|release)'
WEB_BUILDER = r'web-(ie|ff|safari|chrome|opera)-(win7|win8|mac|linux)(-(\d+))?'

NO_COLOR_ENV = dict(os.environ)
NO_COLOR_ENV['TERM'] = 'nocolor'

def GetBuildInfo():
  """Returns a tuple (name, mode, system) where:
    - name: 'frog', 'frogsh', 'frogium', or None when the builder has an
      incorrect name
    - mode: 'debug' or 'release'
    - system: 'linux', 'mac', or 'win7'
    - browser: 'ie', 'ff', 'safari', 'chrome'
  """
  name = None
  mode = None
  system = None
  browser = None
  builder_name = os.environ.get(BUILDER_NAME)
  if builder_name:

    frog_pattern = re.match(FROG_BUILDER, builder_name)
    web_pattern = re.match(WEB_BUILDER, builder_name)

    if frog_pattern:
      name = frog_pattern.group(1)
      system = frog_pattern.group(2)
      mode = frog_pattern.group(3)

    elif web_pattern:
      name = 'frogium'
      mode = 'release'
      browser = web_pattern.group(1)
      system = web_pattern.group(2)

      # TODO(jmesserly): do we want to do anything different for the second IE
      # bot? For now we're using it to track down flakiness.
      number = web_pattern.group(4)

  if system == 'windows':
    system = 'win7'

  return (name, mode, system, browser)


def ComponentsNeedsXterm(component):
  return component in ['frogsh', 'frogium', 'legium', 'webdriver']

def TestStep(name, mode, system, component, targets, flags):
  print '@@@BUILD_STEP %s tests: %s %s@@@' % (name, component, ' '.join(flags))
  sys.stdout.flush()
  if ComponentsNeedsXterm(component) and system == 'linux':
    cmd = ['xvfb-run', '-a']
  else:
    cmd = []

  cmd = (cmd
      + [sys.executable,
          os.path.join('..', 'tools', 'test.py'),
          '--mode=' + mode,
          '--component=' + component,
          '--time',
          '--report',
          '--progress=buildbot',
          '-v']
      + targets)
  if flags:
    cmd.extend(flags)

  exit_code = subprocess.call(cmd, env=NO_COLOR_ENV)
  if exit_code != 0:
    print '@@@STEP_FAILURE@@@'
  return exit_code


def BuildFrog(component, mode, system):
  """ build frog.
   Args:
     - component: either 'leg', 'frog', 'frogsh' (frog self-hosted), 'frogium'
       or 'legium'
     - mode: either 'debug' or 'release'
     - system: either 'linux', 'mac', or 'win7'
  """

  # Make sure we are in the frog directory
  os.chdir(FROG_PATH)

  print '@@@BUILD_STEP build frog@@@'

  args = [sys.executable, '../tools/build.py', '--mode=' + mode]
  return subprocess.call(args, env=NO_COLOR_ENV)


def TestFrog(component, mode, system, browser, flags):
  """ test frog.
   Args:
     - component: either 'leg', 'frog', 'frogsh' (frog self-hosted), 'frogium',
       or 'legium'
     - mode: either 'debug' or 'release'
     - system: either 'linux', 'mac', or 'win7'
     - browser: one of the browsers, see GetBuildInfo
     - flags: extra flags to pass to test.dart
  """

  # Make sure we are in the frog directory
  os.chdir(FROG_PATH)

  if component != 'frogium': # frog and frogsh
    TestStep("frog", mode, system, component, [], flags)
    TestStep("frog_extra", mode, system,
        component, ['frog', 'frog_native', 'peg', 'css'], flags)
    TestStep("sdk", mode, system,
        'vm', ['dartdoc'], flags)

    if not '--checked' in flags:
      TestStep("leg", mode, system, 'leg', [], flags)
      TestStep("leg_extra", mode, system, 'leg',
               ['leg_only', 'frog_native'], flags)
      # Leg isn't self-hosted (yet) so we run the leg unit tests on the VM.
      TestStep("leg_extra", mode, system, 'vm', ['leg'], flags)

  else:
    tests = ['client', 'language', 'corelib', 'isolate', 'frog',
             'frog_native', 'peg', 'css']

    # TODO(jmesserly): make DumpRenderTree more like other browser tests, so
    # we don't have this translation step. See dartbug.com/1158.
    # Ideally we can run most Chrome tests in DumpRenderTree because it's more
    # debuggable, but still have some tests run the full browser.
    # Also: we don't have DumpRenderTree on Windows yet
    # TODO(efortuna): Move Mac back to DumpRenderTree when we have a more stable
    # solution for DRT. Right now DRT is flakier than regular Chrome for the
    # isolate tests, so we're switching to use Chrome in the short term.
    if browser == 'chrome' and system == 'linux':
      TestStep('browser', mode, system, 'frogium', tests, flags)
      TestStep('browser', mode, system, 'legium', tests, flags)
    else:
      additional_flags = ['--browser=' + browser]
      if system.startswith('win') and browser == 'ie':
        # There should not be more than one InternetExplorerDriver instance
        # running at a time. For details, see
        # http://code.google.com/p/selenium/wiki/InternetExplorerDriver.
        additional_flags += ['-j1']
      TestStep(browser, mode, system, 'webdriver', tests,
          flags + additional_flags)

  return 0

def _DeleteFirefoxProfiles(directory):
  """Find all the firefox profiles in a particular directory and delete them."""
  for f in os.listdir(directory):
    item = os.path.join(directory, f)
    if os.path.isdir(item) and f.startswith('tmp'):
      subprocess.Popen('rm -rf %s' % item, shell=True)

def CleanUpTemporaryFiles(system, browser):
  """For some browser (selenium) tests, the browser creates a temporary profile
  on each browser session start. On Windows, generally these files are
  automatically deleted when all python processes complete. However, since our
  buildbot slave script also runs on python, we never get the opportunity to
  clear out the temp files, so we do so explicitly here. Our batch browser
  testing will make this problem occur much less frequently, but will still
  happen eventually unless we do this.

  This problem also occurs with batch tests in Firefox. For some reason selenium
  automatically deletes the temporary profiles for Firefox for one browser,
  but not multiple ones when we have many open batch tasks running. This
  behavior has not been reproduced outside of the buildbots.

  Args:
     - system: either 'linux', 'mac', or 'win7'
     - browser: one of the browsers, see GetBuildInfo
  """
  if system == 'win7':
    shutil.rmtree('C:\\Users\\chrome-bot\\AppData\\Local\\Temp',
        ignore_errors=True)
  elif browser == 'ff':
    # Note: the buildbots run as root, so we can do this without requiring a
    # password. The command won't actually work on regular machines without
    # root permissions.
    _DeleteFirefoxProfiles('/tmp')
    _DeleteFirefoxProfiles('/var/tmp')

def main():
  print 'main'
  if len(sys.argv) == 0:
    print 'Script pathname not known, giving up.'
    return 1

  component, mode, system, browser = GetBuildInfo()
  print "component: %s, mode: %s, system: %s, browser %s" % (component, mode, system,
      browser)
  if component is None:
    return 1

  status = BuildFrog(component, mode, system)
  if status != 0:
    print '@@@STEP_FAILURE@@@'
    return status

  if component != 'frogium' or (system == 'linux' and browser == 'chrome'):
    status = TestFrog(component, mode, system, browser, [])
    if status != 0:
      print '@@@STEP_FAILURE@@@'
      return status

  status = TestFrog(component, mode, system, browser, ['--checked'])
  if status != 0:
    print '@@@STEP_FAILURE@@@'

  if component == 'frogium':
    CleanUpTemporaryFiles(system, browser)
  return status


if __name__ == '__main__':
  sys.exit(main())
