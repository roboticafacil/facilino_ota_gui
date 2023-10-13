import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:facilino_ota_gui/edituser.dart';
import 'package:facilino_ota_gui/serialconsole.dart';
import 'util/Board.dart';
import 'package:file_picker/file_picker.dart';
import 'facilino_settings.dart';
import 'facilino_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:loading_indicator/loading_indicator.dart';
import 'newproject.dart';
import 'util/ArduinoCLI.dart';
import 'util/ProjectOptions.dart';
import 'package:window_manager/window_manager.dart';
import 'Login.dart';
import 'editproject.dart';
import 'util/Project.dart';
import 'util/User.dart';
import 'dart:ui';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:process_run/shell.dart' as ShellProcessRun;
import 'dart:convert' as convert;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tuple/tuple.dart';

enum DownloadMessages{NO_MESSAGE,DOWNLOADED,ERROR}

class Dashboard extends StatefulWidget {
  const Dashboard({super.key, required this.user});
  final User user;

  @override
  State<Dashboard> createState() => DashboardPageState();
}

class DashboardPageState extends State<Dashboard> {

  String code='No code yet';

  final storage = const FlutterSecureStorage();

  late Future<List<Project>> projects = Future(() => <Project>[]);

  ProjectOptions projectOptions=ProjectOptions(boards: [], versions: [], filters: [], languages: []);

  late Future<HttpServer> server;

  late Future<List<Board>> _boardList=Future<List<Board>>(()=> []);

  late User _user;

  String selected_port='';

  String decodeUTF8(String inp)
  {
    int sequenceState=0;
    List<int> rr=<int>[];
    rr.add(60);
    rr.add(112);
    rr.add(62);
    for (var r in inp.runes)
    {
      if ((sequenceState==0)&&(r==10))
      {
        sequenceState=1;
      }
      else if ((sequenceState==1)&&(r==27))
      {
        sequenceState=2;
      }
      else if ((sequenceState==2)&&(r==109))
      {
        sequenceState=0;
        rr.add(60);
        rr.add(47);
        rr.add(112);
        rr.add(62);
        rr.add(60);
        rr.add(112);
        rr.add(62);
      }
      else if ((sequenceState==0)&&(r==27))
      {
        sequenceState=3;
      }
      else if ((sequenceState==3)&&(r==109))
      {
        sequenceState=0;
        rr.add(38);
        rr.add(101);
        rr.add(109);
        rr.add(115);
        rr.add(112);
        rr.add(59);
      }
      else if (sequenceState==0)
      {
        rr.add(r);
      }
    }
    rr.add(60);
    rr.add(47);
    rr.add(112);
    rr.add(62);
    String out=utf8.decode(rr);
    return out;
  }

  Future<Response> clientRequest(Request request)
  async {

    String path = request.url.path;
    //debugPrint(path);
    Response resp=Response.badRequest(body: jsonEncode({"result": 'Bad request'}));
    String outText = '';
    String arduino_cli_exe=ArduinoCLI.getArduinoCLIPath();

    if (path.contains('usb_upload'))
    {
      final String query = await request.readAsString();
      //debugPrint(query);
      Map queryParams = jsonDecode(query);
      code = queryParams["code"].toString();
      String compilationFlags = queryParams["compilation_flags"].toString();
      String user = queryParams["user"].toString();

      Directory tempDir = await getTemporaryDirectory();
      tempDir=tempDir.createTempSync("${user}_");
      String tempPath = tempDir.path;
      String fileName = tempDir.path.substring(tempPath.lastIndexOf("\\")+1);
      final file = File('$tempPath\\$fileName.ino');
      String filepath=file.path;
      String myCode = code;
      file.writeAsString(myCode);

      if (queryParams["action"].toString().contains("upload")) {
        String port = queryParams["port"].toString();
        String cmd1='';
        List<ProcessResult> result1;
        List<ProcessResult> result2;
        outText='<p>';
        try {
          cmd1='$arduino_cli_exe compile --fqbn $compilationFlags $filepath';
          resp=Response.ok(jsonEncode({"result": outText,"command": cmd1}),context: {"shelf.io.buffer_output": false});
          result1 = await shell.run(cmd1);
          for (var element in result1) {
            outText+=decodeUTF8(element.outText);
            resp=Response.ok(jsonEncode({"result": outText,"command": cmd1}),context: {"shelf.io.buffer_output": false});
          }
          outText+='</p><p>';
          String cmd2='';

          try {
            cmd2='$arduino_cli_exe upload -p $port --fqbn $compilationFlags $filepath';
            result2 = await shell.run(cmd2);
            for (var element in result2) {
              outText+=decodeUTF8(element.outText);
              resp=Response.ok(jsonEncode({"result": outText,"command": cmd2}),context: {"shelf.io.buffer_output": false});
            }
            String cmd='<p>$cmd1</p><p>$cmd2</p>';
            outText+='</p><p>Done!</p>';
            resp=Response.ok(jsonEncode({"result": outText,"command": cmd}));
          } on ShellProcessRun.ShellException catch (error) {
            // We might get a shell exception
            outText+=decodeUTF8(error.result!.stderr);
            String cmd='<p>$cmd1</p><p>$cmd2</p>';
            resp=Response.ok(jsonEncode({"result": outText,"command": cmd}));
          }
        } on ShellProcessRun.ShellException catch (error) {
          // We might get a shell exception
          outText+=decodeUTF8(error.result!.stderr);
          Response.ok(jsonEncode({"result": outText,"command": cmd1}));
        }
      }
      else if (queryParams["action"].toString().contains("compile")) {
        String cmd='$arduino_cli_exe compile --fqbn $compilationFlags $filepath';
        try {
          List<ProcessResult> result = await shell.run(cmd);
          //debugPrint(result.length.toString());
          for (var element in result) {
            outText+=decodeUTF8(element.outText);
          }
          //debugPrint(outText);
          resp=Response.ok(jsonEncode({"result": outText,"command": cmd}));

        } on ShellProcessRun.ShellException catch (error) {
          // We might get a shell exception
          outText+=decodeUTF8(error.result!.stderr);
          resp=Response.ok(jsonEncode({"result": outText,"command": cmd}));
        }
        //tempDir.delete(recursive: true);
      }
    }
    else if (path.startsWith("ota_upload"))
    {
      //code = queryParams["code"].toString();
      resp=Response.ok('ota_upload');
    }
    else if (path.startsWith("list_ports"))
    {
      //code = Future<String>(()=> 'List ports request');
      String cmd='$arduino_cli_exe board list';
      try {
        List<String> ports=<String>[];
        List<ProcessResult> result = await shell.run(cmd);
        for (var element in result) {
          bool first=true;
          for (var line in element.outText.split('\n'))
          {
            if (!first)
            {
              String port=line.split(" ").first;
              if (port.isNotEmpty) {
                ports.add(port);
              }
            }
            else
            {
              first=false;
            }
          }
        }
        resp=Response.ok(jsonEncode({"ports": ports}),headers: <String, String>{"Access-Control-Allow-Origin": "*",'ContentType': 'application/json; charset=UTF-8'});
      } on ShellProcessRun.ShellException catch (_) {
        // We might get a shell exception
        resp=Response.ok(jsonEncode({"ports": <String>[]}),headers: <String, String>{"Access-Control-Allow-Origin": "*",'ContentType': 'application/json; charset=UTF-8'});
      }
    }
    else
    {
      resp=Response.ok('URL not supported');
    }
    setState(() {
    });
    return resp;
  }

  Future<HttpServer> createServer(){
    final headers = {
      'Access-Control-Allow-Origin': '*',
      'Content-Type': 'application/json;'
    };
    var handler =
    const Pipeline().addMiddleware(corsHeaders(headers: headers)).addHandler(clientRequest);
    return shelf_io.serve(handler, 'localhost', 4000);
  }

  List<dynamic> boardsDefault= [{"id": "1", "name": "Arduino Nano","image": 'ArduinoNano.jpg'}];
  List<dynamic> versionsDefault= [{"id": "1", "name": "Facilino","image": 'facilino.png'}];
  List<dynamic> filtersDefault= [{"id": "1", "name": "Generic Project","image": 'advanced_electronics.jpg'}];
  List<dynamic> languagesDefault= [{"id": "4", "name": "English"}];

  void getProjectOptions() async {
    var url = Uri.https('facilino.webs.upv.es', '/project_options.php');
    var response = await http.get(url);
    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse = convert.jsonDecode(response.body);
      List<dynamic> boards = jsonResponse["boards"] != null?jsonResponse["boards"]! : boardsDefault;
      List<dynamic> versions = ((jsonResponse["versions"] != null)&&(widget.user.id!=0))?jsonResponse["versions"]! : versionsDefault;
      List<dynamic> filters = jsonResponse["filters"] != null?jsonResponse["filters"]! : filtersDefault;
      List<dynamic> languages = jsonResponse["languages"] != null?jsonResponse["languages"]! : languagesDefault;
      projectOptions = await Future(() => ProjectOptions(boards: boards, versions: versions,filters: filters,languages: languages));
    }
  }

  Future<void> editUser(User user) async {
    User? newUser = await Navigator.push(context,MaterialPageRoute(builder: (context) => EditUser(user: user)));
    if (newUser!=null)
      {
        _user=newUser;
        await Future.delayed(const Duration(seconds: 1));
        setState(() {});
      }
  }

  Future<void> getProjectsData() async {
    http.Response response;
    if (!widget.user.invited) {
      response = await http.post(Uri(scheme: 'https',
          host: 'facilino.webs.upv.es',
          path: '/dashboard.php'), body: {
        'username': widget.user.username,
        'key': widget.user.key
      },
          headers: {
            "Accept": "application/json",
            "Content-Type": "application/x-www-form-urlencoded"
          }
      );
    }
    else{
      response = await http.post(Uri(scheme: 'https',
          host: 'facilino.webs.upv.es',
          path: '/dashboard.php'), body: {
        'invited': "true",
        'user_id': widget.user.id.toString()
      },
          headers: {
            "Accept": "application/json",
            "Content-Type": "application/x-www-form-urlencoded"
          }
      );
    }
    dynamic resp = json.decode(response.body);
      //debugPrint(resp.toString());
      List<Project> p = <Project>[];
      for (var r in resp) {
        p.add(Project(name: r["name"],
            id: int.parse(r["id"]),
            proc_id: int.parse(r["proc_id"]),
            version_id: int.parse(r["version_id"]),
            filter_id: int.parse(r["filter_id"]),
            lang_id: int.parse(r["lang_id"]),
            init_code: ''));
      }
      projects = Future<List<Project>>(() => p);
      await projects;
      setState(() {});
  }

  Future<void> newProject(User user, ProjectOptions projectOptions) async {
    Map<String,dynamic>? projectData = await Navigator.push(context,MaterialPageRoute(builder: (context) => NewProject(user: user, projectOptions: projectOptions)));
    if (projectData!=null) {
      await Future.delayed(const Duration(seconds: 1));
      await getProjectsData();
      /*if (widget.user.id!=0) {
        await getProjectsData();
      }
      else
        {
          addProjectData(projectData);
        }*/
    }
  }

  Future<void> editProject(User user, Project project, ProjectOptions projectOptions) async {
    bool? refresh = await Navigator.push(context,MaterialPageRoute(builder: (context) => EditProject(user: user, project: project, projectOptions: projectOptions)));
    if (refresh!=null) {
      if (refresh) {
        await Future.delayed(const Duration(seconds: 1));
        await getProjectsData();
      }
    }
  }

  Future<void> duplicateProject(int proj_id) async {
    http.Response response;
    if (!widget.user.invited) {
      response = await http.post(Uri(scheme: 'https',
          host: 'facilino.webs.upv.es',
          path: '/dashboard.php'), body: {
        'username': widget.user.username,
        'key': widget.user.key,
        'action': 'duplicate',
        'id': proj_id.toString(),
      },
          headers: {
            "Accept": "application/json",
            "Content-Type": "application/x-www-form-urlencoded"
          }
      );
    }
    else
      {
        response = await http.post(Uri(scheme: 'https',
            host: 'facilino.webs.upv.es',
            path: '/dashboard.php'), body: {
          'action': 'duplicate',
          'invited': 'true',
          'user_id': widget.user.id.toString(),
          'id': proj_id.toString(),
        },
            headers: {
              "Accept": "application/json",
              "Content-Type": "application/x-www-form-urlencoded"
            }
        );
      }
    dynamic resp= json.decode(response.body);
    List<Project> p = <Project>[];
    for (var r in resp)
    {
      p.add(Project(name: r["name"],id: int.parse(r["id"]), proc_id: int.parse(r['proc_id']),version_id: int.parse(r['version_id']),filter_id: int.parse(r['filter_id']),lang_id: int.parse(r['lang_id']),init_code: ''));
    }
    projects= Future<List<Project>> (() => p);
    await projects;
    setState(() {});
  }

  Future<void> deleteProject(int proj_id) async {
    http.Response response;
    if (!widget.user.invited) {
      response = await http.post(Uri(scheme: 'https',
          host: 'facilino.webs.upv.es',
          path: '/dashboard.php'), body: {
        'username': widget.user.username,
        'key': widget.user.key,
        'action': 'delete',
        'id': proj_id.toString()
      },
          headers: {
            "Accept": "application/json",
            "Content-Type": "application/x-www-form-urlencoded"
          }
      );
    }
    else
      {
        response = await http.post(Uri(scheme: 'https',
            host: 'facilino.webs.upv.es',
            path: '/dashboard.php'), body: {
          'action': 'delete',
          'invited': 'true',
          'user_id': widget.user.id.toString(),
          'id': proj_id.toString()
        },
            headers: {
              "Accept": "application/json",
              "Content-Type": "application/x-www-form-urlencoded"
            }
        );
      }
    dynamic resp= json.decode(response.body);

    List<Project> p = <Project>[];
    for (var r in resp)
    {
      p.add(Project(name: r["name"],id: int.parse(r["id"]), proc_id: int.parse(r['proc_id']),version_id: int.parse(r['version_id']),filter_id: int.parse(r['filter_id']),lang_id: int.parse(r['lang_id']),init_code: ''));
    }
    projects= Future<List<Project>> (() => p);
    await projects;
    setState(() {
    });
  }

  

  Future<Tuple2<DownloadMessages,String>> downloadArduinoProject(int proj_id) async {
    http.Response response;
    if (!widget.user.invited) {
      response = await http.post(Uri(scheme: 'https',
          host: 'facilino.webs.upv.es',
          path: '/download.php'), body: {
        'username': widget.user.username,
        'key': widget.user.key,
        'action': 'arduino',
        'id': proj_id.toString()
      },
          headers: {
            "Accept": "application/json",
            "Content-Type": "application/x-www-form-urlencoded"
          }
      );
    }
    else
      {
        response = await http.post(Uri(scheme: 'https',
            host: 'facilino.webs.upv.es',
            path: '/download.php'), body: {
          'invited': 'true',
          'user_id': widget.user.id.toString(),
          'action': 'arduino',
          'id': proj_id.toString()
        },
            headers: {
              "Accept": "application/json",
              "Content-Type": "application/x-www-form-urlencoded"
            }
        );
      }
    debugPrint(response.body);
    dynamic resp= json.decode(response.body);

    if (resp['result']=='OK') {
      final fileDirectory = await getApplicationDocumentsDirectory();
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Arduino project as',
        fileName: '${resp['name'].toString()}.ino',
        initialDirectory: fileDirectory.path,
        lockParentWindow: true
      );

      if (outputFile == null) {
        return const Tuple2(DownloadMessages.NO_MESSAGE,'');
      }
      else
        {
          await File(outputFile).writeAsString(resp['arduino_code']);
          return Tuple2(DownloadMessages.DOWNLOADED,outputFile);
        }
      }
    else
      {
        return Tuple2(DownloadMessages.ERROR,resp['Error'].toString());
      }
  }

  @override
  void initState() {
    super.initState();
    WindowManager.instance.maximize();
    windowManager.show();
    windowManager.focus();
    _user=widget.user;
    getProjectOptions();
    getProjectsData();
    _boardList=Board.getBoards();
    server = createServer();
  }

  Future<void> onLogOut() async {
    (await server).close(force: true);
    await storage.delete(key: "KEY_USERNAME");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects Dashboard'),
        actions: [
          FutureBuilder<List<Board>>(
          builder: (BuildContext context, AsyncSnapshot<List<Board>> snapshot){
            if (!snapshot.hasData) {
              return const Icon(Icons.electric_bolt,color:Colors.deepOrange);
            }
            if (snapshot.hasError) {
              return const Icon(Icons.electric_bolt,color:Colors.deepOrange);
            }

            if (snapshot.data!.isNotEmpty) {
              String p='';
              List<String> ports=[];
              for (var board in snapshot.data!)
                {
                  ports.add(board.port);
                }
              if (ports.contains(selected_port)) {
                p=selected_port;
              } else {
                p=snapshot.data![0].port;
                selected_port=p;
              }
              String t='Connected to ${p}';
              return Row(children: [
              InkWell(
              customBorder: CircleBorder(),
              child: Ink(
              padding: const EdgeInsets.all(2),
              child: Icon(Icons.electric_bolt)),
              onTapDown: (details) async {
                _boardList=Board.getBoards();
                List<Board> _list = await _boardList;
                if (!context.mounted) return;
                final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
                List<PopupMenuItem<String>> items = [];
                for (Board board in _list) {
                  items.add(PopupMenuItem<String>(value: board.port, child: Text(board.port)));
                }

                await showMenu(
                  context: context,
                  position: RelativeRect.fromRect(details.globalPosition & const Size(40, 40),Offset.zero & overlay.size),
                  items: items,
                  elevation: 8.0,
                ).then((String? value) {
                    if (value!=null) {
                      selected_port = value;
                      debugPrint(value);
                      setState(() {});
                    }
                });
                setState(() {});
              }),
                /*PopupMenuButton(
                  onOpened: () => {_boardList=Board.getBoards()},
                  tooltip: t,
                  initialValue: p,
                  icon: const Icon(Icons.electric_bolt),
                  // add icon, by default "3 dot" icon
                  // icon: Icon(Icons.book)
                  itemBuilder: (context) {
                    List<PopupMenuItem<String>> items = [];
                    for (Board board in snapshot.data!) {
                      items.add(PopupMenuItem<String>(value: board.port, child: Text(board.port)));
                    }
                    return items;
                  },
                  onSelected: (value) {
                    selected_port=value;
                    setState(() {});
                  }
              ),*/
                selected_port.isNotEmpty? IconButton(
                    onPressed: () async {
                      await Navigator.push(context,MaterialPageRoute(builder: (context)=> SerialConsole(portName: selected_port)));
                      debugPrint('Returned from serial console');
                      //SerialPort port = SerialPort(selected_port);
                      //debugPrint(port.toString());
                      //port.dispose();
                      /*
                      SerialPortReader reader = SerialPortReader(port, timeout: 10);
                      if (port.isOpen) {
                        reader.close();
                        port.close();
                      }*/
                }, tooltip: 'Serial Console', icon: const Icon(Icons.search)):Container(),
                Text(selected_port)
              ]);
            }
            else
              {
                return const Icon(Icons.electric_bolt,color:Colors.deepOrange);
              }
    },
      future: _boardList),
          //IconButton(onPressed: (){newProject(widget.user,projectOptions);}, icon: const Icon(Icons.add)),
          IconButton(onPressed: () async {Navigator.push(context,MaterialPageRoute(builder: (context)=> const FacilinoSettings()));
            }, icon: const Icon(Facilino.facilino_letter),tooltip: AppLocalizations.of(context)!.facilinoSettings,),
          //IconButton(onPressed: (){}, icon: const Icon(Icons.upload)),
          //IconButton(onPressed: (){ getProjectsData();}, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: (){editUser(widget.user);}, icon: const Icon(Icons.person), tooltip: '${widget.user.first_name} ${widget.user.last_name}',),
          IconButton(onPressed: (){onLogOut(); Navigator.pushReplacement(context,MaterialPageRoute(builder: (context) => LoginPage(alreadyLogged: false)));}, icon: const Icon(Icons.logout),tooltip: 'Logout',)
        ],
      ),
      body: FutureBuilder<List<Project>>(
          builder: (BuildContext context, AsyncSnapshot<List<Project>> snapshot){
            if (!snapshot.hasData) {
              return const Center(child: LoadingIndicator(indicatorType: Indicator.ballPulse,strokeWidth: 4.0));
            }
            if (snapshot.hasError) {
              return const Center(child: Text('Something went wrong :('));
            }
                return ListView.builder(
                    itemCount: snapshot.data!.length,
                    shrinkWrap: true,
                    itemBuilder: (context,pos){
                      return
                        InkWell(
                          hoverColor: Colors.blueAccent,
                          mouseCursor: MaterialStateMouseCursor.clickable,
                          child: Card(margin: const EdgeInsets.all(3),
                            child: Padding(padding: const EdgeInsets.all(5),child: ListTile(
                              title: Text(snapshot.data![pos].name),
                              subtitle: Row(
                                children: [
                                  CachedNetworkImage(
                                    imageUrl: "https://facilino.webs.upv.es/assets/images/${projectOptions.boards[projectOptions.boardIDs
                                        .indexOf(snapshot.data![pos].proc_id)]['image']
                                        .toString()}",
                                    placeholder: (context, url) => const CircularProgressIndicator(),
                                    errorWidget: (context, url, error) => const Icon(Icons.error),
                                    height: 24,
                                  ),
                                  const SizedBox(width: 4,),
                                  CachedNetworkImage(
                                    imageUrl: "https://facilino.webs.upv.es/assets/images/${projectOptions.versions[projectOptions.versionIDs
                                        .indexOf(snapshot.data![pos].version_id)]['image']
                                        .toString()}",
                                    placeholder: (context, url) => const CircularProgressIndicator(),
                                    errorWidget: (context, url, error) => const Icon(Icons.error),
                                    height: 24,
                                  ),
                                  const SizedBox(width: 4,),
                                  CachedNetworkImage(
                                    imageUrl: "https://facilino.webs.upv.es/assets/images/${projectOptions.filters[projectOptions.filterIDs
                                        .indexOf(snapshot.data![pos].filter_id)]['image']
                                        .toString()}",
                                    placeholder: (context, url) => const CircularProgressIndicator(),
                                    errorWidget: (context, url, error) => const Icon(Icons.error),
                                    height: 24,
                                  ),
                                  const SizedBox(width: 4,),
                                  CachedNetworkImage(
                                    imageUrl: "https://facilino.webs.upv.es/lang/images/${projectOptions.languages[projectOptions.langIDs
                                        .indexOf(snapshot.data![pos].lang_id)]['image']
                                        .toString()}",
                                    placeholder: (context, url) => const CircularProgressIndicator(),
                                    errorWidget: (context, url, error) => const Icon(Icons.error),
                                    height: 24,
                                  ),
                                ],
                              ),
                              trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(onPressed: () async {
                                      final webview= await WebviewWindow.create(configuration: CreateConfiguration(
                                        windowHeight: window.physicalSize.height.toInt(),
                                        windowWidth: window.physicalSize.width.toInt(),
                                        title: snapshot.data![pos].name,
                                        titleBarTopPadding: 0,
                                        titleBarHeight: 0,
                                      ));
                                      if (!widget.user.invited)
                                      {
                                        webview.launch("https://facilino.webs.upv.es/facilino.php?action=open&id=${snapshot.data![pos].id}&username=${widget.user.username}&key=${widget.user.key}&alt_header");
                                      }
                                      else
                                      {
                                        webview.launch("https://facilino.webs.upv.es/facilino.php?action=open&id=${snapshot.data![pos].id}&username=${widget.user.username}&key=${widget.user.key}&alt_header&invited");
                                      }

                                      await Future.delayed(const Duration(seconds: 2));
                                      //String? code = await webview.evaluateJavaScript('eval("Blockly.Xml.domToText(Blockly.Xml.workspaceToDom(Blockly.getMainWorkspace()))")');
                                      //debugPrint(code!);
                                      webview.addOnUrlRequestCallback((url) async{
                                        if (url.contains("dashboard.php")) {
                                          debugPrint('Closing');
                                          webview.close();
                                        }
                                      });
                                    }, icon: const Icon(Icons.open_in_new),tooltip: 'Open project',),
                                    IconButton(onPressed: (){
                                      duplicateProject(snapshot.data![pos].id);
                                    }, icon: const Icon(Icons.content_copy), tooltip: 'Duplicate project',),
                                    IconButton(onPressed: (){
                                      AlertDialog alert = AlertDialog(
                                        title: const Text("Delete Project"),
                                        content: const Text("Are you sure you want to delete the project (can't be undone)?"),
                                        actions: [
                                          TextButton(
                                            child: const Text("No"),
                                            onPressed:  () {
                                              Navigator.pop(context);
                                            },
                                          ),
                                          TextButton(
                                            child: const Text("Yes"),
                                            onPressed:  () {
                                              deleteProject(snapshot.data![pos].id);
                                              Navigator.pop(context);
                                            },
                                          ),
                                        ],
                                      );
                                      showDialog(context: context,
                                        builder: (BuildContext context) {
                                          return alert;
                                        },
                                      );
                                    }, icon: const Icon(Icons.delete), tooltip: 'Delete project',),
                                    IconButton(onPressed: () {
                                      downloadArduinoProject(snapshot.data![pos].id).then((Tuple2<DownloadMessages,String> message) {
                                        if (message.item1==DownloadMessages.DOWNLOADED) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text(AppLocalizations.of(context)!.fileSavedAt(message.item2))),
                                          );
                                        }
                                        else if (message.item1==DownloadMessages.ERROR) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text(message.item2)),
                                          );
                                        }
                                      });
                                    }, icon: const Icon(Facilino.arduino_letter), tooltip: 'Arduino code',
                                    ),
                                    IconButton(onPressed: (){
                                      editProject(widget.user,snapshot.data![pos],projectOptions);
                                    }, icon: const Icon(Icons.settings), tooltip: 'Project settings',
                                    ),
                                  ]
                              ),
                            ),
                            ),
                          ),
                          onTap: () async {
                            final webview= await WebviewWindow.create(configuration: CreateConfiguration(
                              windowHeight: window.physicalSize.height.toInt(),
                              windowWidth: window.physicalSize.width.toInt(),
                              title: snapshot.data![pos].name,
                              titleBarTopPadding: 0,
                              titleBarHeight: 0,
                            ));
                            if (snapshot.data![pos].id!=0)
                            {
                              webview.launch("https://facilino.webs.upv.es/facilino.php?action=open&id=${snapshot.data![pos].id}&username=${widget.user.username}&key=${widget.user.key}&alt_header");
                            }else
                            {
                              webview.launch("https://facilino.webs.upv.es/facilino.php?action=open&id=${snapshot.data![pos].id}&username=${widget.user.username}&key=&name=${snapshot.data![pos].name}&lang_id=${snapshot.data![pos].lang_id}&filt_id=${snapshot.data![pos].filter_id}&proc_id=${snapshot.data![pos].proc_id}&version_id=${snapshot.data![pos].version_id}&alt_header");
                            }
                            //webview.launch("https://facilino.webs.upv.es/facilino.php?action=open&id=${snapshot.data![pos].id}&username=${widget.user.username}&key=${widget.user.key}&alt_header");
                            await Future.delayed(const Duration(seconds: 2));
                            webview.addOnUrlRequestCallback((url) async {
                              if (url.contains("dashboard.php")) {
                                String? code = await webview.evaluateJavaScript('eval("Blockly.Xml.domToText(Blockly.Xml.workspaceToDom(Blockly.getMainWorkspace()))")');
                                debugPrint(code!);
                                debugPrint('Closing2');
                                webview.close();
                              }
                            });
                          },
                        );
                    });
          },
          future: projects
      ),
        floatingActionButton:
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              onPressed: () async {
                getProjectsData();
                _boardList=Board.getBoards();
              },
              tooltip: 'Refresh', heroTag: "btnRefresh",
              child: const Icon(Icons.refresh)
            ),
            const SizedBox(width: 8,),
            FloatingActionButton(
              onPressed: () async {
                newProject(widget.user,projectOptions);
              },
              tooltip: 'Add', heroTag: "btnAdd",
              child: const Icon(Icons.add)
            )
          ],
        ),
    );
  }
}