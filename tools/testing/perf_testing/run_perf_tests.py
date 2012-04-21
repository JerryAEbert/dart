#!/usr/bin/python

# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import datetime
import optparse
import os
from os.path import dirname, abspath
import platform
import re
import shutil
import stat
import subprocess
import sys
import time

TOOLS_PATH = os.path.join(dirname(dirname(dirname(abspath(__file__)))))
DART_INSTALL_LOCATION = abspath(os.path.join(dirname(abspath(__file__)),
                                             '..', '..', '..'))
sys.path.append(TOOLS_PATH)
sys.path.append(os.path.join(DART_INSTALL_LOCATION, 'internal', 'tests'))
import post_results
import utils

"""This script runs to track performance and size progress of
different svn revisions. It tests to see if there a newer version of the code on
the server, and will sync and run the performance tests if so."""
class TestRunner(object):

  def __init__(self):
    self.verbose = False
    self.has_shell = False
    if platform.system() == 'Windows':
      # On Windows, shell must be true to get the correct environment variables.
      self.has_shell = True

  def run_cmd(self, cmd_list, outfile=None, append=False, std_in=''):
    """Run the specified command and print out any output to stdout.

    Args:
      cmd_list: a list of strings that make up the command to run
      outfile: a string indicating the name of the file that we should write
         stdout to
      append: True if we want to append to the file instead of overwriting it
      std_in: a string that should be written to the process executing to
         interact with it (if needed)"""
    if self.verbose:
      print ' '.join(cmd_list)
    out = subprocess.PIPE
    if outfile:
      mode = 'w'
      if append:
        mode = 'a'
      out = open(outfile, mode)
      if append:
        # Annoying Windows "feature" -- append doesn't actually append unless
        # you explicitly go to the end of the file.
        # http://mail.python.org/pipermail/python-list/2009-October/1221859.html
        out.seek(0, os.SEEK_END)
    p = subprocess.Popen(cmd_list, stdout = out, stderr=subprocess.PIPE,
                         stdin=subprocess.PIPE, shell=self.has_shell)
    output, stderr = p.communicate(std_in);
    if output:
      print output
    if stderr:
      print stderr
    return output

  def time_cmd(self, cmd):
    """Determine the amount of (real) time it takes to execute a given 
    command."""
    start = time.time()
    self.run_cmd(cmd)
    return time.time() - start

  @staticmethod
  def get_build_targets(suites):
    """Loop through a set of tests that we want to run and find the build
    targets that are necessary.
    
    Args:
      suites: The test suites that we wish to run."""
    build_targets = set()
    for test in suites:
      if test.build_targets is not None:
        for target in test.build_targets:
          build_targets.add(target)
    return build_targets

  def sync_and_build(self, suites):
    """Make sure we have the latest version of of the repo, and build it. We
    begin and end standing in DART_INSTALL_LOCATION.

    Args:
      suites: The set of suites that we wish to build.

    Returns:
      err_code = 1 if there was a problem building."""
    os.chdir(DART_INSTALL_LOCATION)

    self.run_cmd(['gclient', 'sync'])

    # On Windows, the output directory is marked as "Read Only," which causes an
    # error to be thrown when we use shutil.rmtree. This helper function changes
    # the permissions so we can still delete the directory.
    def on_rm_error(func, path, exc_info):
      if os.path.exists(path):
        os.chmod(path, stat.S_IWRITE)
        os.unlink(path)
    # TODO(efortuna): building the sdk locally is a band-aid until all build XXX
    # platform SDKs are hosted in Google storage. Pull from https://sandbox.
    # google.com/storage/?arg=dart-dump-render-tree#dart-dump-render-tree%2Fsdk
    # eventually.
    # TODO(efortuna): Currently always building ia32 architecture because we 
    # don't have test statistics for what's passing on x64. Eliminate arch 
    # specification when we have tests running on x64, too.
    shutil.rmtree(os.path.join(os.getcwd(),
                  utils.GetBuildRoot(utils.GuessOS(), 'release', 'ia32')),
                  onerror=on_rm_error)

    for target in TestRunner.get_build_targets(suites):
      lines = self.run_cmd([os.path.join('.', 'tools', 'build.py'), '-m', 
                            'release', '--arch=ia32', target])

      for line in lines:
        if 'BUILD FAILED' in lines:
          # Someone checked in a broken build! Stop trying to make it work
          # and wait to try again.
          print 'Broken Build'
          return 1
    return 0

  def ensure_output_directory(self, dir_name):
    """Test that the listed directory name exists, and if not, create one for
    our output to be placed.

    Args:
      dir_name: the directory we will create if it does not exist."""
    dir_path = os.path.join(DART_INSTALL_LOCATION, 'tools', 
                            'testing', 'perf_testing', dir_name)
    if not os.path.exists(dir_path):
      os.mkdir(dir_path)
      print 'Creating output directory ', dir_path

  def has_new_code(self):
    """Tests if there are any newer versions of files on the server."""
    os.chdir(DART_INSTALL_LOCATION)
    # Pass 'p' in if we have a new certificate for the svn server, we want to
    # (p)ermanently accept it.
    results = self.run_cmd(['svn', 'st', '-u'], std_in='p')
    for line in results:
      if '*' in line:
        return True
    return False
    
  def get_os_directory(self):
    """Specifies the name of the directory for the testing build of dart, which
    has yet a different naming convention from utils.getBuildRoot(...)."""
    if platform.system() == 'Windows':
      return 'windows'
    elif platform.system() == 'Darwin':
      return 'macos'
    else:
      return 'linux'

  def parse_args(self):
    parser = optparse.OptionParser()
    parser.add_option('--suites', '-s', dest='suites', help='Run the specified '
                      'comma-separated test suites from set: %s' % \
                      ','.join(TestBuilder.available_suite_names()), 
                      action='store', default=None)
    parser.add_option('--forever', '-f', dest='continuous', help='Run this scri'
                      'pt forever, always checking for the next svn checkin',
                      action='store_true', default=False)
    parser.add_option('--nobuild', '-n', dest='no_build', action='store_true',
                      help='Do not sync with the repository and do not '
                      'rebuild.', default=False)
    parser.add_option('--verbose', '-v', dest='verbose', help='Print extra '
                      'debug output', action='store_true', default=False)

    args, ignored = parser.parse_args()

    if not args.suites:
      suites = TestBuilder.available_suite_names()
    else:
      suites = []
      suitelist = args.suites.split(',')
      for name in suitelist:
        if name in TestBuilder.available_suite_names():
          suites.append(name)
        else:
          print ('Error: Invalid suite %s not in ' % name) + \
              '%s' % ','.join(TestBuilder.available_suite_names())
          sys.exit(1)
    self.suite_names = suites
    self.no_build = args.no_build
    self.verbose = args.verbose
    return args.continuous

  def run_test_sequence(self):
    """Run the set of commands to (possibly) build, run, and graph the results
    of our tests.

    Args:
      suite_names: The "display name" the user enters to specify which
          benchmark(s) to run.
      no_build: True if we should not check the repository and build the latest
          version.
    """
    suites = []
    for name in self.suite_names:
      suites += [TestBuilder.make_test(name, self)]

    if not self.no_build and self.sync_and_build(suites) == 1:
      return # The build is broken.

    for test in suites:
      test.run()


class Test(object):
  """The base class to provide shared code for different tests we will run and
  graph. At a high level, each test has three visitors (the tester, the
  file_processor that perform operations on the test object."""

  def __init__(self, result_folder_name, platform_list, variants,
               values_list, test_runner, tester, file_processor,
               build_targets=['create_sdk']):
    """Args:
         result_folder_name: The name of the folder where a tracefile of
             performance results will be stored.
         platform_list: A list containing the platform(s) that our data has been
             run on. (command line, firefox, chrome, etc)
         variants: A list specifying whether we hold data about Frog
             generated code, plain JS code, or a combination of both, or
             Dart depending on the test.
         values_list: A list containing the type of data we will be graphing
             (benchmarks, percentage passing, etc).
         test_runner: Reference to the parent test runner object that notifies a
             test when to run.
         tester: The visitor that actually performs the test running mechanics.
         file_processor: The visitor that processes files in the format
             appropriate for this test.
         build_targets: The targets necessary to build to run these tests
             (default target is create_sdk)."""
    self.result_folder_name = result_folder_name
    # cur_time is used as a timestamp of when this performance test was run.
    self.cur_time = str(time.mktime(datetime.datetime.now().timetuple()))
    self.values_list = values_list
    self.platform_list = platform_list
    self.test_runner = test_runner
    self.tester = tester
    self.file_processor = file_processor
    self.build_targets = build_targets

  def is_valid_combination(self, platform, variant):
    """Check whether data should be captured for this platform/variant
    combination.
    """
    return True

  def run(self):
    """Run the benchmarks/tests from the command line and plot the
    results.
    """
    for visitor in [self.tester, self.file_processor]:
      visitor.prepare()
    
    os.chdir(DART_INSTALL_LOCATION)
    self.test_runner.ensure_output_directory(self.result_folder_name)
    self.tester.run_tests()

    os.chdir(os.path.join('tools', 'testing', 'perf_testing'))

    # TODO(efortuna): Remove trace files once uploaded. This will happen in a
    # future CL.
    files = os.listdir(self.result_folder_name)
    for afile in files:
      if not afile.startswith('.'):
        self.file_processor.process_file(afile)


class Tester(object):
  """The base level visitor class that runs tests. It contains convenience 
  methods that many Tester objects use. Any class that would like to be a
  TesterVisitor must implement the run_tests() method."""

  def __init__(self, test):
    self.test = test

  def prepare(self):
    """Perform any initial setup required before the test is run."""
    pass

  def add_svn_revision_to_trace(self, outfile, browser = None):
    """Add the svn version number to the provided tracefile."""
    def search_for_revision(svn_info_command):
      p = subprocess.Popen(svn_info_command, stdout = subprocess.PIPE,
                           stderr = subprocess.STDOUT, shell =
                           self.test.test_runner.has_shell)
      output, _ = p.communicate()
      for line in output.split('\n'):
        if 'Revision' in line:
          self.test.test_runner.run_cmd(['echo', line.strip()], outfile)
          return True
      return False

    def get_dartium_revision():
      version_file_name = os.path.join(DART_INSTALL_LOCATION, 'client', 'tests',
                                       'dartium', 'LAST_VERSION')
      version_file = open(version_file_name, 'r')
      version = version_file.read().split('.')[-2]
      version_file.close()
      return version

    if browser and browser == 'dartium':
      revision = get_dartium_revision()
      self.test.test_runner.run_cmd(['echo', 'Revision: ' + revision], outfile)
    elif not search_for_revision(['svn', 'info']):
      if not search_for_revision(['git', 'svn', 'info']):
        self.test.test_runner.run_cmd(['echo', 'Revision: unknown'], outfile)


class Processor(object):
  """The base level vistor class that processes tests. It contains convenience 
  methods that many File Processor objects use. Any class that would like to be
  a ProcessorVisitor must implement the process_file() method."""

  def __init__(self, test):
    self.test = test

  def prepare(self):
    """Perform any initial setup required before the test is run."""
    pass

  def report_results(self, benchmark_name, score, platform, variant, 
                     revision_number):
    """Store the results of the benchmark run.
    Args:
      benchmark_name: The name of the individual benchmark.
      score: The numerical value of this benchmark.
      platform: The platform the test was run on (firefox, command line, etc).
      variant: Specifies whether the data was about generated Frog, js, a
          combination of both, or Dart depending on the test.
      revision_number: The revision of the code (and sometimes the revision of
          dartium).
  
    Returns: True if the post was successful."""
    return post_results.report_results(benchmark_name, score, platform, variant,
                                revision_number)


class RuntimePerformanceTest(Test):
  """Super class for all runtime performance testing."""

  def __init__(self, result_folder_name, platform_list, platform_type,
               versions, benchmarks, test_runner, tester, file_processor,
               build_targets=['create_sdk']):
    """Args:
        result_folder_name: The name of the folder where a tracefile of
            performance results will be stored.
        platform_list: A list containing the platform(s) that our data has been
            run on. (command line, firefox, chrome, etc)
        variants: A list specifying whether we hold data about Frog
            generated code, plain JS code, or a combination of both, or
            Dart depending on the test.
        values_list: A list containing the type of data we will be graphing
            (benchmarks, percentage passing, etc).
        test_runner: Reference to the parent test runner object that notifies a
            test when to run.
        tester: The visitor that actually performs the test running mechanics.
        file_processor: The visitor that processes files in the format
            appropriate for this test.
        build_targets: The targets necessary to build to run these tests
            (default target is create_sdk)."""
    super(RuntimePerformanceTest, self).__init__(result_folder_name,
          platform_list, versions, benchmarks, test_runner, tester,
          file_processor, build_targets=build_targets)
    self.platform_list = platform_list
    self.platform_type = platform_type
    self.versions = versions
    self.benchmarks = benchmarks 
 

class BrowserTester(Tester):
  @staticmethod
  def get_browsers():
    browsers = ['dartium', 'ff', 'chrome']
    has_shell = False
    if platform.system() == 'Darwin':
      browsers += ['safari']
    if platform.system() == 'Windows':
      browsers += ['ie']
      has_shell = True
    if 'dartium' in browsers:
      # Fetch it if necessary.
      get_dartium = ['python',
                     os.path.join(DART_INSTALL_LOCATION, 'tools', 'get_drt.py'),
                     '--dartium']
      # TODO(vsm): It's inconvenient that run_cmd isn't in scope here.
      # Perhaps there is a better place to put that or this.
      subprocess.Popen(get_dartium, shell=has_shell)
    return browsers


class CommonBrowserTest(RuntimePerformanceTest):
  """Runs this basic performance tests (Benchpress, some V8 benchmarks) in the
  browser."""

  def __init__(self, test_runner):
    """Args:
      test_runner: Reference to the object that notifies us when to run."""
    super(CommonBrowserTest, self).__init__(
        self.name(), BrowserTester.get_browsers(),
        'browser', ['js', 'frog'],
        self.get_standalone_benchmarks(), test_runner, 
        self.CommonBrowserTester(self),
        self.CommonBrowserFileProcessor(self))
  
  @staticmethod
  def name():
    return 'browser-perf'

  @staticmethod
  def get_standalone_benchmarks():
    return ['Mandelbrot', 'DeltaBlue', 'Richards', 'NBody', 'BinaryTrees',
    'Fannkuch', 'Meteor', 'BubbleSort', 'Fibonacci', 'Loop', 'Permute',
    'Queens', 'QuickSort', 'Recurse', 'Sieve', 'Sum', 'Tak', 'Takl', 'Towers',
    'TreeSort']

  class CommonBrowserTester(BrowserTester):
    def run_tests(self):
      """Run a performance test in the browser."""
      os.chdir('frog')
      self.test.test_runner.run_cmd(['python', os.path.join('benchmarks', 
                                     'make_web_benchmarks.py')])
      os.chdir('..')

      for browser in BrowserTester.get_browsers():
        for version in self.test.versions:
          if not self.test.is_valid_combination(browser, version):
            continue
          self.test.trace_file = os.path.join(
              'tools', 'testing', 'perf_testing', self.test.result_folder_name,
              'perf-%s-%s-%s' % (self.test.cur_time, browser, version))
          self.add_svn_revision_to_trace(self.test.trace_file, browser)
          file_path = os.path.join(
              os.getcwd(), 'internal', 'browserBenchmarks',
              'benchmark_page_%s.html' % version)
          self.test.test_runner.run_cmd(
              ['python', os.path.join('tools', 'testing', 'run_selenium.py'),
              '--out', file_path, '--browser', browser,
              '--timeout', '600', '--mode', 'perf'], self.test.trace_file, 
              append=True)

  class CommonBrowserFileProcessor(Processor):
    def process_file(self, afile):
      """Comb through the html to find the performance results."""
      os.chdir(os.path.join(DART_INSTALL_LOCATION, 'tools',
                            'testing', 'perf_testing'))
      parts = afile.split('-')
      browser = parts[2]
      version = parts[3]
      f = open(os.path.join(self.test.result_folder_name, afile))
      lines = f.readlines()
      line = ''
      i = 0
      revision_num = 0
      while '<div id="results">' not in line and i < len(lines):
        if 'Revision' in line:
          revision_num = int(line.split()[1].strip('"'))
        line = lines[i]
        i += 1

      if i >= len(lines) or revision_num == 0:
        # Then this run did not complete. Ignore this tracefile.
        return

      line = lines[i]
      i += 1
      results = []
      if line.find('<br>') > -1:
        results = line.split('<br>')
      else:
        results = line.split('<br />')
      for result in results:
        name_and_score = result.split(':')
        if len(name_and_score) < 2:
          break
        name = name_and_score[0].strip()
        score = name_and_score[1].strip()
        if version == 'js' or version == 'v8':
          version = 'js'
        self.report_results(name, score, browser, version, revision_num)

      f.close()


class DromaeoTester(Tester):
  DROMAEO_BENCHMARKS = {
      'attr': ('attributes', [
          'getAttribute',
          'element.property',
          'setAttribute',
          'element.property = value']),
      'modify': ('modify', [
          'createElement',
          'createTextNode',
          'innerHTML',
          'cloneNode',
          'appendChild',
          'insertBefore']),
      'query': ('query', [
          'getElementById',
          'getElementById (not in document)',
          'getElementsByTagName(div)',
          'getElementsByTagName(p)',
          'getElementsByTagName(a)',
          'getElementsByTagName(*)',
          'getElementsByTagName (not in document)',
          'getElementsByName',
          'getElementsByName (not in document)']),
      'traverse': ('traverse', [
          'firstChild',
          'lastChild',
          'nextSibling',
          'previousSibling',
          'childNodes'])
  }

  # Use filenames that don't have unusual characters for benchmark names.	
  @staticmethod	
  def legalize_filename(str):	
    remap = {	
        ' ': '_',	
        '(': '_',	
        ')': '_',	
        '*': 'ALL',	
        '=': 'ASSIGN',	
        }	
    for (old, new) in remap.iteritems():	
      str = str.replace(old, new)	
    return str

  # TODO(vsm): This is a hack to skip breaking tests.  Triage this
  # failure properly.  The modify suite fails on 32-bit chrome on
  # the mac.
  @staticmethod
  def get_valid_dromaeo_tags():
    tags = [tag for (tag, _) in DromaeoTester.DROMAEO_BENCHMARKS.values()]
    if platform.system() == 'Darwin':
      tags.remove('modify')
    return tags

  @staticmethod
  def get_dromaeo_benchmarks():
    valid = DromaeoTester.get_valid_dromaeo_tags()
    benchmarks = reduce(lambda l1,l2: l1+l2,
                        [tests for (tag, tests) in
                         DromaeoTester.DROMAEO_BENCHMARKS.values() 
                         if tag in valid])
    return map(DromaeoTester.legalize_filename, benchmarks)

  @staticmethod
  def get_dromaeo_versions():
    return ['js', 'frog_dom', 'frog_html']


class DromaeoTest(RuntimePerformanceTest):
  """Runs Dromaeo tests, in the browser."""
  def __init__(self, test_runner):
    super(DromaeoTest, self).__init__(
        self.name(), BrowserTester.get_browsers(), 'browser',
        DromaeoTester.get_dromaeo_versions(), 
        DromaeoTester.get_dromaeo_benchmarks(), test_runner,
        self.DromaeoPerfTester(self),
        self.DromaeoFileProcessor(self))

  @staticmethod
  def name():
    return 'dromaeo'

  def is_valid_combination(self, browser, version):
    # TODO(vsm): This avoids a bug in 32-bit Chrome (dartium)
    # running JS dromaeo.
    if browser == 'dartium' and version == 'js':
      return False
    return True

  class DromaeoPerfTester(DromaeoTester):
    def run_tests(self):
      """Run dromaeo in the browser."""

      # Build tests.
      dromaeo_path = os.path.join('samples', 'third_party', 'dromaeo')
      current_path = os.getcwd()
      os.chdir(dromaeo_path)
      self.test.test_runner.run_cmd(['python', 'generate_frog_tests.py'])
      os.chdir(current_path)

      versions = DromaeoTester.get_dromaeo_versions()

      for browser in BrowserTester.get_browsers():
        for version_name in versions:
          if not self.test.is_valid_combination(browser, version_name):
            continue
          version = DromaeoTest.DromaeoPerfTester.get_dromaeo_url_query(
              browser, version_name)
          self.test.trace_file = os.path.join(
              'tools', 'testing', 'perf_testing', self.test.result_folder_name,
              'dromaeo-%s-%s-%s' % (self.test.cur_time, browser, version_name))
          self.add_svn_revision_to_trace(self.test.trace_file, browser)
          file_path = '"%s"' % os.path.join(os.getcwd(), dromaeo_path,
              'index-js.html?%s' % version)
          self.test.test_runner.run_cmd(
              ['python', os.path.join('tools', 'testing', 'run_selenium.py'),
               '--out', file_path, '--browser', browser,
               '--timeout', '600', '--mode', 'dromaeo'], self.test.trace_file,
               append=True)

    @staticmethod
    def get_dromaeo_url_query(browser, version):
      if browser == 'dartium':
        version = version.replace('frog', 'dart')
      version = version.replace('_','&')
      tags = DromaeoTester.get_valid_dromaeo_tags()
      return '|'.join([ '%s&%s' % (version, tag) for tag in tags])


  class DromaeoFileProcessor(Processor):
    def process_file(self, afile):
      """Comb through the html to find the performance results."""
      parts = afile.split('-')
      browser = parts[2]
      version = parts[3]

      f = open(os.path.join(self.test.result_folder_name, afile))
      lines = f.readlines()
      i = 0
      revision_num = 0
      revision_pattern = r'Revision: (\d+)'
      suite_pattern = r'<div class="result-item done">(.+?)</ol></div>'
      result_pattern = r'<b>(.+?)</b>(.+?)<small> runs/s(.+)'

      for line in lines:
        rev = re.match(revision_pattern, line.strip())
        if rev:
          revision_num = int(rev.group(1))
          continue

        suite_results = re.findall(suite_pattern, line)
        if suite_results:
          for suite_result in suite_results:
            results = re.findall(r'<li>(.*?)</li>', suite_result)
            if results:
              for result in results:
                r = re.match(result_pattern, result)
                name = DromaeoTester.legalize_filename(r.group(1).strip(':'))
                score = float(r.group(2))
                self.report_results(name, score, browser, version, revision_num)

      f.close()


class DromaeoSizeTest(Test):
  """Run tests to determine the compiled file output size of Dromaeo."""
  def __init__(self, test_runner):
    super(DromaeoSizeTest, self).__init__(
        self.name(),
        ['browser'], ['dart', 'frog_dom', 'frog_html', 'frog_htmlidiomatic'],
        DromaeoTester.DROMAEO_BENCHMARKS.keys(), test_runner, 
        self.DromaeoSizeTester(self),
        self.DromaeoSizeProcessor(self))
  
  @staticmethod
  def name():
    return 'dromaeo-size'


  class DromaeoSizeTester(DromaeoTester):
    def run_tests(self):
      # Build tests.
      dromaeo_path = os.path.join('samples', 'third_party', 'dromaeo')
      current_path = os.getcwd()
      os.chdir(dromaeo_path)
      self.test.test_runner.run_cmd(
          ['python', os.path.join('generate_frog_tests.py')])
      os.chdir(current_path)

      self.test.trace_file = os.path.join(
          'tools', 'testing', 'perf_testing', self.test.result_folder_name,
          self.test.result_folder_name + self.test.cur_time)
      self.add_svn_revision_to_trace(self.test.trace_file)

      variants = [
          ('frog_dom', ''),
          ('frog_html', '-html'),
          ('frog_htmlidiomatic', '-htmlidiomatic')]

      test_path = os.path.join(dromaeo_path, 'tests')
      frog_path = os.path.join(test_path, 'frog')
      total_size = {}
      for (variant, _) in variants:
        total_size[variant] = 0
      total_dart_size = 0
      for suite in DromaeoTester.DROMAEO_BENCHMARKS.keys():
        dart_size = 0
        try:
          dart_size = os.path.getsize(os.path.join(test_path,
                                                   'dom-%s.dart' % suite))
        except OSError:
          pass #If compilation failed, continue on running other tests.

        total_dart_size += dart_size
        self.test.test_runner.run_cmd(
            ['echo', 'Size (dart, %s): %s' % (suite, str(dart_size))],
            self.test.trace_file, append=True)

        for (variant, suffix) in variants:
          name = 'dom-%s%s.dart.js' % (suite, suffix)
          js_size = 0
          try:
            # TODO(vsm): Strip comments at least.  Consider compression.
            js_size = os.path.getsize(os.path.join(frog_path, name))
          except OSError:
            pass #If compilation failed, continue on running other tests.

          total_size[variant] += js_size
          self.test.test_runner.run_cmd(
              ['echo', 'Size (%s, %s): %s' % (variant, suite, str(js_size))],
              self.test.trace_file, append=True)

      self.test.test_runner.run_cmd(
          ['echo', 'Size (dart, %s): %s' % (total_dart_size, 'sum')],
          self.test.trace_file, append=True)
      for (variant, _) in variants:
        self.test.test_runner.run_cmd(
            ['echo', 'Size (%s, %s): %s' % (variant, 'sum',
                                            total_size[variant])],
            self.test.trace_file, append=True)


  class DromaeoSizeProcessor(Processor):
    def process_file(self, afile):
      """Pull all the relevant information out of a given tracefile.

      Args:
        afile: is the filename string we will be processing."""
      os.chdir(os.path.join(DART_INSTALL_LOCATION, 'tools',
          'testing', 'perf_testing'))
      f = open(os.path.join(self.test.result_folder_name, afile))
      tabulate_data = False
      revision_num = 0
      revision_pattern = r'Revision: (\d+)'
      result_pattern = r'Size \((\w+), ([a-zA-Z0-9-]+)\): (\d+)'

      for line in f.readlines():
        rev = re.match(revision_pattern, line.strip())
        if rev:
          revision_num = int(rev.group(1))
          continue

        result = re.match(result_pattern, line.strip())
        if result:
          variant = result.group(1)
          metric = result.group(2)
          num = result.group(3)
          if num.find('.') == -1:
            num = int(num)
          else:
            num = float(num)
          self.report_results(metric, num, 'browser', variant, revision_num)

      f.close()
  

class CompileTimeAndSizeTest(Test):
  """Run tests to determine how long minfrog takes to compile, and the compiled
  file output size of some benchmarking files."""
  def __init__(self, test_runner):
    """Reference to the test_runner object that notifies us when to begin
    testing."""
    super(CompileTimeAndSizeTest, self).__init__(
        self.name(), ['commandline'], ['frog'], 
        ['Compiling on Dart VM', 'Bootstrapping', 'minfrog', 'swarm', 'total'],
        test_runner, self.CompileTester(self),
        self.CompileProcessor(self))
    self.dart_compiler = os.path.join(
        DART_INSTALL_LOCATION, utils.GetBuildRoot(utils.GuessOS(),
        'release', 'ia32'), 'dart-sdk', 'bin', 'frogc')
    _suffix = ''
    if platform.system() == 'Windows':
      _suffix = '.exe'
    self.dart_vm = os.path.join(
        DART_INSTALL_LOCATION, utils.GetBuildRoot(utils.GuessOS(), 
        'release', 'ia32'), 'dart-sdk', 'bin','dart' + _suffix)
    self.failure_threshold = {
        'Compiling on Dart VM' : 1, 'Bootstrapping' : .5, 'minfrog' : 100, 
        'swarm' : 100, 'total' : 100}

  @staticmethod
  def name():
    return 'time-size'

  class CompileTester(Tester):
    def run_tests(self):
      os.chdir('frog')
      self.test.trace_file = os.path.join(
          '..', 'tools', 'testing', 'perf_testing', 
          self.test.result_folder_name,
          self.test.result_folder_name + self.test.cur_time)

      self.add_svn_revision_to_trace(self.test.trace_file)

      elapsed = self.test.test_runner.time_cmd(
          [self.test.dart_vm, os.path.join('.', 'minfrogc.dart'),
          '--out=minfrog', 'minfrog.dart'])
      self.test.test_runner.run_cmd(
          ['echo', '%f Compiling on Dart VM in production mode in seconds'
          % elapsed], self.test.trace_file, append=True)
      elapsed = self.test.test_runner.time_cmd(
          [os.path.join('.', 'minfrog'), '--out=minfrog', 'minfrog.dart', 
          os.path.join('tests', 'hello.dart')])
      if elapsed < self.test.failure_threshold['Bootstrapping']:
        #minfrog didn't compile correctly. Stop testing now, because subsequent
        #numbers will be meaningless.
        return
      size = os.path.getsize('minfrog')
      self.test.test_runner.run_cmd(
          ['echo', '%f Bootstrapping time in seconds in production mode' %
          elapsed], self.test.trace_file, append=True)
      self.test.test_runner.run_cmd(
          ['echo', '%d Generated checked minfrog size' % size],
          self.test.trace_file, append=True)

      self.test.test_runner.run_cmd(
          [self.test.dart_compiler, '--out=swarm-result',
          os.path.join('..', 'samples', 'swarm',
          'swarm.dart')])

      swarm_size = 0
      try:
        swarm_size = os.path.getsize('swarm-result')
      except OSError:
        pass #If compilation failed, continue on running other tests.

      self.test.test_runner.run_cmd(
          [self.test.dart_compiler, '--out=total-result',
          os.path.join('..', 'samples', 'total',
          'client', 'Total.dart')])
      total_size = 0
      try:
        total_size = os.path.getsize('total-result')
      except OSError:
        pass #If compilation failed, continue on running other tests.

      self.test.test_runner.run_cmd(
          ['echo', '%d Generated checked swarm size' % swarm_size],
          self.test.trace_file, append=True)

      self.test.test_runner.run_cmd(
          ['echo', '%d Generated checked total size' % total_size],
          self.test.trace_file, append=True)
    
      #Revert our newly built minfrog to prevent conflicts when we update
      self.test.test_runner.run_cmd(
          ['svn', 'revert',  os.path.join(os.getcwd(), 'minfrog')])
      os.chdir('..')


  class CompileProcessor(Processor):

    def process_file(self, afile):
      """Pull all the relevant information out of a given tracefile.

      Args:
        afile: is the filename string we will be processing."""
      os.chdir(os.path.join(DART_INSTALL_LOCATION, 'tools',
          'testing', 'perf_testing'))
      f = open(os.path.join(self.test.result_folder_name, afile))
      tabulate_data = False
      revision_num = 0
      for line in f.readlines():
        tokens = line.split()
        if 'Revision' in line:
          revision_num = int(line.split()[1])
        else:
          for metric in self.test.values_list:
            if metric in line:
              num = tokens[0]
              if num.find('.') == -1:
                num = int(num)
              else:
                num = float(num)
              self.report_results(metric, num, 'commandline', 'frog', 
                                 revision_num)

      f.close()


class TestBuilder(object):
  """Construct the desired test object."""
  available_suites = dict((suite.name(), suite) for suite in [
      CompileTimeAndSizeTest, CommonBrowserTest, DromaeoTest, DromaeoSizeTest])

  @staticmethod
  def make_test(test_name, test_runner):
    return TestBuilder.available_suites[test_name](test_runner)

  @staticmethod
  def available_suite_names():
    return TestBuilder.available_suites.keys()


def main():
  runner = TestRunner()
  continuous = runner.parse_args()
  if continuous:
    while True:
      if runner.has_new_code():
        runner.run_test_sequence()
      else:
        time.sleep(200)
  else:
    runner.run_test_sequence()

if __name__ == '__main__':
  main()
