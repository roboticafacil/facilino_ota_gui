import 'dart:io';
import 'package:process_run/shell.dart' as ShellProcessRun;
import 'ArduinoCLI.dart';

class Board
{
  String port;
  String protocol;
  String type;
  Board({required this.port, required this.protocol, required this.type});

  static Future<List<Board>> getBoards() async {
    String arduino_cli_exe = '';
    String arduinoCliDir = ArduinoCLI.getArduinoCLIDir();
    arduino_cli_exe = ArduinoCLI.getArduinoCLIPath();

    if (await Directory(arduinoCliDir).exists()) {
      String cmd = '$arduino_cli_exe board list';
      try {
        List<ProcessResult> res = await shell.run(cmd);

        List<Board> boardList = [];
        int count = 0;
        int num_boards = res.outLines.length - 2;
        for (var r in res.outLines) {
          if ((count >= 1) && (count <= num_boards)) {
            List<String> words = r.split(RegExp(r"\s+"));
            boardList.add(Board(
                port: words[0],
                protocol: words[1],
                type: words.getRange(2, words.length).join(' ')));
          }
          count++;
        }
        return Future<List<Board>>(() => boardList);
      } on ShellProcessRun.ShellException catch (error) {
        return Future<List<Board>>(() => []);
      }
    }
    else
      return Future<List<Board>>(() => []);
  }
}