import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SerialConsole extends StatefulWidget {
  const SerialConsole({super.key, required this.portName});

  final String portName;

  @override
  State<SerialConsole> createState() => _SerialConsoleState();
}

class _SerialConsoleState extends State<SerialConsole> {
  late SerialPort port;
  late SerialPortReader reader;
  String selected_baudrate='';
  FocusNode keepFocus = FocusNode();
  List<String> io_Buffer = <String>[];
  TextEditingController inputData = TextEditingController();
  String outputData = "";
  List<String> baudrates=["9600","115200"];
  final storage = const FlutterSecureStorage();

  Future<void> openPort(String portName) async {
    try {
      port = SerialPort(portName);
      selected_baudrate=(await storage.read(key: "PORT_BAUDRATE"))??'';
      String p='';
      if (baudrates.contains(selected_baudrate)) {
        p=selected_baudrate;
      } else {
        p=baudrates[0];
        selected_baudrate=p;
        storage.write(key: "PORT_BAUDRATE", value: selected_baudrate);
      }
      port.openReadWrite();
      if (port.isOpen)
      {
        var config = SerialPortConfig();
        config.baudRate = int.parse(selected_baudrate);
        port.config = config;
        debugPrint('Port is opened!');
      }
    } catch (e, _) {
      debugPrint("Port ${portName} could not be opened!");
      port.dispose();
      if (!context.mounted) return;
      Navigator.of(context).pop();
    }
    setState(() {
    });
  }

  @override
  void initState() {
    super.initState();
    openPort(widget.portName);
  }

  @override
  void dispose()
  {
    super.dispose();
    if (port.isOpen) {
      port.close();
      port.dispose();
      debugPrint('Port closed!');
    }
  }

  @override
  Widget build(BuildContext context) {
    reader = SerialPortReader(port, timeout: 10);

    String stringData;

    final scrollController = ScrollController();
    final stream = reader.stream.map((data) {
        stringData = String.fromCharCodes(data);
        stringData.replaceAll('\r', "");
        stringData.replaceAll('\n', "");
        io_Buffer.add(stringData);
      });
    //

    return Scaffold(
      appBar: AppBar(
        title: Text('${AppLocalizations.of(context)!.serialConsole} ${widget.portName}', style: const TextStyle(color: Colors.black45,fontWeight: FontWeight.bold)),
        actions: [
          Row(children: [PopupMenuButton(
              tooltip: AppLocalizations.of(context)!.baudrate,
              initialValue:selected_baudrate,
              icon: const Icon(Icons.speed),
              // add icon, by default "3 dot" icon
              // icon: Icon(Icons.book)
              itemBuilder: (context) {
                List<PopupMenuItem<String>> items = [];
                for (String baudrate in baudrates) {
                  items.add(PopupMenuItem<String>(value: baudrate, child: Text(baudrate)));
                }
                return items;
              },
              onSelected: (value) async {
                selected_baudrate=value;
                await storage.write(key: "PORT_BAUDRATE", value: selected_baudrate);
                var config = SerialPortConfig();
                config.baudRate = int.parse(selected_baudrate);
                port.config = config;
                debugPrint('Baudrate changed to $value');
                setState(() {
                });
              }
          ),
            Text(selected_baudrate)
          ])
        ]
      ),
      body: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 7,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.all(5),
              child: Scrollbar(
                controller: scrollController,
                child:
                StreamBuilder(
                  stream: stream,
                  builder: ((context, snapshot) {
                    //debugPrint(io_Buffer.length.toString());
                    return SingleChildScrollView(
                        reverse:true,
                        controller: scrollController,
                        child: Text(io_Buffer.join(''),style: const TextStyle(fontSize: 12,color: Colors.black)));
                  }),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                //color: const Color.fromARGB(255, 236, 238, 242),
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.all(5),
              child: Row(
                children: [
                  Expanded(
                    flex: 7,
                    child: TextField(
                      autofocus: true,
                      focusNode: keepFocus,
                      style: const TextStyle(color: Colors.blue),
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: AppLocalizations.of(context)!.sendData,
                        suffixIcon: IconButton(
                          onPressed: () {
                            inputData.clear();
                          },
                          icon: const Icon(Icons.clear),
                        ),
                      ),
                      controller: inputData,
                      onSubmitted: (str) {
                        if (inputData.text.isEmpty) {
                          setState(() => Null);
                        } else {
                          setState(
                            () async {
                              io_Buffer.add('> ${inputData.text}');
                              Uint8List data = Uint8List.fromList(inputData.text.codeUnits);
                              port.write(data);
                              debugPrint("write : ${inputData.text}");
                              // port.write(Uint8List.fromList(" ".codeUnits));
                              // port.write(inputData.text);
                              // port.write(" ");
                              // inputBuffer.add(inputData.text);

                              inputData.clear();
                            },
                          );
                          inputData.clear();
                          keepFocus.requestFocus();
                        }
                      },
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Container(
                      width: 50,
                      margin: const EdgeInsets.only(left: 20, right: 20),
                      child: MaterialButton(
                        child: const Icon(Icons.send),
                        onPressed: () {
                          if (inputData.text.isEmpty) {
                            setState(() {
                              Null;
                            });
                          } else {
                            setState(() {
                              io_Buffer.add('> ${inputData.text}');
                              Uint8List data = Uint8List.fromList(inputData.text.codeUnits);
                              port.write(data);
                              debugPrint("write : ${inputData.text}");
                              inputData.clear();
                            });
                            keepFocus.requestFocus();
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
