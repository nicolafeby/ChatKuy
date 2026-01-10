import 'package:json_annotation/json_annotation.dart';

part 'friend_model.g.dart';

@JsonSerializable()
class FriendModel {
  final String uid;
  final String username;
  final String? displayName;
  final String? photoUrl;
  final DateTime createdAt;

  FriendModel({
    required this.uid,
    required this.username,
    this.displayName,
    this.photoUrl,
    required this.createdAt,
  });

  factory FriendModel.fromJson(Map<String, dynamic> json) =>
      _$FriendModelFromJson(json);

  Map<String, dynamic> toJson() => _$FriendModelToJson(this);
}
