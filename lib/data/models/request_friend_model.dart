import 'package:chatkuy/core/constants/firestore.dart';
import 'package:chatkuy/core/utils/converter/timestamp_converter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'request_friend_model.g.dart';

@JsonSerializable()
class FriendRequestModel {
  final String id;
  final String fromUid;
  final String toUid;

  final String username;
  final String displayName;
  final String? photoUrl;

  final String status;

  @TimestampConverter()
  final DateTime createdAt;

  FriendRequestModel({
    required this.id,
    required this.fromUid,
    required this.toUid,
    required this.username,
    required this.displayName,
    this.photoUrl,
    required this.status,
    required this.createdAt,
  });

  factory FriendRequestModel.fromJson(Map<String, dynamic> json) =>
      _$FriendRequestModelFromJson(json);

  Map<String, dynamic> toJson() =>
      _$FriendRequestModelToJson(this);

  /// 🔥 KHUSUS CREATE (tanpa id & serverTimestamp)
  Map<String, dynamic> toCreateJson() {
    final json = toJson();
    json.remove('id');
    json[FriendRequestField.createdAt] =
        FieldValue.serverTimestamp();
    return json;
  }

  factory FriendRequestModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return FriendRequestModel.fromJson({
      ...doc.data()!,
      'id': doc.id,
    });
  }
}
