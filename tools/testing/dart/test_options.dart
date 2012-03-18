// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("test_options_parser");

#import("dart:io");
#import("dart:builtin");
#import("drt_updater.dart");

List<String> defaultTestSelectors =
    const ['dartc', 'samples', 'standalone', 'corelib', 'co19', 'language',
           'isolate', 'vm', 'client', 'dartdoc', 'utils'];

/**
 * Specification of a single test option.
 *
 * The name of the specification is used as the key for the option in
 * the Map returned from the [TestOptionParser] parse method.
 */
class _TestOptionSpecification {
  _TestOptionSpecification(this.name,
                           this.description,
                           this.keys,
                           this.values,
                           this.defaultValue,
                           [type = 'string']) : this.type = type;
  String name;
  String description;
  List<String> keys;
  List<String> values;
  var defaultValue;
  String type;
}


/**
 * Parser of test options.
 */
class TestOptionsParser {
  String specialCommandHelp =
"""
Special command support. Wraps the command line in
a special command. The special command should contain
an '@' character which will be replaced by the normal
command.

For example if the normal command that will be executed
is 'dart file.dart' and you specify special command
'python -u valgrind.py @ suffix' the final command will be
'python -u valgrind.py dart file.dart suffix'""";

  /**
   * Creates a test options parser initialized with the known options.
   */
  TestOptionsParser() {
    _options =
        [ new _TestOptionSpecification(
              'mode',
              'Mode in which to run the tests',
              ['-m', '--mode'],
              ['all', 'debug', 'release'],
              'debug'),
          new _TestOptionSpecification(
              'component',
              '''
Controls how dart code is compiled and executed.

   vm: Run dart code on the standalone dart vm.

   frog: Compile dart code by running frog on the standalone dart vm, and
       run the resulting javascript on D8.

   leg: Compile dart code by running leg on the standalone dart vm, and
       run the resulting javascript on D8.

   frogsh: Compile dart code by running frog on node.js, and run the
       resulting javascript on the same instance of node.js.

   dartium: Run dart code in a type="application/dart" script tag in a
       dartium build of DumpRenderTree.

   frogium: Compile dart code by running frog on the standalone dart vm,
       and run the resulting javascript in a javascript script tag in
       a dartium build of DumpRenderTree.

   legium: Compile dart code by running leg on the standalone dart vm,
       and run the resulting javascript in a javascript script tag in
       a dartium build of DumpRenderTree.

   webdriver: Compile dart code by running frog on the standalone dart vm,
       and then run the resulting javascript in the browser that is specified
       by the --browser switch (e.g. chrome, safari, ff, etc.).

   dartc: Run dart code through the dartc static analyzer (does not
       execute dart code).
''',
              ['-c', '--component'],
              ['most', 'vm', 'frog', 'leg', 'frogsh', 'dartium',  'frogium',
               'legium', 'webdriver', 'dartc'],
              'vm'),
          new _TestOptionSpecification(
              'arch',
              'The architecture to run tests for',
              ['-a', '--arch'],
              ['all', 'ia32', 'x64', 'simarm'],
              'ia32'),
          new _TestOptionSpecification(
              'system',
              'The operating system to run tests on',
              ['-s', '--system'],
              ['linux', 'macos', 'windows'],
              new Platform().operatingSystem()),
          new _TestOptionSpecification(
              'checked',
              'Run tests in checked mode',
              ['--checked'],
              [],
              false,
              'bool'),
          new _TestOptionSpecification(
              'host_checked',
              'Run compiler in checked mode',
              ['--host-checked'],
              [],
              false,
              'bool'),
          new _TestOptionSpecification(
              'timeout',
              'Timeout in seconds',
              ['-t', '--timeout'],
              [],
              -1,
              'int'),
          new _TestOptionSpecification(
              'progress',
              'Progress indication mode',
              ['-p', '--progress'],
              ['compact', 'color', 'line', 'verbose',
               'silent', 'status', 'buildbot'],
              'compact'),
          new _TestOptionSpecification(
              'report',
              'Print a summary report of the number of tests, by expectation',
              ['--report'],
              [],
              false,
              'bool'),
          new _TestOptionSpecification(
              'tasks',
              'The number of parallel tasks to run',
              ['-j', '--tasks'],
              [],
              new Platform().numberOfProcessors(),
              'int'),
          new _TestOptionSpecification(
              'help',
              'Print list of options',
              ['-h', '--help'],
              [],
              false,
              'bool'),
          new _TestOptionSpecification(
              'verbose',
              'Verbose output',
              ['-v', '--verbose'],
              [],
              false,
              'bool'),
          new _TestOptionSpecification(
              'list',
              'List tests only, do not run them',
              ['--list'],
              [],
              false,
              'bool'),
          new _TestOptionSpecification(
              'keep-generated-tests',
              'Keep the generated files in the temporary directory',
              ['--keep-generated-tests'],
              [],
              false,
              'bool'),
          new _TestOptionSpecification(
              'valgrind',
              'Run tests through valgrind',
              ['--valgrind'],
              [],
              false,
              'bool'),
          new _TestOptionSpecification(
              'special-command',
              specialCommandHelp,
              ['--special-command'],
              [],
              ''),
          new _TestOptionSpecification(
              'time',
              'Print timing information after running tests',
              ['--time'],
              [],
              false,
              'bool'),
          new _TestOptionSpecification(
              'browser',
              'Web browser to use on webdriver tests',
              ['-b', '--browser'],
              ['ff', 'chrome', 'safari', 'ie', 'opera'],
              'chrome'),
          new _TestOptionSpecification(
              'frog',
              'Path to frog executable',
              ['--frog'],
              [],
              ''),
          new _TestOptionSpecification(
              'drt',
              'Path to DumpRenderTree executable',
              ['--drt'],
              [],
              ''),
          new _TestOptionSpecification(
              'froglib',
              'Path to frog library',
              ['--froglib'],
              [],
              ''),
          new _TestOptionSpecification(
              'noBatch',
              'Do not run browser tests in batch mode',
              ['-n', '--nobatch'],
              [],
              false,
              'bool')];
  }


  /**
   * Parse a list of strings as test options.
   *
   * Returns a list of configurations in which to run the
   * tests. Configurations are maps mapping from option keys to
   * values. When encountering the first non-option string, the rest
   * of the arguments are stored in the returned Map under the 'rest'
   * key.
   */
  List<Map> parse(List<String> arguments) {
    var configuration = new Map();
    // Fill in configuration with arguments passed to the test script.
    var numArguments = arguments.length;
    for (var i = 0; i < numArguments; i++) {
      // Extract name and value for options.
      String arg = arguments[i];
      String name = '';
      String value = '';
      _TestOptionSpecification spec;
      if (arg.startsWith('--')) {
        if (arg == '--help') {
          _printHelp();
          return null;
        }
        var split = arg.indexOf('=');
        if (split == -1) {
          name = arg;
          spec = _getSpecification(name);
          // Boolean options do not have a value.
          if (spec.type != 'bool') {
            if ((i + 1) >= arguments.length) {
              print('No value supplied for option $name');
              return null;
            }
            value = arguments[++i];
          }
        } else {
          name = arg.substring(0, split);
          spec = _getSpecification(name);
          value = arg.substring(split + 1, arg.length);
        }
      } else if (arg.startsWith('-')) {
        if (arg == '-h') {
          _printHelp();
          return null;
        }
        if (arg.length > 2) {
          name = arg.substring(0, 2);
          spec = _getSpecification(name);
          value = arg.substring(2, arg.length);
        } else {
          name = arg;
          spec = _getSpecification(name);
          // Boolean options do not have a value.
          if (spec.type != 'bool') {
            if ((i + 1) >= arguments.length) {
              print('No value supplied for option $name');
              return null;
            }
            value = arguments[++i];
          }
        }
      } else {
        // The argument does not start with '-' or '--' and is
        // therefore not an option. We use it as a test selection
        // pattern.
        configuration.putIfAbsent('selectors', () => []);
        var patterns = configuration['selectors'];
        patterns.add(arg);
        continue;
      }


      // Multiple uses of a flag are an error, because there is no
      // naturally correct way to handle conflicting options.
      if (configuration.containsKey(spec.name)) {
        print('Error: test.dart disallows multiple "--${spec.name}" flags');
        exit(1);
      }
      // Parse the value for the option.
      if (spec.type == 'bool') {
        if (!value.isEmpty()) {
          print('No value expected for bool option $name');
          exit(1);
        }
        configuration[spec.name] = true;
      } else if (spec.type == 'int') {
        try {
          configuration[spec.name] = Math.parseInt(value);
        } catch (var e) {
          print('Integer value expected for int option $name');
          exit(1);
        }
      } else {
        assert(spec.type == 'string');
        if (!spec.values.isEmpty()) {
          for (var v in value.split(',')) {
            if (spec.values.lastIndexOf(v) == -1) {
              print('Unknown value ($v) for option $name');
              exit(1);
            }
          }
        }
        configuration[spec.name] = value;
      }
    }

    // Apply default values for unspecified options.
    for (var option in _options) {
      if (!configuration.containsKey(option.name)) {
        configuration[option.name] = option.defaultValue;
      }
    }

    return _expandConfigurations(configuration);
  }


  /**
   * Recursively expand a configuration with multiple values per key
   * into a list of configurations with exactly one value per key.
   */
  List<Map> _expandConfigurations(Map configuration) {

    // TODO(ager): Get rid of this. This is for backwards
    // compatibility with the python test scripts. They use system
    // 'win32' for Windows.
    if (configuration['system'] == 'windows') {
      configuration['system'] = 'win32';
    }

    // Expand the pseudo-values such as 'all'.
    if (configuration['arch'] == 'all') {
      configuration['arch'] = 'ia32,x64';
    }
    if (configuration['mode'] == 'all') {
      configuration['mode'] = 'debug,release';
    }
    if (configuration['component'] == 'most') {
      configuration['component'] = 'vm,dartc';
    }
    if (configuration['valgrind']) {
      // TODO(ager): Get rid of this when there is only one checkout and
      // we don't have to special case for the runtime checkout.
      File valgrindFile = new File('runtime/tools/valgrind.py');
      if (!valgrindFile.existsSync()) {
        valgrindFile = new File('../runtime/tools/valgrind.py');
      }
      String valgrind = valgrindFile.fullPathSync();
      configuration['special-command'] = 'python -u $valgrind @';
    }

    // Use verbose progress indication for verbose output unless buildbot
    // progress indication is requested.
    if (configuration['verbose'] && configuration['progress'] != 'buildbot') {
      configuration['progress'] = 'verbose';
    }

    // Create the artificial 'unchecked' options that test status files
    // expect.
    configuration['unchecked'] = !configuration['checked'];
    configuration['host_unchecked'] = !configuration['host_checked'];

    // Expand the test selectors into a suite name and a simple
    // regular expressions to be used on the full path of a test file
    // in that test suite. If no selectors are explicitly given use
    // the default suite patterns.
    var selectors = configuration['selectors'];
    if (selectors is !Map) {
      if (selectors == null) {
        selectors = new List.from(defaultTestSelectors);
      }
      Map<String, RegExp> selectorMap = new Map<String, RegExp>();
      for (var i = 0; i < selectors.length; i++) {
        var pattern = selectors[i];
        var suite = pattern;
        var slashLocation = pattern.indexOf('/');
        if (slashLocation != -1) {
          suite = pattern.substring(0, slashLocation);
          pattern = pattern.substring(slashLocation + 1);
          pattern = pattern.replaceAll('*', '.*');
          pattern = pattern.replaceAll('/', '.*');
        } else {
          pattern = ".*";
        }
        if (selectorMap.containsKey(suite)) {
          print("Error: '$suite/$pattern'.  Only one test selection" +
                " pattern is allowed to start with '$suite/'");
          exit(1);
        }
        selectorMap[suite] = new RegExp(pattern);
      }
      configuration['selectors'] = selectorMap;
    }

    // Expand the architectures.
    var archs = configuration['arch'];
    if (archs.contains(',')) {
      var result = new List<Map>();
      for (var arch in archs.split(',')) {
        var newConfiguration = new Map.from(configuration);
        newConfiguration['arch'] = arch;
        result.addAll(_expandConfigurations(newConfiguration));
      }
      return result;
    }

    // Expand modes.
    var modes = configuration['mode'];
    if (modes.contains(',')) {
      var result = new List<Map>();
      for (var mode in modes.split(',')) {
        var newConfiguration = new Map.from(configuration);
        newConfiguration['mode'] = mode;
        result.addAll(_expandConfigurations(newConfiguration));
      }
      return result;
    }

    // Expand components.
    var components = configuration['component'];
    if (components.contains(',')) {
      var result = new List<Map>();
      for (var component in components.split(',')) {
        var newConfiguration = new Map.from(configuration);
        newConfiguration['component'] = component;
        result.addAll(_expandConfigurations(newConfiguration));
      }
      return result;
    } else {
      // All components eventually go through this path, after expansion.
      if (DumpRenderTreeUpdater.componentRequiresDRT(components)) {
        DumpRenderTreeUpdater.update();
      }
    }

    // Adjust default timeout based on mode and component.
    if (configuration['timeout'] == -1) {
      var timeout = 60;
      switch (configuration['component']) {
        case 'dartc':
        case 'dartium':
        case 'frogium':
        case 'legium':
        case 'webdriver':
          timeout *= 4;
          break;
        case 'leg':
        case 'frog':
          if (configuration['mode'] == 'debug') {
            timeout *= 4;
          }
          if (configuration['host_checked']) {
            timeout *= 8;
          }
          break;
        default:
          if (configuration['mode'] == 'debug') {
            timeout *= 2;
          }
          break;
      }
      configuration['timeout'] = timeout;
    }

    return [configuration];
  }


  /**
   * Print out usage information.
   */
  void _printHelp() {
    print('usage: dart test.dart [options]\n');
    print('Options:\n');
    for (var option in _options) {
      print('${option.name}: ${option.description}.');
      for (var name in option.keys) {
        assert(name.startsWith('-'));
        var buffer = new StringBuffer();;
        buffer.add(name);
        if (option.type == 'bool') {
          assert(option.values.isEmpty());
        } else {
          buffer.add(name.startsWith('--') ? '=' : ' ');
          if (option.type == 'int') {
            assert(option.values.isEmpty());
            buffer.add('n (default: ${option.defaultValue})');
          } else {
            buffer.add('[');
            bool first = true;
            for (var value in option.values) {
              if (!first) buffer.add(", ");
              if (value == option.defaultValue) buffer.add('*');
              buffer.add(value);
              first = false;
            }
            buffer.add(']');
          }
        }
        print(buffer.toString());
      }
      print('');
    }
  }


  /**
   * Find the test option specification for a given option key.
   */
  _TestOptionSpecification _getSpecification(String name) {
    for (var option in _options) {
      if (option.keys.some((key) => key == name)) {
        return option;
      }
    }
    print('Unknown test option $name');
    exit(1);
  }


  List<_TestOptionSpecification> _options;
}
