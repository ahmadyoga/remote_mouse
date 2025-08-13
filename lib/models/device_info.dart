import 'package:json_annotation/json_annotation.dart';

part 'device_info.g.dart';

@JsonSerializable()
class DeviceInfo {
  final String name;
  final String ip;
  final int port;
  final String? id;
  final DateTime discoveredAt;

  DeviceInfo({
    required this.name,
    required this.ip,
    required this.port,
    this.id,
    DateTime? discoveredAt,
  }) : discoveredAt = discoveredAt ?? DateTime.now();

  factory DeviceInfo.fromJson(Map<String, dynamic> json) =>
      _$DeviceInfoFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceInfoToJson(this);

  @override
  String toString() {
    return 'DeviceInfo(name: $name, ip: $ip, port: $port, id: $id)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeviceInfo &&
        other.name == name &&
        other.ip == ip &&
        other.port == port;
  }

  @override
  int get hashCode => Object.hash(name, ip, port);
}
