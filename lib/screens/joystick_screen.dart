import 'dart:convert';

import 'package:control_pad/control_pad.dart';
import 'package:control_pad/models/gestures.dart';
import 'package:control_pad/models/pad_button_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

class JoystickScreen extends StatefulWidget {
  const JoystickScreen({Key key, this.device}) : super(key: key);
  final BluetoothDevice device;
  @override
  _JoystickScreenState createState() => _JoystickScreenState();
}

class _JoystickScreenState extends State<JoystickScreen> {
  BluetoothCharacteristic targetCharacteristic;

  String connectionText = "Device Connected";

  final String SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  final String CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

  @override
  void initState() {
    super.initState();
    connectToDevice();
  }

  connectToDevice() async {
    await widget.device.connect();
    setState(() {
      connectionText = "Connected to Device";
    });

    await discoverServices();
  }

  discoverServices() async {
    if (widget.device == null) return;

    List<BluetoothService> services = await widget.device.discoverServices();
    services.forEach((service) {
      // do something with service
      if (service.uuid.toString() == SERVICE_UUID) {
        service.characteristics.forEach((characteristic) {
          if (characteristic.uuid.toString() == CHARACTERISTIC_UUID) {
            targetCharacteristic = characteristic;
            writeData("Hi there, ESP32!!");
            setState(() {
              connectionText = "All Ready with ${widget.device.name}";
            });
          }
        });
      }
    });
  }

  disconnectFromDevice() {
    if (widget.device == null) return;

    widget.device.disconnect();

    setState(() {
      connectionText = "Device Disconnected";
    });
  }

  writeData(String data) async {
    if (targetCharacteristic == null) return;

    List<int> bytes = utf8.encode(data);
    await targetCharacteristic.write(bytes, withoutResponse: true);
  }

  @override
  Widget build(BuildContext context) {
    JoystickDirectionCallback onDirectionChanged(
        double degrees, double distance) {
      String data =
          "Degree : ${degrees.toStringAsFixed(2)}, distance : ${distance.toStringAsFixed(2)}";
      print(data);
      writeData(data);
    }

    PadButtonPressedCallback padButtonPressedCallback(
        int buttonIndex, Gestures gesture) {
      String data;
      if (buttonIndex == 2) {
        data = 'walk';
      } else {
        data = "buttonIndex : ${buttonIndex}";
      }
      print(data);
      writeData(data);
    }

    Future<bool> _onWillPop() {
      return showDialog(
          context: context,
          builder: (context) =>
              new AlertDialog(
                title: Text('Are you sure?'),
                content: Text('Do you want to disconnect device and go back?'),
                actions: <Widget>[
                  new FlatButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: new Text('No')),
                  new FlatButton(
                      onPressed: () {
                        disconnectFromDevice();
                        Navigator.of(context).pop(true);
                      },
                      child: new Text('Yes')),
                ],
              ) ??
              false);
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(connectionText),
        ),
        body: Container(
          child:
              // targetCharacteristic == null
              //     ? Center(
              //         child: Text(
              //           "Waiting...",
              //           style: TextStyle(fontSize: 24, color: Colors.red),
              //         ),
              //       )
              //     :
              Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              JoystickView(
                onDirectionChanged: onDirectionChanged,
              ),
              PadButtonsView(
                buttons: [
                  PadButtonItem(index: 0, buttonText: "A"),
                  PadButtonItem(
                      index: 1, buttonText: "B", pressedColor: Colors.red),
                  PadButtonItem(
                      index: 2, buttonText: "C", pressedColor: Colors.green),
                  PadButtonItem(
                      index: 3, buttonText: "D", pressedColor: Colors.yellow),
                ],
                padButtonPressedCallback: padButtonPressedCallback,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
