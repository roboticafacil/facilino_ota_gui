import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:http/http.dart' as http;
import 'Login.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PasswordRecoveryPage extends StatefulWidget {
  const PasswordRecoveryPage({super.key});

  @override
  State<PasswordRecoveryPage> createState() => _PasswordRecoveryPageState();
}

class _PasswordRecoveryPageState extends State<PasswordRecoveryPage> {

  TextEditingController email=TextEditingController();
  final _resetPasswordFormKey = GlobalKey<FormBuilderState>();

  @override
  void initState() {
    super.initState();
  }

  void goToLogin(BuildContext context, dynamic resp)
  {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(resp["result"].toString())),
    );
    Navigator.pushReplacement(context,MaterialPageRoute(builder: (context) => LoginPage(alreadyLogged: false)));
  }

  Future<dynamic> onPasswordRecovery(Map<String,dynamic> formData) async {
    final http.Response response = await http.post(Uri(scheme: 'https', host: 'facilino.webs.upv.es',path: '/lost-password.php'), body: {
      "email": formData['email'].toString(),
      "json": "true"
    },
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/x-www-form-urlencoded"
        }
    );
    final dynamic resp = json.decode(response.body);
    return resp;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text(AppLocalizations.of(context)!.passwordRecovery),
        ),
        body: Center(
          // Center is a layout widget. It takes a single child and positions it
          // in the middle of the parent.
          child:
          FractionallySizedBox(
            widthFactor: 0.5,
            heightFactor: 1,
            child:
            FormBuilder(
              key: _resetPasswordFormKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>
                [
                Text(AppLocalizations.of(context)!.passwordRecoveryMsg),
                const SizedBox(height: 10,),
                FormBuilderTextField(
                  name: 'email',
                  decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: AppLocalizations.of(context)!.email,
                      hintText: AppLocalizations.of(context)!.emailHint
                  ),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(),
                    FormBuilderValidators.email(),
                    FormBuilderValidators.maxLength(50)
                  ]),
                ),
              ],
            ),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            if (_resetPasswordFormKey.currentState!.saveAndValidate()) {
              //await updateProjectData((_editProjectFormKey.currentState?.value)!)
              await onPasswordRecovery(
                  (_resetPasswordFormKey.currentState!.value)).then((resp) =>
                  goToLogin(context, resp));
            }
          },
          tooltip: AppLocalizations.of(context)!.sendPasswordRecoveryMail,
          child: const Icon(Icons.email),
        )
    );
  }
}