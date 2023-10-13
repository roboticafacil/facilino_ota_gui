import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'util/ProjectOptions.dart';
import 'util/Project.dart';
import 'util/User.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class EditProject extends StatefulWidget {
  const EditProject({super.key, required this.user,required this.project, required this.projectOptions});
  final User user;
  final Project project;
  final ProjectOptions projectOptions;



  @override
  State<EditProject> createState() => EditProjectPageState();
}

class EditProjectPageState extends State<EditProject> {


  final _editProjectFormKey = GlobalKey<FormBuilderState>();

  bool isFacilinoOTA=false;

  List<DropdownMenuItem<int>> boardItems = [];
  //List<int> boardIDs=[];
  List<DropdownMenuItem<int>> versionItems = [];
  //List<int> versionIDs=[];
  List<DropdownMenuItem<int>> filterItems = [];
  //List<int> filterIDs=[];
  List<DropdownMenuItem<int>> languageItems = [];
  //List<int> languageIDs=[];

  void buildProjectOptionsMenuItems()
  {
    //boardIDs.clear();
    boardItems.clear();
    for (var board in widget.projectOptions.boards) {
      int id = int.parse(board["id"]);
      //boardIDs.add(id);
      boardItems.add(DropdownMenuItem(
          value: id, child:
      Row(
        children: [
          CachedNetworkImage(
            imageUrl: "https://facilino.webs.upv.es/assets/images/${board["image"]}",
            placeholder: (context, url) => const CircularProgressIndicator(),
            errorWidget: (context, url, error) => const Icon(Icons.error),
            height: 150,
          ),
          const SizedBox( width: 25),
          Text(board["name"]),
        ],
      )
      ));
    }

    //versionIDs.clear();
    versionItems.clear();
    for (var version in widget.projectOptions.versions) {
      int id = int.parse(version["id"]);
      //versionIDs.add(id);
      versionItems.add(DropdownMenuItem(
          value: id, child:
      Row(
        children: [
          CachedNetworkImage(
            imageUrl: "https://facilino.webs.upv.es/assets/images/${version["image"]}",
            placeholder: (context, url) => const CircularProgressIndicator(),
            errorWidget: (context, url, error) => const Icon(Icons.error),
            height: 150,
          ),
          const SizedBox( width: 25),
          Text(version["name"]),
        ],
      )));
    }

    //filterIDs.clear();
    filterItems.clear();
    for (var filter in widget.projectOptions.filters) {
      int id = int.parse(filter["id"]);
      //filterIDs.add(id);
      filterItems.add(DropdownMenuItem(
          value: id, child:
      Row(
        children: [
          CachedNetworkImage(
            imageUrl: "https://facilino.webs.upv.es/assets/images/${filter["image"]}",
            placeholder: (context, url) => const CircularProgressIndicator(),
            errorWidget: (context, url, error) => const Icon(Icons.error),
            height: 150,
          ),
          const SizedBox( width: 25),
          Text(filter["name"]),
        ],
      )
      ));
    }

    //languageIDs.clear();
    languageItems.clear();
    for (var language in widget.projectOptions.languages) {
      int id = int.parse(language["id"]);
      //languageIDs.add(id);
      languageItems.add(DropdownMenuItem(
          value: id, child:
      Row(
        children: [
          CachedNetworkImage(
            imageUrl: "https://facilino.webs.upv.es/lang/images/${language["image"]}",
            placeholder: (context, url) => const CircularProgressIndicator(),
            errorWidget: (context, url, error) => const Icon(Icons.error),
            height: 24,
          ),
          const SizedBox( width: 25),
          Text(language["name"]),
        ],
      )
      ));
    }
  }

  @override
  void initState() {
    super.initState();
    buildProjectOptionsMenuItems();
  }


  Future<void> updateProjectData(Map<String,dynamic> projectData) async {
    Map<String, String> body;
    if (projectData['server']!=null) {
      if (!widget.user.invited) {
        body = {
          'username': widget.user.username,
          'key': widget.user.key,
          'action': 'update',
          'proj_id': widget.project.id.toString(),
          'name': projectData['name'].toString(),
          'proc_id': projectData['proc_id'].toString(),
          'version_id': projectData['version_id'].toString(),
          'filter_id': projectData['filter_id'].toString(),
          'lang_id': projectData['lang_id'].toString(),
          'server': projectData['server'].toString(),
          'device': projectData['device'].toString()
        };
      }
      else
        {
          body = {
            'user_id': widget.user.id.toString(),
            'invited': 'true',
            'action': 'update',
            'proj_id': widget.project.id.toString(),
            'name': projectData['name'].toString(),
            'proc_id': projectData['proc_id'].toString(),
            'version_id': projectData['version_id'].toString(),
            'filter_id': projectData['filter_id'].toString(),
            'lang_id': projectData['lang_id'].toString(),
            'server': projectData['server'].toString(),
            'device': projectData['device'].toString()
          };
        }
    }
    else
      {
        if (!widget.user.invited) {
          body = {
            'username': widget.user.username,
            'key': widget.user.key,
            'action': 'update',
            'proj_id': widget.project.id.toString(),
            'name': projectData['name'].toString(),
            'proc_id': projectData['proc_id'].toString(),
            'version_id': projectData['version_id'].toString(),
            'filter_id': projectData['filter_id'].toString(),
            'lang_id': projectData['lang_id'].toString(),
          };
        }
        else
          {
            body = {
              'user_id': widget.user.id.toString(),
              'invited': 'true',
              'action': 'update',
              'proj_id': widget.project.id.toString(),
              'name': projectData['name'].toString(),
              'proc_id': projectData['proc_id'].toString(),
              'version_id': projectData['version_id'].toString(),
              'filter_id': projectData['filter_id'].toString(),
              'lang_id': projectData['lang_id'].toString(),
            };
          }
      }
    final http.Response response = await http.post(Uri(scheme: 'https',
        host: 'facilino.webs.upv.es',
        path: '/dashboard.php'), body: body,
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/x-www-form-urlencoded"
        }
    );
    dynamic resp= json.decode(response.body);
    if (resp['result']=="OK")
      {
        return;
      }
    else {
    }

  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.editProject, style: const TextStyle(color: Colors.black45,fontWeight: FontWeight.bold)),
    ),
     body:
     FormBuilder(
       key: _editProjectFormKey,
       child: Column(
         children: [
           const SizedBox(height: 10,),
           FormBuilderTextField(
             name: 'name',
             initialValue: widget.project.name,
             decoration: InputDecoration(labelText: AppLocalizations.of(context)!.projectName),
             validator: FormBuilderValidators.compose([FormBuilderValidators.required(),
               FormBuilderValidators.maxLength(50)]),
           ),
           const SizedBox(height: 10,),
           widget.projectOptions.boardIDs.contains(widget.project.proc_id)? FormBuilderDropdown(name: 'proc_id', decoration: InputDecoration(labelText: AppLocalizations.of(context)!.hardware), items: boardItems, initialValue: widget.project.proc_id,):Container(),
           const SizedBox(height: 10,),
           widget.projectOptions.versionIDs.contains(widget.project.version_id)? FormBuilderDropdown(name: 'version_id', decoration: InputDecoration(labelText: AppLocalizations.of(context)!.version), items: versionItems, initialValue: widget.project.version_id,onChanged: (val) {
             // do the necessary calculations with your value
             isFacilinoOTA=false;
             if (val!=null)
               {
                 if (val==3)
                   {
                     isFacilinoOTA=true;
                   }
               }
             setState(() {

             });
           },):Container(),
           const SizedBox(height: 10,),
           widget.projectOptions.filterIDs.contains(widget.project.filter_id)? FormBuilderDropdown(name: 'filter_id', decoration: InputDecoration(labelText: AppLocalizations.of(context)!.blockFilter), items: filterItems, initialValue: widget.project.filter_id):Container(),
           const SizedBox(height: 10,),
           widget.projectOptions.langIDs.contains(widget.project.lang_id)? FormBuilderDropdown(name: 'lang_id', decoration: InputDecoration(labelText:AppLocalizations.of(context)!.language), items: languageItems, initialValue: widget.project.lang_id):Container(),
           isFacilinoOTA? const SizedBox(height: 10,): Container(),
           isFacilinoOTA? FormBuilderTextField(
              name: 'server',
              decoration: InputDecoration(labelText:AppLocalizations.of(context)!.serverIP),
              validator: FormBuilderValidators.ip(),
            ): Container(),
            isFacilinoOTA? const SizedBox(height: 10,): Container(),
            isFacilinoOTA? FormBuilderTextField(
              name: 'device',
              decoration: InputDecoration(labelText: AppLocalizations.of(context)!.deviceIP),
              validator: FormBuilderValidators.ip(),
            ): Container(),
           const SizedBox(height: 10,),
           MaterialButton(
             color: Theme.of(context).colorScheme.secondary,
             onPressed: () {
               // Validate and save the form values
               if (_editProjectFormKey.currentState!.saveAndValidate()) {
                 //await updateProjectData((_editProjectFormKey.currentState?.value)!)
                 updateProjectData((_editProjectFormKey.currentState!.value));
                 //Future(() => updateProjectData((_editProjectFormKey.currentState?.value)!));
                 ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(content: Text(AppLocalizations.of(context)!.projectUpdated)),
                 );
                 Navigator.pop(context, true);
               }
             },
             child: Text(AppLocalizations.of(context)!.save),
           )
         ],
       ),
     )
    );
  }
}
