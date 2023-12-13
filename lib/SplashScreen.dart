import 'dart:async';
import 'dart:convert';
//import 'dart:html';

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
   final String arduinoCLIURL=Platform.isWindows? 'https://facilino.webs.upv.es/arduino-cli/arduino-cli.exe' : 'https://facilino.webs.upv.es/arduino-cli/arduino-cli';
   late Future<String> message;
   late Future<String> sub_message;
   late Future<String> steps;

  checkArduinoCLI() async {
    String arduinoCliExe='';
    setState(() {
      message=Future<String> (() => AppLocalizations.of(context)!.checkingCLI);
      steps=Future<String> (()=> "");
      sub_message = Future<String>(() => "");
    });
    ArduinoCLI.initializeShell();

    String arduinoCliDir=ArduinoCLI.getArduinoCLIDir();
    arduinoCliExe=ArduinoCLI.getArduinoCLIPath();

    bool noErrors=true;

    if ((await Directory(arduinoCliDir).exists())&&(widget.overwrite))
    {
      await Directory(arduinoCliDir).delete(recursive: true);
      setState(() {
        message=Future<String> (() => AppLocalizations.of(context)!.restoringCLI);
        steps = Future<String>(() => "");
        sub_message = Future<String>(() => "");
      });
      await Future.delayed(const Duration(seconds: 1));
    }

    if ((!await Directory(arduinoCliDir).exists())||(widget.overwrite))
    {
      setState(() {
        message=Future<String> (() => AppLocalizations.of(context)!.downloadingCLI);
        steps = Future<String>(() => "");
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
            file = File('$arduinoCliExe.exe');
          } else {
            file = File(arduinoCliExe);
          }
          setState(() {
            steps = Future<String>(() => "");
            sub_message=Future<String> (() => AppLocalizations.of(context)!.fileDownloadedOn(file.path));
          });
          await file.writeAsBytes(bytes);
          if (Platform.isLinux)
            {
              debugPrint('Setting Arduino CLI as an executable file');
              shell.run('chmod +x $arduinoCliExe');
            }
        }
        else {
          noErrors=false;
          setState(() {
            steps = Future<String>(() => "");
            sub_message=Future<String> (() => AppLocalizations.of(context)!.errorCode(response.statusCode));
          });
          debugPrint('Error code: ${response.statusCode}');
        }
      }
      catch(ex){
        noErrors=false;
        setState(() {
          steps = Future<String>(() => "");
          sub_message=Future<String> (() => AppLocalizations.of(context)!.cannotFetchURL(arduinoCLIURL));
        });
        debugPrint('Can not fetch url');
      }
    }

    if (noErrors) {
      //String cmd = widget.overwrite? (Platform.isWindows? '$arduinoCliExe config init --overwrite':'sudo $arduinoCliExe config init --overwrite') : (Platform.isWindows? '$arduinoCliExe config init':'sudo $arduinoCliExe config init');
      String cmd = widget.overwrite? '$arduinoCliExe config init --overwrite' : '$arduinoCliExe config init';
      try {
        await shell.run(cmd);
        setState(() {
          message = Future<
              String>(() => AppLocalizations.of(context)!.gettingCLIDependencies);
          steps = Future<String>(() => "");
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
          '$arduinoCliExe config set directories.data $arduinoCliDir${Platform
              .pathSeparator}Arduino15';
          List<ProcessResult> res = await shell.run(cmd);
          debugPrint(utf8.decode(res.outText.runes.toList()));
          cmd =
          '$arduinoCliExe config set directories.downloads $arduinoCliDir${Platform
              .pathSeparator}Arduino15${Platform.pathSeparator}staging';
          res = await shell.run(cmd);
          debugPrint(utf8.decode(res.outText.runes.toList()));
          cmd =
          '$arduinoCliExe config set library.enable_unsafe_install true';
          res = await shell.run(cmd);
          debugPrint(utf8.decode(res.outText.runes.toList()));
          cmd =
          '$arduinoCliExe config set locale en_US';
          res = await shell.run(cmd);
          debugPrint(utf8.decode(res.outText.runes.toList()));
          var jsonResponse =
          convert.jsonDecode(response.body) as Map<String, dynamic>;
          List<dynamic> coreList=jsonResponse['core'] as List<dynamic>;
          List<dynamic> libList=jsonResponse['libs'] as List<dynamic>;
          int numSteps=coreList.length+libList.length;
          int currentStep=0;
          //Now, install core boards
          setState(() {
            message =
                Future<String>(() => AppLocalizations.of(context)!.installingBoards);
              steps = Future<String> (() => '$currentStep/$numSteps');
          });
          await Future.delayed(const Duration(seconds: 1));

          debugPrint(jsonResponse.toString());
          for (var instruction in coreList) {
            String subCmd=instruction as String;
            currentStep++;
            try {
              cmd = '$arduinoCliExe $subCmd';
              setState(() {
                steps = Future<String> (() => '$currentStep/$numSteps');
                sub_message = Future<String>(() => cmd);
              });
              res = await shell.run(cmd);
              for (var r in res) {
                setState(() {
                  steps = Future<String> (() => '$currentStep/$numSteps');
                  sub_message = Future<String>(() => utf8.decode(res.outText.runes.toList()));
                });
                debugPrint(res.outText);
              }
            } on ShellProcessRun.ShellException catch (error) {
              debugPrint(cmd);
              debugPrint(error.result!.errText);
              setState(() {
                steps = Future<String> (() => '$currentStep/$numSteps');
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

          for (var instruction in libList) {
            String subCmd=instruction as String;
            currentStep++;
            if (subCmd.contains("--zip-path")) {
              List<String> c = subCmd.split(" ");
              String libFile = c[3];
              HttpClient httpClient = HttpClient();
              File file;
              setState(() {
                steps = Future<String> (() => '$currentStep/$numSteps');
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
              cmd = '$arduinoCliExe $subCmd';
              setState(() {
                steps = Future<String> (() => '$currentStep/$numSteps');
                sub_message = Future<String>(() => cmd);
              });
              res = await shell.run(cmd);
              for (var r in res) {
                setState(() {
                  steps = Future<String> (() => '$currentStep/$numSteps');
                  sub_message = Future<String>(() => utf8.decode(res.outText.runes.toList()) );
                });
                debugPrint(res.outText);
              }
            } on ShellProcessRun.ShellException catch (error) {
              setState(() {
                steps = Future<String> (() => '$currentStep/$numSteps');
                sub_message = Future<String>(() => utf8.decode(error.result!.errText.runes.toList()) );
              });
              debugPrint(error.result!.errText);
            }
          }
          setState(() {
            message =
                Future<String>(() => AppLocalizations.of(context)!.cliInstalled);
            steps = Future<String> (() => "");
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
            return Text(snapshot.data!,style: const TextStyle(fontSize: 10));
          },
          future: steps
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