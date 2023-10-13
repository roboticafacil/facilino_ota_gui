import 'dart:async';
import 'dart:convert';

import 'util/ArduinoCLI.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:process_run/shell.dart' as ShellProcessRun;
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import 'package:loading_indicator/loading_indicator.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'main.dart';

class SplashScreen extends StatefulWidget {
  final bool overwrite;
  const SplashScreen({super.key,required this.overwrite});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
   final String arduinoCLIURL='https://facilino.webs.upv.es/arduino-cli/arduino-cli.exe';
   late Future<String> message;
   late Future<String> sub_message;

  checkArduinoCLI() async {
    String arduino_cli_exe='';
    setState(() {
      message=Future<String> (() => AppLocalizations.of(context)!.checkingCLI);
      sub_message = Future<String>(() => "");
    });
    ArduinoCLI.initializeShell();

    String arduinoCliDir=ArduinoCLI.getArduinoCLIDir();
    arduino_cli_exe=ArduinoCLI.getArduinoCLIPath();

    bool no_errors=true;

    if ((await Directory(arduinoCliDir).exists())&&(widget.overwrite))
    {
      await Directory(arduinoCliDir).delete(recursive: true);
      setState(() {
        message=Future<String> (() => AppLocalizations.of(context)!.restoringCLI);
        sub_message = Future<String>(() => "");
      });
      await Future.delayed(const Duration(seconds: 1));
    }

    if ((!await Directory(arduinoCliDir).exists())||(widget.overwrite))
    {
      setState(() {
        message=Future<String> (() => AppLocalizations.of(context)!.downloadingCLI);
        sub_message = Future<String>(() => "");
      });
      await Directory.fromUri(Uri.directory(arduinoCliDir)).create(recursive: true);
      HttpClient httpClient = HttpClient();
      File file;
      try {
        var request = await httpClient.getUrl(Uri.parse(arduinoCLIURL));
        var response = await request.close();
        if(response.statusCode == 200) {
          var bytes = await consolidateHttpClientResponseBytes(response);
          if (Platform.isWindows) {
            file = File('$arduino_cli_exe.exe');
          } else {
            file = File(arduino_cli_exe);
          }
          setState(() {
            sub_message=Future<String> (() => AppLocalizations.of(context)!.fileDownloadedOn(file.path));
          });
          await file.writeAsBytes(bytes);
        }
        else {
          no_errors=false;
          setState(() {
            sub_message=Future<String> (() => AppLocalizations.of(context)!.errorCode(response.statusCode));
          });
          debugPrint('Error code: ${response.statusCode}');
        }
      }
      catch(ex){
        no_errors=false;
        setState(() {
          sub_message=Future<String> (() => AppLocalizations.of(context)!.cannotFetchURL(arduinoCLIURL));
        });
        debugPrint('Can not fetch url');
      }
    }

    if (no_errors) {
      String cmd = widget.overwrite? '$arduino_cli_exe config init --overwrite' : '$arduino_cli_exe config init';
      try {
        await shell.run(cmd);
        setState(() {
          message = Future<
              String>(() => AppLocalizations.of(context)!.gettingCLIDependencies);
          sub_message = Future<String>(() => "");
        });
        await Future.delayed(const Duration(seconds: 1));
        //If we get to this point it means that Facilino OTA Server is not configured...
        var url = Uri.https('facilino.webs.upv.es', '/dependencies.php');
        var response = await http.get(url);
        if (response.statusCode == 200) {
          setState(() {
            message = Future<String>(() => AppLocalizations.of(context)!.configuringCLI);
          });
          //First set directories for Arduino CLI
          cmd =
          '$arduino_cli_exe config set directories.data $arduinoCliDir${Platform
              .pathSeparator}Arduino15';
          List<ProcessResult> res = await shell.run(cmd);
          debugPrint(utf8.decode(res.outText.runes.toList()));
          cmd =
          '$arduino_cli_exe config set directories.downloads $arduinoCliDir${Platform
              .pathSeparator}Arduino15${Platform.pathSeparator}staging';
          res = await shell.run(cmd);
          debugPrint(utf8.decode(res.outText.runes.toList()));
          cmd =
          '$arduino_cli_exe config set library.enable_unsafe_install true';
          res = await shell.run(cmd);
          debugPrint(utf8.decode(res.outText.runes.toList()));
          cmd =
          '$arduino_cli_exe config set locale en_US';
          res = await shell.run(cmd);
          debugPrint(utf8.decode(res.outText.runes.toList()));
          //Now, install core boards
          setState(() {
            message =
                Future<String>(() => AppLocalizations.of(context)!.installingBoards);
          });
          await Future.delayed(const Duration(seconds: 1));
          var jsonResponse =
          convert.jsonDecode(response.body) as Map<String, dynamic>;
          debugPrint(jsonResponse.toString());
          for (var instruction in jsonResponse['core']) {
            String sub_cmd = instruction as String;
            try {
              cmd = '$arduino_cli_exe $sub_cmd';
              setState(() {
                sub_message = Future<String>(() => cmd);
              });
              res = await shell.run(cmd);
              for (var r in res) {
                setState(() {
                  sub_message = Future<String>(() => utf8.decode(res.outText.runes.toList()));
                });
                debugPrint(res.outText);
              }
            } on ShellProcessRun.ShellException catch (error) {
              debugPrint(cmd);
              debugPrint(error.result!.errText);
              setState(() {
                sub_message = Future<String>(() => utf8.decode(error.result!.errText.runes.toList()) );
              });

              await Future.delayed(const Duration(seconds: 1));

            }
          }

          debugPrint('For loop for libs done!');

          setState(() {
            message =
                Future<String>(() => AppLocalizations.of(context)!.installingLibraries);
            sub_message = Future<String>(() => "");
          });

          await Future.delayed(const Duration(seconds: 1));

          for (var instruction in jsonResponse['libs']) {
            String sub_cmd = instruction as String;
            if (sub_cmd.contains("--zip-path")) {
              List<String> c = sub_cmd.split(" ");
              String libFile = c[3];
              HttpClient httpClient = HttpClient();
              File file;
              setState(() {
                sub_message = Future<
                    String>(() => AppLocalizations.of(context)!.downloadingFile('https://facilino.webs.upv.es/arduino-cli/$libFile'));
              });
              var request = await httpClient.getUrl(Uri.parse(
                  'https://facilino.webs.upv.es/arduino-cli/$libFile'));
              var response = await request.close();
              if (response.statusCode == 200) {
                var bytes = await consolidateHttpClientResponseBytes(
                    response);
                file = File(libFile);
                await file.writeAsBytes(bytes);
              }
            }

            try {
              cmd = '$arduino_cli_exe $sub_cmd';
              setState(() {
                sub_message = Future<String>(() => cmd);
              });
              res = await shell.run(cmd);
              for (var r in res) {
                setState(() {
                  sub_message = Future<String>(() => utf8.decode(res.outText.runes.toList()) );
                });
                debugPrint(res.outText);
              }
            } on ShellProcessRun.ShellException catch (error) {
              setState(() {
                sub_message = Future<String>(() => utf8.decode(error.result!.errText.runes.toList()) );
              });
              debugPrint(error.result!.errText);
            }
          }
          setState(() {
            message =
                Future<String>(() => AppLocalizations.of(context)!.cliInstalled);
            sub_message = Future<String>(() => "");
          });

          await Future.delayed(const Duration(seconds: 1));

          widget.overwrite? navigatorKey.currentState?.pushReplacementNamed('/already_logged_in'):  navigatorKey.currentState?.pushReplacementNamed('/login');
        } else {
          setState(() {
            sub_message =
                Future<String>(() => AppLocalizations.of(context)!.requestFailed(response.statusCode));
          });
          debugPrint('Request failed with status: ${response.statusCode}');

          await Future.delayed(const Duration(seconds: 1));

          setState(() {
            message = Future<String>(() => AppLocalizations.of(context)!.cliChecked);
            sub_message = Future<String>(() => "");
          });

          await Future.delayed(const Duration(seconds: 1));

          widget.overwrite? navigatorKey.currentState?.pushReplacementNamed('/already_logged_in'):  navigatorKey.currentState?.pushReplacementNamed('/login');
        }
      } on ShellProcessRun.ShellException catch (error) {
        setState(() {
          sub_message = Future<String>(() => utf8.decode(error.result!.errText.runes.toList()) );
        });
        debugPrint(error.result!.exitCode.toString());

        await Future.delayed(const Duration(seconds: 1));

        widget.overwrite? navigatorKey.currentState?.pushReplacementNamed('/already_logged_in'):  navigatorKey.currentState?.pushReplacementNamed('/login');
        //navigatorKey.currentState?.pushReplacementNamed('/login');

      }
    }
}

  @override
  void initState() {
    super.initState();
    checkArduinoCLI();
  }

  @override
  Widget build(BuildContext context) {

    //Future.delayed(Duration(seconds: 10));
    return Scaffold(
      body: Center (child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
    children: [
      Image.file(File('assets/facilino.png'),),
      const Flexible(child: LoadingIndicator(indicatorType: Indicator.ballPulse,strokeWidth: 4.0)),
      FutureBuilder<String>(
        builder: (BuildContext context, AsyncSnapshot<String> snapshot){
        if (!snapshot.hasData) {
          return Container();
        }
        if (snapshot.hasError) {
          return Center(child: Text(AppLocalizations.of(context)!.somethingWentWrong));
        }
        return Text(snapshot.data!);
        },
        future: message
      ),
      FutureBuilder<String>(
          builder: (BuildContext context, AsyncSnapshot<String> snapshot){
            if (!snapshot.hasData) {
              return Container();
            }
            if (snapshot.hasError) {
              return Center(child: Text(AppLocalizations.of(context)!.somethingWentWrong));
            }
            return Text(snapshot.data!,style: const TextStyle(fontSize: 8),);
          },
          future: sub_message
      )
      ]
    )
      ),
      ),
    );
  }
}