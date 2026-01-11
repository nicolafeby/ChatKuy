import 'package:json_annotation/json_annotation.dart';
import 'package:chatkuy/data/models/user_model.dart';

part 'friend_model.g.dart';

@JsonSerializable(explicitToJson: true)
class FriendModel {
  final String uid;
  final UserModel user;
  final DateTime createdAt;

  FriendModel({
    required this.uid,
    required this.user,
    required this.createdAt,
  });

  factory FriendModel.fromJson(Map<String, dynamic> json) => _$FriendModelFromJson(json);

  Map<String, dynamic> toJson() => _$FriendModelToJson(this);
}
