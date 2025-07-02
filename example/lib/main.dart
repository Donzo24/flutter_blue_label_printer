import 'dart:async';
import 'dart:convert';

import 'package:bluetooth_print/bluetooth_print.dart';
import 'package:bluetooth_print/bluetooth_print_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final BluetoothPrint bluetoothPrint = BluetoothPrint.instance;
  bool _connected = false;
  BluetoothDevice? _device;
  String tips = 'no device connect';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => initBluetooth());
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initBluetooth() async {
    await bluetoothPrint.startScan(timeout: const Duration(seconds: 4));

    final bool isConnected = await bluetoothPrint.isConnected;

    bluetoothPrint.state.listen((state) {
      debugPrint('Current device status: $state');

      switch (state) {
        case BluetoothPrint.CONNECTED:
          setState(() {
            _connected = true;
            tips = 'connect success';
          });
          break;
        case BluetoothPrint.DISCONNECTED:
          setState(() {
            _connected = false;
            tips = 'disconnect success';
          });
          break;
        default:
          break;
      }
    });

    if (!mounted) return;

    if(isConnected) {
      setState(() {
        _connected = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('BluetoothPrint example app'),
        ),
        body: RefreshIndicator(
          onRefresh: () =>
              bluetoothPrint.startScan(timeout: const Duration(seconds: 4)),
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  child: Text(tips),
                ),
                const Divider(),
                StreamBuilder<List<BluetoothDevice>>(
                  stream: bluetoothPrint.scanResults,
                  initialData: const [],
                  builder: (c, snapshot) => Column(
                    children: snapshot.data!.map((d) => ListTile(
                      title: Text(d.name ?? ''),
                      subtitle: Text(d.address ?? ''),
                      onTap: () {
                        setState(() {
                          _device = d;
                        });
                      },
                      trailing: _device != null && _device!.address == d.address
                          ? const Icon(Icons.check, color: Colors.green)
                          : null,
                    )).toList(),
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 5, 20, 10),
                  child: Column(
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          OutlinedButton(
                            onPressed: _connected ? null : () async {
                              if(_device?.address != null) {
                                setState(() {
                                  tips = 'connecting...';
                                });
                                await bluetoothPrint.connect(_device!);
                              } else {
                                setState(() {
                                  tips = 'please select device';
                                });
                                debugPrint('please select device');
                              }
                            },
                            child: const Text('connect'),
                          ),
                          const SizedBox(width: 10.0),
                          OutlinedButton(
                            onPressed: _connected ? () async {
                              setState(() {
                                tips = 'disconnecting...';
                              });
                              await bluetoothPrint.disconnect();
                            } : null,
                            child: const Text('disconnect'),
                          ),
                        ],
                      ),
                      const Divider(),
                      OutlinedButton(
                        onPressed: _connected ? () async {
                          final Map<String, dynamic> config = {};
                          final List<LineText> list = [];

                          list.add(LineText(
                            type: LineText.TYPE_TEXT,
                            content: '**********************************************',
                            weight: 1,
                            align: LineText.ALIGN_CENTER,
                            linefeed: 1
                          ));
                          list.add(LineText(
                            type: LineText.TYPE_TEXT,
                            content: 'Receipt Header',
                            weight: 1,
                            align: LineText.ALIGN_CENTER,
                            fontZoom: 2,
                            linefeed: 1
                          ));
                          list.add(LineText(linefeed: 1));

                          list.add(LineText(
                            type: LineText.TYPE_TEXT,
                            content: 'Item Name',
                            align: LineText.ALIGN_LEFT,
                            absolutePos: 0,
                            relativePos: 0,
                            linefeed: 0
                          ));
                          list.add(LineText(
                            type: LineText.TYPE_TEXT,
                            content: 'Unit',
                            align: LineText.ALIGN_LEFT,
                            absolutePos: 350,
                            relativePos: 0,
                            linefeed: 0
                          ));
                          list.add(LineText(
                            type: LineText.TYPE_TEXT,
                            content: 'Qty',
                            align: LineText.ALIGN_LEFT,
                            absolutePos: 500,
                            relativePos: 0,
                            linefeed: 1
                          ));

                          list.add(LineText(
                            type: LineText.TYPE_TEXT,
                            content: 'Product C30',
                            align: LineText.ALIGN_LEFT,
                            absolutePos: 0,
                            relativePos: 0,
                            linefeed: 0
                          ));
                          list.add(LineText(
                            type: LineText.TYPE_TEXT,
                            content: 'pcs',
                            align: LineText.ALIGN_LEFT,
                            absolutePos: 350,
                            relativePos: 0,
                            linefeed: 0
                          ));
                          list.add(LineText(
                            type: LineText.TYPE_TEXT,
                            content: '12.0',
                            align: LineText.ALIGN_LEFT,
                            absolutePos: 500,
                            relativePos: 0,
                            linefeed: 1
                          ));

                          list.add(LineText(
                            type: LineText.TYPE_TEXT,
                            content: '**********************************************',
                            weight: 1,
                            align: LineText.ALIGN_CENTER,
                            linefeed: 1
                          ));
                          list.add(LineText(linefeed: 1));

                          final ByteData data = await rootBundle.load("assets/images/bluetooth_print.png");
                          final List<int> imageBytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
                          final String base64Image = base64Encode(imageBytes);
                          list.add(LineText(
                            type: LineText.TYPE_IMAGE,
                            content: base64Image,
                            align: LineText.ALIGN_CENTER,
                            linefeed: 1
                          ));

                          await bluetoothPrint.printReceipt(config, list);
                        } : null,
                        child: const Text('print receipt(esc)'),
                      ),
                      OutlinedButton(
                        onPressed: _connected ? () async {
                          final Map<String, dynamic> config = {
                            'width': 40, // Label width in mm
                            'height': 70, // Label height in mm
                            'gap': 2, // Gap between labels in mm
                          };

                          // x, y coordinates in dpi, 1mm = 8dpi
                          final List<LineText> list = [
                            LineText(type: LineText.TYPE_TEXT, x: 10, y: 10, content: 'A Title'),
                            LineText(type: LineText.TYPE_TEXT, x: 10, y: 40, content: 'this is content'),
                            LineText(type: LineText.TYPE_QRCODE, x: 10, y: 70, content: 'qrcode content\n'),
                            LineText(type: LineText.TYPE_BARCODE, x: 10, y: 190, content: 'barcode content\n'),
                          ];

                          final List<LineText> imageList = [];
                          final ByteData imageData = await rootBundle.load("assets/images/guide3.png");
                          final List<int> imageBytes = imageData.buffer.asUint8List(imageData.offsetInBytes, imageData.lengthInBytes);
                          final String base64Image = base64Encode(imageBytes);
                          imageList.add(LineText(
                            type: LineText.TYPE_IMAGE,
                            content: base64Image,
                            align: LineText.ALIGN_CENTER,
                            width: 850
                          ));

                          await bluetoothPrint.printLabel(config, list);
                          await bluetoothPrint.printLabel(config, imageList);
                        } : null,
                        child: const Text('print label(tsc)'),
                      ),
                      OutlinedButton(
                        onPressed: _connected ? () async {
                          await bluetoothPrint.printTest();
                        } : null,
                        child: const Text('print selftest'),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
        floatingActionButton: StreamBuilder<bool>(
          stream: bluetoothPrint.isScanning,
          initialData: false,
          builder: (c, snapshot) {
            if (snapshot.data == true) {
              return FloatingActionButton(
                onPressed: () => bluetoothPrint.stopScan(),
                backgroundColor: Colors.red,
                child: const Icon(Icons.stop),
              );
            }
            return FloatingActionButton(
              onPressed: () => bluetoothPrint.startScan(timeout: const Duration(seconds: 4)),
              child: const Icon(Icons.search),
            );
          },
        ),
      ),
    );
  }
}
