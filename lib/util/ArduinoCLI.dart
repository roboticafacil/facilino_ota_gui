import 'dart:io';
import 'package:process_run/shell.dart' as ShellProcessRun;

late ShellProcessRun.Shell shell;

class ArduinoCLI
{
  static String getArduinoCLIPath() {
    String arduino_cli_exe;
    String appDir = File(Platform.resolvedExecutable).parent.path;
    arduino_cli_exe = '$appDir${Platform.pathSeparator}arduino-cli${Platform
        .pathSeparator}arduino-cli';
    return arduino_cli_exe;
  }

  static String getArduinoCLIDir() {
    String appDir = File(Platform.resolvedExecutable).parent.path;
    String arduinoCliDir = '$appDir${Platform.pathSeparator}arduino-cli';
    return arduinoCliDir;
  }

  static void initializeShell()
  {
    if (Platform.isLinux||Platform.isWindows||Platform.isMacOS) {
      var controller = ShellProcessRun.ShellLinesController();
      //if (Platform.isLinux) {
      //  var env = ShellProcessRun.ShellEnvironment()..aliases['sudo']='sudo --stdin';
      //  var stdin = ShellProcessRun.sharedStdIn;
      //  shell = ShellProcessRun.Shell(stdin: stdin, environment: env, stdout: controller.sink, verbose: true);
      //}
      //else
      //  {
          shell = ShellProcessRun.Shell(stdout: controller.sink, verbose: true);
      //  }
    }
  }

}