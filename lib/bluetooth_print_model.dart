import 'package:json_annotation/json_annotation.dart';

part 'bluetooth_print_model.g.dart';

const int ALIGN_LEFT = 0;
const int ALIGN_CENTER = 1;
const int ALIGN_RIGHT = 2;

@JsonSerializable(includeIfNull: false)
class BluetoothDevice {
  BluetoothDevice({
    this.name,
    this.address,
    this.type = 0,
    this.connected = false,
  });

  String? name;
  String? address;
  int? type;
  bool? connected;

  factory BluetoothDevice.fromJson(Map<String, dynamic> json) =>
      _$BluetoothDeviceFromJson(json);
  Map<String, dynamic> toJson() => _$BluetoothDeviceToJson(this);
}

@JsonSerializable(includeIfNull: false)
class LineText {
  static const String TYPE_TEXT = 'text';
  static const String TYPE_BARCODE = 'barcode';
  static const String TYPE_QRCODE = 'qrcode';
  static const String TYPE_IMAGE = 'image';

  LineText({
    this.type,
    this.content,
    this.size = 0,
    this.align = ALIGN_LEFT,
    this.weight = 0,
    this.width = 0,
    this.height = 0,
    this.absolutePos = 0,
    this.relativePos = 0,
    this.fontZoom = 1,
    this.underline = 0,
    this.linefeed = 0,
    this.x = 0,
    this.y = 0,
  });

  /// print type ,include['text','barcode','qrcode','image']
  final String? type;

  /// ['text','barcode','qrcode','image'] need print content
  final String? content;

  /// ['qrcode'] qrcode size ,only when type is qrcode
  final int? size;

  /// ['text'] text align
  final int? align;

  /// ['text'] text weight
  final int? weight;

  /// ['text'] text width
  final int? width;

  /// ['text'] text height
  final int? height;

  /// ['text'] absolute position from line begin
  final int? absolutePos;

  /// ['text'] relative position from last content
  final int? relativePos;

  /// ['text'] font zoom level, include 1-8
  final int? fontZoom;

  /// ['text'] show underline
  final int? underline;

  /// ['text'] print linebreak
  final int? linefeed;

  /// X coordinate for positioning
  final int? x;

  /// Y coordinate for positioning
  final int? y;

  factory LineText.fromJson(Map<String, dynamic> json) =>
      _$LineTextFromJson(json);
  Map<String, dynamic> toJson() => _$LineTextToJson(this);
}
