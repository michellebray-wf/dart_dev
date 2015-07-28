library dart_dev.src.tasks.format.api;

import 'dart:async';

import 'package:dart_dev/process.dart';

import 'package:dart_dev/src/tasks/format/config.dart';
import 'package:dart_dev/src/tasks/task.dart';

FormatTask format(
    {bool check: defaultCheck, List<String> directories: defaultDirectories}) {
  var executable = 'pub';
  var args = ['run', 'dart_style:format'];

  if (check) {
    args.add('-n');
  } else {
    args.add('-w');
  }

  args.addAll(directories);

  TaskProcess process = new TaskProcess(executable, args);
  FormatTask task = new FormatTask(
      '$executable ${args.join(' ')}', process.done)..isDryRun = check;

  RegExp cwdPattern = new RegExp('Formatting directory (.+):');
  RegExp formattedPattern = new RegExp('Formatted (.+\.dart)');
  RegExp unchangedPattern = new RegExp('Unchanged (.+\.dart)');

  String cwd = '';
  process.stdout.listen((line) {
    if (check) {
      task.affectedFiles.add(line.trim());
    } else {
      if (cwdPattern.hasMatch(line)) {
        cwd = cwdPattern.firstMatch(line).group(1);
      } else if (formattedPattern.hasMatch(line)) {
        task.affectedFiles
            .add('$cwd${formattedPattern.firstMatch(line).group(1)}');
      } else if (unchangedPattern.hasMatch(line)) {
        task.unaffectedFiles
            .add('$cwd${unchangedPattern.firstMatch(line).group(1)}');
      }
    }
    task._formatterOutput.add(line);
  });
  process.stderr.listen(task._formatterOutput.addError);
  process.exitCode.then((code) {
    task.successful = check ? task.affectedFiles.isEmpty : code <= 0;
  });

  return task;
}

class FormatTask extends Task {
  List<String> affectedFiles = [];
  final Future done;
  final String formatterCommand;
  bool isDryRun;
  List<String> unaffectedFiles = [];

  StreamController<String> _formatterOutput = new StreamController();

  FormatTask(String this.formatterCommand, Future this.done);

  Stream<String> get formatterOutput => _formatterOutput.stream;
}
