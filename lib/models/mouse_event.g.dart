// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mouse_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MouseEvent _$MouseEventFromJson(Map<String, dynamic> json) => MouseEvent(
      dx: (json['dx'] as num?)?.toDouble(),
      dy: (json['dy'] as num?)?.toDouble(),
      click: json['click'] as String?,
      scroll: json['scroll'] as String?,
      tap: json['tap'] as String?,
      gesture: json['gesture'] as String?,
      data: json['data'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$MouseEventToJson(MouseEvent instance) =>
    <String, dynamic>{
      'dx': instance.dx,
      'dy': instance.dy,
      'click': instance.click,
      'scroll': instance.scroll,
      'tap': instance.tap,
      'gesture': instance.gesture,
      'data': instance.data,
    };
