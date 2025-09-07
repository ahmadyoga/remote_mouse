import 'package:json_annotation/json_annotation.dart';

part 'mouse_event.g.dart';

@JsonSerializable()
class MouseEvent {
  final double? dx;
  final double? dy;
  final String? click;
  final String? scroll;
  final String? tap;
  final String? gesture;
  final String? keyboard;
  final String? text;
  final String? key;
  final Map<String, dynamic>? data;

  MouseEvent({
    this.dx,
    this.dy,
    this.click,
    this.scroll,
    this.tap,
    this.gesture,
    this.keyboard,
    this.text,
    this.key,
    this.data,
  });

  factory MouseEvent.move(double dx, double dy) => MouseEvent(dx: dx, dy: dy);

  factory MouseEvent.click(String button) => MouseEvent(click: button);

  factory MouseEvent.scroll(String direction) => MouseEvent(scroll: direction);

  factory MouseEvent.tap(String button) => MouseEvent(tap: button);

  factory MouseEvent.gesture(String gestureType,
          {Map<String, dynamic>? data}) =>
      MouseEvent(gesture: gestureType, data: data);

  factory MouseEvent.keyboard(String action, {String? text, String? key}) =>
      MouseEvent(keyboard: action, text: text, key: key);

  factory MouseEvent.fromJson(Map<String, dynamic> json) =>
      _$MouseEventFromJson(json);

  Map<String, dynamic> toJson() => _$MouseEventToJson(this);

  @override
  String toString() {
    return 'MouseEvent(dx: $dx, dy: $dy, click: $click, scroll: $scroll, tap: $tap, gesture: $gesture, keyboard: $keyboard, text: $text, key: $key, data: $data)';
  }
}
