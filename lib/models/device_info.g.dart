// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceInfo _$DeviceInfoFromJson(Map<String, dynamic> json) => DeviceInfo(
      name: json['name'] as String,
      ip: json['ip'] as String,
      port: (json['port'] as num).toInt(),
      id: json['id'] as String?,
      discoveredAt: json['discoveredAt'] == null
          ? null
          : DateTime.parse(json['discoveredAt'] as String),
    );

Map<String, dynamic> _$DeviceInfoToJson(DeviceInfo instance) =>
    <String, dynamic>{
      'name': instance.name,
      'ip': instance.ip,
      'port': instance.port,
      'id': instance.id,
      'discoveredAt': instance.discoveredAt.toIso8601String(),
    };
