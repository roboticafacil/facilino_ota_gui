import 'package:libserialport/libserialport.dart';

class PortManager{

  late SerialPort port ;

  String? portName;

  PortManager.fromName(String this.portName){
    port = SerialPort(portName!);
  }
  open(){
  }

  


}