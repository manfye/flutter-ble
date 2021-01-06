import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import "dart:typed_data";

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'BLE Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: MyHomePage(title: 'Flutter BLE Demo'),
      );
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;
  final FlutterBlue flutterBlue = FlutterBlue.instance;
  final List<BluetoothDevice> devicesList = new List<BluetoothDevice>();
  final Map<Guid, List<int>> readValues = new Map<Guid, List<int>>();

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _writeController = TextEditingController();
  BluetoothDevice _connectedDevice;
  List<BluetoothService> _services;

  _addDeviceTolist(final BluetoothDevice device) {
    if (!widget.devicesList.contains(device)) {
      setState(() {
        widget.devicesList.add(device);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    widget.flutterBlue.connectedDevices
        .asStream()
        .listen((List<BluetoothDevice> devices) {
      for (BluetoothDevice device in devices) {
        _addDeviceTolist(device);
      }
    });
    widget.flutterBlue.scanResults.listen((List<ScanResult> results) {
      for (ScanResult result in results) {
        _addDeviceTolist(result.device);
      }
    });
    widget.flutterBlue.startScan();
  }

//https://thingsboard.io/docs/iot-gateway/guides/how-to-connect-ble-sensor-using-gateway/
  _testBytes() {
    String foo = 'Hello world';
// Runes runes = foo.runes;
// or
    Iterable<int> bytes2 = foo.codeUnits;
    print(bytes2);
    // bytesToInteger();
    bytesToHexString();
  }

  uint16ToByte() {}
  bytesToInteger(t1, t2) {
    var value = 0;
    //1343232275
    List<int> bytes = [t1, t2];
    for (var i = 0, length = bytes.length; i < length; i++) {
      value += bytes[i] * pow(256, i);
    }

    print(value);
  }

  bytesToHexString() {
    // List<int> bytes2 = [69, 83, 89, 77, 83, 69, 84]; 00002a00-0000-1000-8000-00805f9b34fb
    List<int> bytes2 = [16, 0, 32, 0, 0, 0, 144, 1];

    String bar = utf8.decode(bytes2);
    print(bar);
  }

  ListView _buildListViewOfDevices() {
    List<Container> containers = new List<Container>();
    for (BluetoothDevice device in widget.devicesList) {
      device.type.toString() == "BluetoothDeviceType.le"
          ? containers.add(
              Container(
                height: 50,
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        children: <Widget>[
                          Text(device.name == ''
                              ? '(unknown device)'
                              : device.name),
                          Text(device.id.toString()),
                          Text(device.type.toString()),
                        ],
                      ),
                    ),
                    FlatButton(
                      color: Colors.blue,
                      child: Text(
                        'Connect',
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () async {
                        widget.flutterBlue.stopScan();
                        try {
                          await device.connect();
                        } catch (e) {
                          if (e.code != 'already_connected') {
                            throw e;
                          }
                        } finally {
                          _services = await device.discoverServices();
                        }
                        setState(() {
                          _connectedDevice = device;
                        });
                      },
                    ),
                  ],
                ),
              ),
            )
          : SizedBox(
              height: 0,
            );
    }

    return ListView(
      padding: const EdgeInsets.all(8),
      children: <Widget>[
        ...containers,
      ],
    );
  }

  List<ButtonTheme> _buildReadWriteNotifyButton(
      BluetoothCharacteristic characteristic) {
    List<ButtonTheme> buttons = new List<ButtonTheme>();

    // if (characteristic.properties.read) {
    //   buttons.add(
    //     ButtonTheme(
    //       minWidth: 10,
    //       height: 20,
    //       child: Padding(
    //         padding: const EdgeInsets.symmetric(horizontal: 4),
    //         child: RaisedButton(
    //           color: Colors.blue,
    //           child: Text('READ', style: TextStyle(color: Colors.white)),
    //           onPressed: () async {
    //             var sub = characteristic.value.listen((value) {
    //               print(characteristic.uuid);
    //               print(value);
    //               print(widget.flutterBlue.connectedDevices);
    //               print(widget.readValues[characteristic.uuid]);
    //               setState(() {
    //                 widget.readValues[characteristic.uuid] = value;
    //               });
    //             });
    //             await characteristic.read();
    //             sub.cancel();
    //           },
    //         ),
    //       ),
    //     ),
    //   );
    // }
    // if (characteristic.properties.write) {
    //   buttons.add(
    //     ButtonTheme(
    //       minWidth: 10,
    //       height: 20,
    //       child: Padding(
    //         padding: const EdgeInsets.symmetric(horizontal: 4),
    //         child: RaisedButton(
    //           child: Text('WRITE', style: TextStyle(color: Colors.white)),
    //           onPressed: () async {
    //             await showDialog(
    //                 context: context,
    //                 builder: (BuildContext context) {
    //                   return AlertDialog(
    //                     title: Text("Write"),
    //                     content: Row(
    //                       children: <Widget>[
    //                         Expanded(
    //                           child: TextField(
    //                             controller: _writeController,
    //                           ),
    //                         ),
    //                       ],
    //                     ),
    //                     actions: <Widget>[
    //                       FlatButton(
    //                         child: Text("Send"),
    //                         onPressed: () {
    //                           characteristic.write(
    //                               utf8.encode(_writeController.value.text));
    //                           Navigator.pop(context);
    //                         },
    //                       ),
    //                       FlatButton(
    //                         child: Text("Cancel"),
    //                         onPressed: () {
    //                           Navigator.pop(context);
    //                         },
    //                       ),
    //                     ],
    //                   );
    //                 });
    //           },
    //         ),
    //       ),
    //     ),
    //   );
    // }
    if (characteristic.properties.notify) {
      buttons.add(
        ButtonTheme(
          minWidth: 10,
          height: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: RaisedButton(
              child: Text('NOTIFY', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                characteristic.value.listen((value) {
                  widget.readValues[characteristic.uuid] = value;
                  print(value);
                  print(value[0]);
                  bytesToInteger(value[0], value[1]);
                  setState(() {
                    widget.readValues[characteristic.uuid] = value;
                  });
                });

                await characteristic.setNotifyValue(true);
              },
            ),
          ),
        ),
      );
    }

    return buttons;
  }

  ListView _buildConnectDeviceView() {
    List<Container> containers = new List<Container>();

    for (BluetoothService service in _services) {
      List<Widget> characteristicsWidget = new List<Widget>();

      for (BluetoothCharacteristic characteristic in service.characteristics) {
        characteristic.uuid.toString() == "ebe0ccc1-7a0a-4b0c-8a1a-6ff2997da3a6"
            ? characteristicsWidget.add(
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(characteristic.uuid.toString(),
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Row(
                        children: <Widget>[
                          ..._buildReadWriteNotifyButton(characteristic),
                        ],
                      ),
                      Row(
                        children: <Widget>[
                          Text('Value: ' +
                              widget.readValues[characteristic.uuid]
                                  .toString()),
                        ],
                      ),
                      Divider(),
                    ],
                  ),
                ),
              )
            : SizedBox(
                height: 0,
              );
      }
      service.uuid.toString() == "ebe0ccb0-7a0a-4b0c-8a1a-6ff2997da3a6"
          ? containers.add(
              Container(
                child: ExpansionTile(
                    title: Text(service.uuid.toString()),
                    children: characteristicsWidget),
              ),
            )
          : SizedBox(
              height: 0,
            );
    }

    return ListView(
      padding: const EdgeInsets.all(8),
      children: <Widget>[
        ...containers,
      ],
    );
  }

  ListView _buildView() {
    if (_connectedDevice != null) {
      return _buildConnectDeviceView();
    }
    return _buildListViewOfDevices();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // bytesToInteger();
          },
          child: Icon(Icons.navigation),
          backgroundColor: Colors.green,
        ),
        body: _buildView(),
      );
}
