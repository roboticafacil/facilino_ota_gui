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

class EditUser extends StatefulWidget {
  const EditUser({super.key, required this.user});
  final User user;
  @override
  State<EditUser> createState() => EditUserPageState();
}

class EditUserPageState extends State<EditUser> {

  final _editUserFormKey = GlobalKey<FormBuilderState>();
  late User _user;

  @override
  void initState() {
    super.initState();
    _user=widget.user;
  }

  Future<void> updateUserData(Map<String,dynamic> userData) async {
    final http.Response response = await http.post(Uri(scheme: 'https',
        host: 'facilino.webs.upv.es',
        path: '/user.php'), body: {
      'username': widget.user.username,
      'key': widget.user.key,
      'action': 'update',
      'first_name': userData['first_name'].toString(),
      'last_name': userData['last_name'].toString(),
      'lang_id': userData['lang_id'].toString()
    },
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/x-www-form-urlencoded"
        }
    );
    dynamic resp= json.decode(response.body);
    if (resp['result']=="OK")
    {
      _user=widget.user;
      _user.first_name=userData['first_name'].toString();
      _user.last_name=userData['last_name'].toString();
      _user.lang_id=int.parse(userData['lang_id'].toString());
      return;
    }
    else {
    }

  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    List<DropdownMenuItem<int>> languageItems = [
      DropdownMenuItem(
          value: 4,
          child:
          Row(
            children: [
              CachedNetworkImage(
                imageUrl: "https://facilino.webs.upv.es/lang/images/united-kingdom.png",
                placeholder: (context, url) => const CircularProgressIndicator(),
                errorWidget: (context, url, error) => const Icon(Icons.error),
                height: 24,
              ),
              const SizedBox( width: 25),
              Text(AppLocalizations.of(context)!.english),
            ],
          )
      ),
      DropdownMenuItem(
          value: 5,
          child:
          Row(
            children: [
              CachedNetworkImage(
                imageUrl: "https://facilino.webs.upv.es/lang/images/spain.png",
                placeholder: (context, url) => const CircularProgressIndicator(),
                errorWidget: (context, url, error) => const Icon(Icons.error),
                height: 24,
              ),
              const SizedBox( width: 25),
              Text(AppLocalizations.of(context)!.spanish),
            ],
          )
      )
    ];


    return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.editUser, style: const TextStyle(color: Colors.black45,fontWeight: FontWeight.bold)),
        ),
        body:
            Padding(
              padding: const EdgeInsets.all(8.0),
              child:
            FormBuilder(
              key: _editUserFormKey,
              child: Column(
                children: [
                  const SizedBox(height: 10,),
                  FormBuilderTextField(
                      name: 'username',
                      enabled: false,
                      initialValue: widget.user.username,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: AppLocalizations.of(context)!.username,
                        hintText: AppLocalizations.of(context)!.chooseUsername,
                      ),
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                        FormBuilderValidators.maxLength(50)
                      ])
                  ),
                  const SizedBox(height: 10,),
                  FormBuilderTextField(
                      name: 'email',
                      enabled: false,
                      initialValue: widget.user.email,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: AppLocalizations.of(context)!.email,
                        hintText: '${AppLocalizations.of(context)!.emailHint} (${AppLocalizations.of(context)!.mustBeUnique})',
                      ),
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                        FormBuilderValidators.email(),
                        FormBuilderValidators.maxLength(50)
                      ])
                  ),
                  const SizedBox(height: 10,),
                  FormBuilderTextField(
                    name: 'first_name',
                    initialValue: widget.user.first_name,
                    decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: AppLocalizations.of(context)!.firstName,
                        hintText: AppLocalizations.of(context)!.firstNameHint,),
                    validator: FormBuilderValidators.compose([FormBuilderValidators.required(),
                      FormBuilderValidators.maxLength(50)]),
                  ),
                  const SizedBox(height: 10,),
                  FormBuilderTextField(
                    name: 'last_name',
                    initialValue: widget.user.last_name,
                    decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: AppLocalizations.of(context)!.lastName,
                      hintText: AppLocalizations.of(context)!.lastNameHint,),
                    validator: FormBuilderValidators.compose([FormBuilderValidators.required(),
                      FormBuilderValidators.maxLength(50)]),
                  ),
                  const SizedBox(height: 10,),
                  FormBuilderDropdown(name: 'lang_id', decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: AppLocalizations.of(context)!.language,
                      hintText: AppLocalizations.of(context)!.languageHint,
                  ), items: languageItems, initialValue: widget.user.lang_id,),
                  const SizedBox(height: 10,),
                  MaterialButton(
                    color: Theme.of(context).colorScheme.secondary,
                    onPressed: () {
                      // Validate and save the form values
                      if (_editUserFormKey.currentState!.saveAndValidate()) {
                        updateUserData((_editUserFormKey.currentState!.value));
                        //Future(() => updateProjectData((_editProjectFormKey.currentState?.value)!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(AppLocalizations.of(context)!.userUpdated)),
                        );
                        Navigator.pop(context, _user);
                      }
                    },
                    child: Text(AppLocalizations.of(context)!.save),
                  )
                ],
              ),
            ),
            )
    );
  }
}