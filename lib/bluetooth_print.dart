import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';

import 'bluetooth_print_model.dart';

class BluetoothPrint {
  static const String NAMESPACE = 'bluetooth_print';
  static const int CONNECTED = 1;
  static const int DISCONNECTED = 0;

  static const MethodChannel _channel = MethodChannel('$NAMESPACE/methods');
  static const EventChannel _stateChannel = EventChannel('$NAMESPACE/state');

  Stream<MethodCall> get _methodStream => _methodStreamController.stream;
  final StreamController<MethodCall> _methodStreamController = StreamController.broadcast();

  BluetoothPrint._() {
    _channel.setMethodCallHandler((MethodCall call) async {
      _methodStreamController.add(call);
      return null;
    });
  }

  static final BluetoothPrint _instance = BluetoothPrint._();

  static BluetoothPrint get instance => _instance;

  Future<bool> get isAvailable async =>
      await _channel.invokeMethod<bool>('isAvailable') ?? false;

  Future<bool> get isOn async =>
      await _channel.invokeMethod<bool>('isOn') ?? false;

  Future<bool> get isConnected async =>
      await _channel.invokeMethod<bool>('isConnected') ?? false;

  final BehaviorSubject<bool> _isScanning = BehaviorSubject.seeded(false);

  Stream<bool> get isScanning => _isScanning.stream;

  final BehaviorSubject<List<BluetoothDevice>> _scanResults =
      BehaviorSubject.seeded([]);

  Stream<List<BluetoothDevice>> get scanResults => _scanResults.stream;

  final PublishSubject<void> _stopScanPill = PublishSubject();

  /// Gets the current state of the Bluetooth module
  Stream<int> get state async* {
    final initialState = await _channel.invokeMethod<int>('state') ?? DISCONNECTED;
    yield initialState;

    yield* _stateChannel.receiveBroadcastStream().map((s) => s as int);
  }

  /// Starts a scan for Bluetooth Low Energy devices
  /// Timeout closes the stream after a specified [Duration]
  Stream<BluetoothDevice> scan({
    Duration? timeout,
  }) async* {
    if (_isScanning.value == true) {
      throw Exception('Another scan is already in progress.');
    }

    // Emit to isScanning
    _isScanning.add(true);

    final killStreams = <Stream>[_stopScanPill];
    if (timeout != null) {
      killStreams.add(Rx.timer<void>(null, timeout));
    }

    // Clear scan results list
    _scanResults.add(<BluetoothDevice>[]);

    try {
      await _channel.invokeMethod('startScan');
    } catch (e) {
      print('Error starting scan: $e');
      _stopScanPill.add(null);
      _isScanning.add(false);
      rethrow;
    }

    yield* BluetoothPrint.instance._methodStream
        .where((m) => m.method == "ScanResult")
        .map((m) => m.arguments)
        .takeUntil(Rx.merge(killStreams))
        .doOnDone(stopScan)
        .map((map) {
      if (map == null) throw Exception('Scan result is null');
      final device = BluetoothDevice.fromJson(Map<String, dynamic>.from(map as Map));
      final List<BluetoothDevice> list = _scanResults.value;
      final existingIndex = list.indexWhere((e) => e.address == device.address);

      if (existingIndex != -1) {
        list[existingIndex] = device;
      } else {
        list.add(device);
      }
      _scanResults.add(list);
      return device;
    });
  }

  Future<List<BluetoothDevice>> startScan({
    Duration? timeout,
  }) async {
    await scan(timeout: timeout).drain();
    return _scanResults.value;
  }

  /// Stops a scan for Bluetooth Low Energy devices
  Future<void> stopScan() async {
    await _channel.invokeMethod('stopScan');
    _stopScanPill.add(null);
    _isScanning.add(false);
  }

  Future<void> connect(BluetoothDevice device) =>
      _channel.invokeMethod('connect', device.toJson());

  Future<void> disconnect() => _channel.invokeMethod('disconnect');

  Future<void> destroy() => _channel.invokeMethod('destroy');

  Future<bool> printReceipt(Map<String, dynamic> config, List<LineText> data) async {
    final Map<String, Object> args = {
      'config': config,
      'data': data.map((m) => m.toJson()).toList(),
    };

    await _channel.invokeMethod('printReceipt', args);
    return true;
  }

  Future<bool> printLabel(Map<String, dynamic> config, List<LineText> data) async {
    final Map<String, Object> args = {
      'config': config,
      'data': data.map((m) => m.toJson()).toList(),
    };

    await _channel.invokeMethod('printLabel', args);
    return true;
  }

  Future<bool> writeByte(Map<String, dynamic> config, List<int> data) async {
    final Map<String, Object> args = {
      'config': config,
      'data': jsonEncode(data),
    };

    await _channel.invokeMethod('writeByte', args);
    return true;
  }

  Future<void> printTest() => _channel.invokeMethod('printTest');
}
