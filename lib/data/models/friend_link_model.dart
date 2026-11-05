import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'friend_link_model.g.dart';

@JsonSerializable(createFactory: false, includeIfNull: false)
class FriendLinkModel {
  final String uid;
  final String requestId;

  const FriendLinkModel({
    required this.uid,
    required this.requestId,
  });

  Map<String, dynamic> toJson() => _$FriendLinkModelToJson(this);

  Map<String, dynamic> toFirestoreJson() {
    return {
      ...toJson(),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
