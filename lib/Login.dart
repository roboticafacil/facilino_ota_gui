

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:http/http.dart' as http;
import 'package:loading_indicator/loading_indicator.dart';
import 'package:username_validator/username_validator.dart';
import 'util/User.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'facilino_settings.dart';
import 'facilino_icons.dart';

import 'dashboard.dart';

class LoginPage extends StatefulWidget {
  final bool alreadyLogged;
  const LoginPage({super.key, required this.alreadyLogged});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final storage = const FlutterSecureStorage();

  final _loginFormKey = GlobalKey<FormBuilderState>();
  late bool _passwordVisible;
  Future<String> _username=Future(() => '');
  String _initialUserName='';

  Future<void> getUserName() async {
    final usr = await storage.read(key: "KEY_USERNAME");
    debugPrint('Retrieved $usr in KEY_USERNAME');
    _username=Future(()=> usr.toString());
    _initialUserName=(usr!=null)? usr.toString(): '';
  }

  @override
  void initState() {
    super.initState();
    _passwordVisible = false;
    getUserName();
  }

  void goToDashboard(BuildContext context, dynamic resp)
  {
    if (resp["result"]=="OK") {
      User user = User(username: resp["username"],id: resp["id"],key: resp["key"], email: resp['email'], first_name: resp['first_name'], last_name: resp['last_name'],lang_id: resp['lang_id'], invited: resp['invited']);
      Navigator.pushReplacement(context,MaterialPageRoute(builder: (context) => Dashboard(user: user)));
    }
  }

  Future<dynamic> onLogin(Map<String,dynamic> formData) async {
    final http.Response response = await http.post(Uri(scheme: 'https', host: 'facilino.webs.upv.es',path: '/login.php'), body: {
      "username": formData['username'].toString(),
      "password": formData['password'].toString(),
      "json": "true"
    },
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/x-www-form-urlencoded"
        }
    );
    debugPrint('Storing ${formData['username'].toString()} in KEY_USERNAME');
    await storage.write(key: "KEY_USERNAME", value: formData['username'].toString());
    final dynamic resp = json.decode(response.body);
    return resp;
  }

  Future<dynamic> onLoginInvited() async {
    final http.Response response = await http.post(Uri(scheme: 'https', host: 'facilino.webs.upv.es',path: '/login.php'), body: {
      "json": "true",
      "invited": "true"
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
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(AppLocalizations.of(context)!.login),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child:
        FractionallySizedBox(
          widthFactor: 0.6,
          heightFactor: 1,
          child:
              FutureBuilder<String>(
                builder: (BuildContext context, AsyncSnapshot<String> snapshot){
                  if (!snapshot.hasData) {
                    return const Center(child: LoadingIndicator(indicatorType: Indicator.ballPulse,strokeWidth: 4.0));
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text(AppLocalizations.of(context)!.somethingWentWrong));
                  }
                  return FormBuilder(
                    key: _loginFormKey,
                    child:
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Image.file(File('assets/facilino.png'),),
                        FormBuilderTextField(
                            name: 'username',
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              labelText: AppLocalizations.of(context)!.username,
                              hintText: AppLocalizations.of(context)!.usernameHint,
                            ),
                            initialValue: _initialUserName,
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
                                color: Theme
                                    .of(context)
                                    .primaryColorDark,
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
                        const SizedBox(height: 5,),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            InkWell(
                              child: Text(AppLocalizations.of(context)!.notRegisteredYet,
                                  style: const TextStyle(fontSize: 10,
                                      color: Colors.blue,
                                      fontStyle: FontStyle.italic)),
                              onTap: () =>
                                  Navigator.pushNamed(context, '/register'),
                            ),
                            InkWell(
                              child: Text(AppLocalizations.of(context)!.passwordRecovery,
                                  style: const TextStyle(fontSize: 10,
                                      color: Colors.blue,
                                      fontStyle: FontStyle.italic)),
                              onTap: () =>
                                  Navigator.pushNamed(
                                      context, '/password_recovery'),),
                          ],
                        )
                      ],
                    ),
                  );
                },
                future: _username,
              )
        ),
      ),
      floatingActionButton:
          Wrap(
            direction: Axis.vertical,
            children: [
              Container(
                margin: const EdgeInsets.all(10),
                child:

          FloatingActionButton(
            heroTag: "btnLogin",
            onPressed: () async {
              if (_loginFormKey.currentState!.saveAndValidate()) {
                await onLogin((_loginFormKey.currentState!.value)).then((
                    resp) => goToDashboard(context, resp));
              }
            },
            tooltip: AppLocalizations.of(context)!.login,
            child: const Icon(Icons.login),
          ),),
              Container(
                margin:EdgeInsets.all(10),
                child:
                FloatingActionButton(
                  heroTag: "btnInivited",
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context)!.loginToKeepChanges)),
                  );
                  await onLoginInvited().then((
                      resp) => goToDashboard(context, resp));
                  //User user = User(username: 'invited',id: 0,key: '', email: '', first_name: 'Invited', last_name: 'User',lang_id: 4);
                  //Navigator.pushReplacement(context,MaterialPageRoute(builder: (context) => Dashboard(user: user)));
                },
                tooltip: AppLocalizations.of(context)!.tryFacilino,
                child: const Icon(Icons.rocket_launch),
              ),
              ),
              const SizedBox(
                height: 20,
              )
          ],
        ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }
}