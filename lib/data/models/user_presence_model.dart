import 'package:json_annotation/json_annotation.dart';

part 'user_presence_model.g.dart';

@JsonSerializable(explicitToJson: true)
class UserPresenceModel {
  final bool isOnline;
  final DateTime lastOnlineAt;

  const UserPresenceModel({
    required this.isOnline,
    required this.lastOnlineAt,
  });

  factory UserPresenceModel.fromJson(Map<String, dynamic> json) => _$UserPresenceModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserPresenceModelToJson(this);
}
