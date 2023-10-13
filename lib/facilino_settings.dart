import 'dart:io';
import 'package:facilino_ota_gui/SplashScreen.dart';
import 'package:facilino_ota_gui/add_arduino_cli_library.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:scrollable_table_view/scrollable_table_view.dart';
import 'util/Core.dart';
import 'util/Library.dart';
import 'util/Board.dart';
import 'package:flutter/material.dart';
import 'util/ArduinoCLI.dart';
import 'package:process_run/shell.dart' as ShellProcessRun;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import 'package:string_similarity/string_similarity.dart';

class FacilinoSettings extends StatefulWidget {
  const FacilinoSettings({super.key});

  @override
  State<FacilinoSettings> createState() => FacilinoSettingsState();
}

class FacilinoSettingsState extends State<FacilinoSettings> {
  //final _arduinoCLIFormKey = GlobalKey<FormBuilderState>();

  late Future<List<Core>> _coreList=Future<List<Core>>(()=> []);
  late Future<List<Board>> _boardList=Future<List<Board>>(()=> []);
  late Future<List<Library>> _libList=Future<List<Library>>(()=> []);

  final List<String> _requiredCoreListName=[];
  final List<String> _requiredLibListName=[];

  checkCores() async{
    String arduino_cli_exe = '';
    String arduinoCliDir = ArduinoCLI.getArduinoCLIDir();
    arduino_cli_exe = ArduinoCLI.getArduinoCLIPath();
    if (await Directory(arduinoCliDir).exists()) {
      String cmd = '$arduino_cli_exe core list';
      try {
        List<ProcessResult> res = await shell.run(cmd);
        List<Core> coreList = [];
        int count = 0;
        int num_cores = res.outLines.length - 2;
        for (var r in res.outLines) {
          if ((count >= 1) && (count <= num_cores)) {
            List<String> words = r.split(RegExp(r"\s+"));
            if (words.length >= 4) {
              coreList.add(Core(
                  id: words[0],
                  installed_version: words[1],
                  latest_version: words[2],
                  name: words.getRange(3, words.length).join(' ')));
            }
          }
          count++;
        }
        _coreList = Future<List<Core>>(() => coreList);
        await _coreList;
        //debugPrint(res.outText);
      } on ShellProcessRun.ShellException catch (error) {
        debugPrint(error.toString());
      }
    }
    setState(() {});
  }

  checkLibs() async {
    String arduino_cli_exe = '';
    String arduinoCliDir = ArduinoCLI.getArduinoCLIDir();
    arduino_cli_exe = ArduinoCLI.getArduinoCLIPath();
    if (await Directory(arduinoCliDir).exists()) {
      String cmd = '$arduino_cli_exe lib list';
      try {
        List<ProcessResult> res = await shell.run(cmd);
        //debugPrint(res.outText.toString());
        List<Library> libList = [];
        int count = 0;
        int num_libs = res.outLines.length - 2;
        for (var r in res.outLines) {
          if ((count >= 1) && (count <= num_libs)) {
            List<String> words = r.split(RegExp(r"\s+"));
            int installed_idx = -1;
            int idx = 0;
            for (String word in words) {
              if (word.isNotEmpty) {
                if (int.tryParse(word[0]) != null) {
                  //debugPrint(word);
                  installed_idx = idx;
                  break;
                }
              }
              idx++;
            }
            if (installed_idx >= 1) {
              String str = words.getRange(0, installed_idx).join(' ');
              final r = str.bestMatch(_requiredLibListName);
              debugPrint('$str best match ${r.bestMatch.rating!}');
              if (r.bestMatch.rating! > 0.7) {
                libList.add(Library(
                    name: str,
                    installed_version: words[installed_idx],
                    available_version: words[installed_idx + 1],
                    location: words[installed_idx + 2],
                    description: words.getRange(installed_idx + 3, words.length)
                        .join(' '),
                    system: true));
              }
              else {
                libList.add(Library(
                    name: str,
                    installed_version: words[installed_idx],
                    available_version: words[installed_idx + 1],
                    location: words[installed_idx + 2],
                    description: words.getRange(installed_idx + 3, words.length)
                        .join(' '),
                    system: false));
              }
            }
          }
          count++;
        }
        _libList = Future<List<Library>>(() => libList);
        await _libList;
        //debugPrint(res.outText);
      } on ShellProcessRun.ShellException catch (error) {
        debugPrint(error.toString());
      }
    }
    setState(() {});
  }

  addArduinoCLIBoard() async {
  }

  addArduinoCLILibrary() async {
    await Navigator.push(context,MaterialPageRoute(builder: (context) => const AddArduinoCLILibrary())).then((_) => checkLibs());
  }

  Future<bool> uninstallLib(String name) async {
    String arduino_cli_exe = '';
    String arduinoCliDir = ArduinoCLI.getArduinoCLIDir();
    arduino_cli_exe = ArduinoCLI.getArduinoCLIPath();
    if (await Directory(arduinoCliDir).exists()) {
      if (name.isNotEmpty) {
        String cmd = '$arduino_cli_exe lib uninstall $name';
        debugPrint(cmd);
        try {
          List<ProcessResult> res = await shell.run(cmd);
          debugPrint(res.toString());
          //Navigator.pop(context, true);
          //Navigator.pop(context,_newProjectFormKey.currentState!.value);
          return true;
        }
        on ShellProcessRun.ShellException catch (error) {
          debugPrint(error.toString());
        }
      }
    }
    return false;
  }

  checkArduinoCLI() async {

      var url = Uri.https('facilino.webs.upv.es', '/dependencies.php');
      var response = await http.get(url);
      if (response.statusCode == 200) {
        _requiredCoreListName.clear();
        _requiredLibListName.clear();
        var jsonResponse = convert.jsonDecode(response.body) as Map<String, dynamic>;
        for (String instruction in jsonResponse['core']) {
          int idx=instruction.indexOf("install");
          if (idx>0)
            {
              String str=instruction.substring(idx+8);
              if (str.contains((" ")))
                {
                  str=str.substring(0,str.indexOf(" "));
                }
              _requiredCoreListName.add(str);
              debugPrint(str);
            }
        }
        for (String instruction in jsonResponse['libs']) {
          int idx=instruction.indexOf("install");
          if (idx>0)
          {
            String str=instruction.substring(idx+8);
            if (str.contains(("--zip-path")))
            {
              str=str.substring(str.indexOf(" ")+1);
            }
            _requiredLibListName.add(str);
            debugPrint(str);
          }
        }
      }

      _boardList=Board.getBoards();
      await _boardList;

      checkCores();
      checkLibs();
      setState(() {});
    Future.delayed(const Duration(seconds: 1));
  }

  @override
  void initState() {
    super.initState();
    checkArduinoCLI();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.facilinoSettings,
            style:
                const TextStyle(color: Colors.black45, fontWeight: FontWeight.bold)),
        actions: [
          /*IconButton(onPressed: () {
            addArduinoCLIBoard();
          },
              icon: const Icon(Icons.add_card,color:Colors.white)
          ),*/
          IconButton(onPressed: () {
            addArduinoCLILibrary();
          },
              icon: const Icon(Icons.add,color:Colors.white)
          ),
          IconButton(onPressed: () {
            AlertDialog alert = AlertDialog(
              title: Text(AppLocalizations.of(context)!.reinstallCLI),
              content: Text(AppLocalizations.of(context)!.reinstallCLIQuestion),
              actions: [
                TextButton(
                  child: Text(AppLocalizations.of(context)!.no),
                  onPressed:  () {
                    Navigator.pop(context);
                  },
                ),
                TextButton(
                  child: Text(AppLocalizations.of(context)!.yes),
                  onPressed:  () {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const SplashScreen(overwrite: true)));
                  },
                ),
              ],
            );
            showDialog(context: context,
              builder: (BuildContext context) {
                return alert;
              },
            );
          },
              icon: const Icon(Icons.restore,color:Colors.white)
          ),
        ],
      ),
      body: Column(
          children: [
        const SizedBox(height: 10,),
            Center(child: Text(AppLocalizations.of(context)!.detectedBoards)),
            const SizedBox(height: 10,),
            FutureBuilder<List<Board>>(
                builder:
                    (BuildContext context, AsyncSnapshot<List<Board>> snapshot) {

                  if (!snapshot.hasData) {
                    return const Center(child: LoadingIndicator(indicatorType: Indicator.ballPulse,strokeWidth: 4.0));
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text(AppLocalizations.of(context)!.somethingWentWrong));
                  }

                  final boards=List<TableViewRow>.generate(snapshot.data!.length,
                          (index){
                        return TableViewRow(cells:
                        [
                          TableViewCell(alignment: Alignment.centerLeft, child: Text(snapshot.data![index].port)),
                          TableViewCell(alignment: Alignment.center, child: Text(snapshot.data![index].protocol)),
                          TableViewCell(alignment: Alignment.centerLeft, child: Text(snapshot.data![index].type))
                        ]
                          ,height: 20,);
                      },
                      growable: false
                  );

                  if (boards.isNotEmpty) {
                    return Expanded(
                        flex: 2,
                        child:
                        ScrollableTableView(
                          headers: [
                            AppLocalizations.of(context)!.port,
                            AppLocalizations.of(context)!.protocol,
                            AppLocalizations.of(context)!.type
                          ].map((label) {
                            return TableViewHeader(
                              label: label,
                              width: (MediaQuery
                                  .of(context)
                                  .size
                                  .width - 20) / 3,
                            );
                          }).toList(),
                          rows: boards,
                        )
                    );
                  }
                  else
                    {
                      return Column(children: [
                      Center(child: Text(AppLocalizations.of(context)!.noBoardsDetected,style: const TextStyle(color: Colors.deepOrange))),
                        const SizedBox(height: 10,)
                      ]);
                    }
                },
                future: _boardList),
        Center(child: Text(AppLocalizations.of(context)!.supportedHardware)),
        FutureBuilder<List<Core>>(
            builder:
                (BuildContext context, AsyncSnapshot<List<Core>> snapshot) {

                  if (!snapshot.hasData) {
                    return const Center(child: LoadingIndicator(indicatorType: Indicator.ballPulse,strokeWidth: 4.0));
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text(AppLocalizations.of(context)!.somethingWentWrong));
                  }

                  final cores=List<TableViewRow>.generate(snapshot.data!.length,
                      (index){
                        return TableViewRow(cells:
                        [
                          TableViewCell(alignment: Alignment.centerLeft, child: Text(snapshot.data![index].id)),
                          TableViewCell(alignment: Alignment.center, child: Text(snapshot.data![index].installed_version)),
                          TableViewCell(alignment: Alignment.centerLeft, child: Text(snapshot.data![index].name))
                        ]
                          ,height: 20,);
                      },
                    growable: false
                  );

                  return Expanded(
                    flex: 3,
                      child:
                  ScrollableTableView(
                    headers: [
                      AppLocalizations.of(context)!.id,
                      AppLocalizations.of(context)!.version,
                      AppLocalizations.of(context)!.name
                    ].map((label) {
                      return TableViewHeader(
                        label: label,
                        width: (MediaQuery.of(context).size.width-20)/3,
                      );
                    }).toList(),
                    rows: cores,
                  )
                  );
            },
            future: _coreList),
        Center(child: Text(AppLocalizations.of(context)!.installedLibraries)),
        const SizedBox(height: 10),
        FutureBuilder<List<Library>>(
            builder:
                (BuildContext context, AsyncSnapshot<List<Library>> snapshot) {

              if (!snapshot.hasData) {
                return const Center(child: LoadingIndicator(indicatorType: Indicator.ballPulse,strokeWidth: 4.0));
              }
              if (snapshot.hasError) {
                return Center(child: Text(AppLocalizations.of(context)!.somethingWentWrong));
              }

              final libraries=List<TableViewRow>.generate(snapshot.data!.length,
                      (index){
                    if (snapshot.data![index].system) {
                      return TableViewRow(cells:
                      [
                        TableViewCell(
                            alignment: Alignment.centerLeft, child: Text(
                            snapshot.data![index].name)),
                        TableViewCell(alignment: Alignment.center, child: Text(
                            snapshot.data![index].installed_version)),
                        TableViewCell(alignment: Alignment.center, child: Text(
                            snapshot.data![index].location)),
                        TableViewCell(
                            alignment: Alignment.centerLeft, child: Text(
                            snapshot.data![index].description))
                      ]
                        , height: 20,);
                    }
                    else
                      {
                        return TableViewRow(cells:
                        [
                          TableViewCell(
                              alignment: Alignment.centerLeft, child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                                Text(snapshot.data![index].name),const SizedBox(width: 5,),IconButton( tooltip: AppLocalizations.of(context)!.uninstall, icon: const Icon(Icons.delete,size: 14), onPressed: () async {
                                  bool result = await uninstallLib(snapshot.data![index].name);
                                  if (!context.mounted) return;
                                  if (result) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.libraryUninstalled)));
                                  }
                                  else {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.libraryNotUninstalled)));
                                  }
                                  checkLibs();
                                  setState(() {});
                                  },)])),
                          TableViewCell(alignment: Alignment.center, child: Text(
                              snapshot.data![index].installed_version)),
                          TableViewCell(alignment: Alignment.center, child: Text(
                              snapshot.data![index].location)),
                          TableViewCell(
                              alignment: Alignment.centerLeft, child: Text(
                              snapshot.data![index].description))
                        ]
                          , height: 25, backgroundColor: Colors.limeAccent,);
                      }
                  },
                  growable: false
              );



              return Expanded(
                flex: 6,
                  child:
              ScrollableTableView(
                headers: [
                  AppLocalizations.of(context)!.name,
                  AppLocalizations.of(context)!.version,
                  AppLocalizations.of(context)!.location,
                  AppLocalizations.of(context)!.description
                ].map((label) {
                  return TableViewHeader(
                    label: label,
                    width: (MediaQuery.of(context).size.width-20)/4,
                  );
                }).toList(),
                rows: libraries,
              )
              );
            },
            future: _libList),
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          checkArduinoCLI();
        },
        tooltip: AppLocalizations.of(context)!.refresh,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
