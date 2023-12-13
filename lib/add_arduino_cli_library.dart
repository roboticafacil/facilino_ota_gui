import 'dart:io';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:scrollable_table_view/scrollable_table_view.dart';
import 'util/NewLibrary.dart';
import 'package:flutter/material.dart';
import 'util/ArduinoCLI.dart';
import 'package:process_run/shell.dart' as ShellProcessRun;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AddArduinoCLILibrary extends StatefulWidget {
  const AddArduinoCLILibrary({super.key});

  @override
  State<AddArduinoCLILibrary> createState() => AddArduinoCLILibraryState();
}

class AddArduinoCLILibraryState extends State<AddArduinoCLILibrary> {
  //final _arduinoCLIFormKey = GlobalKey<FormBuilderState>();

  late Future<List<NewLibrary>> _libList=Future<List<NewLibrary>>(()=> []);
  final textController = TextEditingController();

  Future<bool> installLib(String name) async {
    String arduino_cli_exe = '';
    String arduinoCliDir = ArduinoCLI.getArduinoCLIDir();
    arduino_cli_exe = ArduinoCLI.getArduinoCLIPath();
    if (await Directory(arduinoCliDir).exists()) {
      if (name.isNotEmpty) {
        String cmd = '$arduino_cli_exe lib install $name';
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

  updateLibList(String text) async{
    String arduino_cli_exe = '';
    String arduinoCliDir = ArduinoCLI.getArduinoCLIDir();
    arduino_cli_exe = ArduinoCLI.getArduinoCLIPath();

    if (await Directory(arduinoCliDir).exists()) {
      if (text.isNotEmpty) {
        String cmd = '$arduino_cli_exe lib search $text';
        try {
          List<ProcessResult> res = await shell.run(cmd);
          //debugPrint(res.outText.toString());
          List<NewLibrary> libList = [];
          int count = 0;
          int num_libs = res.outLines.length - 2;

          for (var r in res.outLines) {
            if (r.contains("Name:")) {
              List<String> name = r.split('Name: ');
              libList.add(NewLibrary(name: name[1].replaceAll('"', ''),  available_version: '', author: '', description: '',architecture: '', maintainer: '', full_description: '', url: ''));
            }
            if (r.contains("Versions:")) {
              List<String> versions = r.split('Versions: ');
              List<String> version = versions[1].split(',');
              libList.last.available_version=version.last.replaceAll(']', '').replaceAll('[','');
            }
            if (r.contains("Author:")) {
              List<String> authors = r.split('Author: ');
              libList.last.author=authors[1];
            }
            if (r.contains("Sentence:")) {
              List<String> sentence = r.split('Sentence: ');
              libList.last.description=sentence[1];
            }
            if (r.contains("Architecture:")) {
              List<String> arch = r.split('Architecture: ');
              libList.last.architecture=arch[1];
            }
            if (r.contains("Maintainer:")) {
              List<String> maintainers = r.split('Maintainer: ');
              libList.last.maintainer=maintainers[1];
            }
            if (r.contains("Paragraph:")) {
              List<String> par = r.split('Paragraph: ');
              libList.last.full_description=par[1];
            }
            if (r.contains("Website:")) {
              List<String> url = r.split('Website: ');
              libList.last.url=url[1];
            }

          }
          debugPrint(libList.length.toString());
          _libList = Future<List<NewLibrary>>(() => libList);
          await _libList;
          setState(() {
          });
          //debugPrint(res.outText);
        } on ShellProcessRun.ShellException catch (error) {
          debugPrint(error.toString());
        }
      }
      else
        {
          await _libList;
          setState(() {
          });
        }
    }
  }

  @override
  void initState() {
    super.initState();
    updateLibList('');
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.addCLILibrary,
            style:
            const TextStyle(color: Colors.black45, fontWeight: FontWeight.bold)),
      ),
      body:
            FutureBuilder<List<NewLibrary>>(
                builder:
                    (BuildContext context, AsyncSnapshot<List<NewLibrary>> snapshot) {

                  if (!snapshot.hasData) {
                    return const Center(child: LoadingIndicator(indicatorType: Indicator.ballPulse,strokeWidth: 4.0));
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text(AppLocalizations.of(context)!.somethingWentWrong));
                  }

                  final List<Widget> libraries=List<Widget>.generate(snapshot.data!.length,
                          (index){
                        return Card(
                          elevation: 0,
                          color: Theme.of(context).colorScheme.background,
                          child: SizedBox(
                              width: MediaQuery.of(context).size.width,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 5,),
                                  Center(child: Text(snapshot.data![index].name)),
                                  const SizedBox(height: 5),
                                  Row(children: [ Text(AppLocalizations.of(context)!.author_), const SizedBox(width: 10,),Expanded(child: Text(snapshot.data![index].author)),]),
                                  const SizedBox(height: 5),
                                  Row(children: [ Text(AppLocalizations.of(context)!.maintainer_), const SizedBox(width: 10,),Expanded(child: Text(snapshot.data![index].maintainer)),]),
                                  const SizedBox(height: 5),
                                  Row(children: [ Text(AppLocalizations.of(context)!.description_), const SizedBox(width: 10,),Expanded(child: Text(snapshot.data![index].full_description,maxLines: 10, overflow: TextOverflow.ellipsis,)),]),
                                  const SizedBox(height: 5),
                                  Row(children: [ Text(AppLocalizations.of(context)!.website_), const SizedBox(width: 10,),Text(snapshot.data![index].url),]),
                                  const SizedBox(height: 5),
                                  Row(children: [ Text(AppLocalizations.of(context)!.version_), const SizedBox(width: 10,),Text(snapshot.data![index].available_version),]),
                                  const SizedBox(height: 5),
                                  Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: <Widget>[
                                          Transform.translate(
                                            offset: const Offset(-5,-10),
                                            child: FloatingActionButton(
                                              heroTag: 'addLibBtn${index}',
                                      onPressed: () async {
                                        debugPrint('clicked!');
                                        bool result = await installLib(snapshot.data![index].name);
                                        if (!context.mounted) return;
                                        if (result) {
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.libraryInstalled)));
                                          Navigator.pop(context);
                                        }
                                        else {
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.libraryNotInstalled)));
                                        }
                                        },
                                      child: const Icon(Icons.add))
                                          )
                                        ]
                                  )
                                ],
                              )
                          )
                        );
                      },
                      growable: false
                  );

                  return SafeArea(
                    child:
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Padding(padding: const EdgeInsets.symmetric(horizontal: 8,vertical: 16),
                        child:
                        Row(
                          children: [
                            Flexible(child:
                        TextField(
                          decoration: InputDecoration(border: const OutlineInputBorder(),
                          hintText: AppLocalizations.of(context)!.searchText),
                          controller: textController,
                        )),
                            IconButton(
                                /*onPressed: () {

                              setState(() {});
                              },*/
                              icon: const Icon (Icons.search), onPressed: () { updateLibList(textController.text); },)
                          ],
                        ),
                        ),
                    Flexible(child:
                    SingleChildScrollView(
                      child: Column(
                        children: libraries,
                      ),
                    ),
                    ),
                      ]
                    )
                  );
                },
                future: _libList),
    );
  }
}
