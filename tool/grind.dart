import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:async/async.dart' show StreamGroup;
import 'package:grinder/grinder.dart';

main(List<String> args) => grind(args);

/// flutter pub get
@Task('pub get')
void pub() {
  _processLog(Process.start('flutter', ['pub', 'get']));
}


/// build_runner でファイルを生成
@Task('run build_runner')
void runner() {
  _runProcess(
      'flutter',
      ['pub', 'run', 'build_runner', 'build', '--delete-conflicting-outputs'],
  );
}

/// 静的解析
@Task('analyze')
void analyze() {
  Analyzer.analyze(['./lib']);
}

/// ユニットテスト
@Task('unit test')
@Depends(analyze)
void test() {
  TestRunner().test(files: 'test/unit');
}

/// 静的解析・ユニットテストを行ったのちビルドする
@Task('build')
@Depends(test)
void build() {
  TaskArgs args = context.invocation.arguments;

  final mode = args.getOption('mode');
  log(mode);
  if (mode?.isEmpty ?? true) {
    throw Exception('mode option is required.');
  }

  // APサーバ、データベースの接続先などを指定する環境変数
  final isRelease = args.getFlag('release');
  final env = isRelease ? 'release' : 'staging';

  _processLog(Process.start(
    'flutter',
    ['build', mode, '--dart-define=ENV=${env}']
  ));
}

Future<void> _processLog(Future<Process> process) async {
  final _process = await process;
  final output = StreamGroup.merge([_process.stdout, _process.stderr]);
  await for (final message in output) {
    log(utf8.decode(message));
  }
}

Future<void> _runProcess(String executable, List<String> arguments) async {
  final result = await Process.run(executable, arguments);
  stdout.write(result.stdout);
  stderr.write(result.stderr);
}