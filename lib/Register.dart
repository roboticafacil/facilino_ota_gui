
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:username_validator/username_validator.dart';
import 'Login.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});
  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}


class _RegistrationPageState extends State<RegistrationPage> {

  final _registerFormKey = GlobalKey<FormBuilderState>();
  late bool _passwordVisible;

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
            const Text('English'),
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
            const Text('Español'),
            ],
        )
      )
    ];

  @override
  void initState() {
    _passwordVisible = false;
  }

  void goToLogin(BuildContext context, dynamic resp)
  {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(resp["result"].toString())),
    );
    if (resp["status"]=="OK") {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => LoginPage(alreadyLogged: false)));
    }
  }

  Future<dynamic> onUserRegistration(Map<String,dynamic> formData) async {
    final http.Response response = await http.post(Uri(scheme: 'https', host: 'facilino.webs.upv.es',path: '/registration.php'), body: {
      "username": formData['username'].toString(),
      "email": formData['email'].toString(),
      "password": formData['password'].toString(),
      "first_name": formData['first_name'].toString(),
      "last_name": formData['last_name'].toString(),
      "lang_id": formData['lang_id'].toString(),
      "json": "true"
    },
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/x-www-form-urlencoded"
        }
    );
    final dynamic resp = json.decode(response.body);
    debugPrint(resp.toString());
    return resp;
  }

  //

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text(AppLocalizations.of(context)!.registration),
        ),
        body: Center(
          // Center is a layout widget. It takes a single child and positions it
          // in the middle of the parent.
          child:
          FractionallySizedBox(
            widthFactor: 0.5,
            heightFactor: 1,
            child: FormBuilder(
            key: _registerFormKey,
            child:
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>
              [
                Text(AppLocalizations.of(context)!.fillFormRegistration),
                const SizedBox(height: 10,),
                FormBuilderTextField(
                    name: 'username',
                    decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: AppLocalizations.of(context)!.username,
                      hintText: '${AppLocalizations.of(context)!.chooseUsername} (${AppLocalizations.of(context)!.mustBeUnique})',
                    ),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(),
                      FormBuilderValidators.maxLength(50),
                      (val) {
                        if (val!=null)
                        {
                          if (UValidator.validateThis(pattern:RegPattern.basic,username: val))
                          {
                            return null;
                          }
                        }
                        return AppLocalizations.of(context)!.invalidUsername;
                      }
                    ])
                ),
                const SizedBox(height: 10,),
                FormBuilderTextField(
                  name: 'email',
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
                    name: 'password',
                    decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: AppLocalizations.of(context)!.password,
                        hintText: AppLocalizations.of(context)!.passwordHint,
                        suffixIcon: IconButton(
                        icon: Icon(
                          // Based on passwordVisible state choose the icon
                          _passwordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Theme.of(context).primaryColorDark,
                        ),
                        onPressed: () {
                          // Update the state i.e. toogle the state of passwordVisible variable
                          setState(() {
                            _passwordVisible = !_passwordVisible;
                          });
                        },
                      ),
                    ),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(),
                      FormBuilderValidators.maxLength(50)
                    ]),
                    obscureText: !_passwordVisible,
                ),
                const SizedBox(height: 10,),
                FormBuilderTextField(
                    name: 'first_name',
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: AppLocalizations.of(context)!.username,
                      hintText: AppLocalizations.of(context)!.usernameHint,
                    ),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(),
                      FormBuilderValidators.maxLength(100),
                    ])
                ),
                const SizedBox(height: 10,),
                FormBuilderTextField(
                    name: 'last_name',
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: AppLocalizations.of(context)!.lastName,
                      hintText: AppLocalizations.of(context)!.lastNameHint,
                    ),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(),
                      FormBuilderValidators.maxLength(100)
                    ])
                ),
                const SizedBox(height: 10,),
                FormBuilderDropdown(name: 'lang_id', decoration: InputDecoration(labelText: AppLocalizations.of(context)!.language), items: languageItems, initialValue: 4,)
              ],
            ),
          ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            //Save and validate form
            if (_registerFormKey.currentState!.saveAndValidate()) {
              await onUserRegistration((_registerFormKey.currentState!.value)).then((resp) => goToLogin(context,resp));
            }
          },
          tooltip: AppLocalizations.of(context)!.submitRegistration,
          child: const Icon(Icons.send),
        )
    );
  }
}