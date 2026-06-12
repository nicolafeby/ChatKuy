import 'package:chatkuy/core/constants/app_strings.dart';
import 'package:chatkuy/core/constants/firestore.dart';
import 'package:chatkuy/core/utils/extension/user_model_fields.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_update_model.g.dart';

@JsonSerializable(createFactory: false, includeIfNull: false)
class UserUpdateModel {
  @JsonKey(name: AppStrings.fcmToken)
  final String? fcmToken;

  @JsonKey(name: FriendField.photoUrl)
  final String? photoUrl;

  final String? accountStatus;
  final bool? isOnline;

  @JsonKey(includeToJson: false)
  final bool updatePhotoUrl;

  @JsonKey(includeToJson: false)
  final bool markDeletionRequested;

  const UserUpdateModel({
    this.fcmToken,
    this.photoUrl,
    this.accountStatus,
    this.isOnline,
    this.updatePhotoUrl = false,
    this.markDeletionRequested = false,
  });

  const UserUpdateModel.fcmToken(String token) : this(fcmToken: token);

  const UserUpdateModel.profilePicture(String? imageUrl)
      : this(
          photoUrl: imageUrl,
          updatePhotoUrl: true,
        );

  const UserUpdateModel.accountDeletionRequested()
      : this(
          accountStatus: AccountStatus.pendingDelete,
          isOnline: false,
          fcmToken: '',
          markDeletionRequested: true,
        );

  Map<String, dynamic> toJson() => _$UserUpdateModelToJson(this);

  Map<String, dynamic> toFirestoreJson() {
    return {
      ...toJson(),
      if (updatePhotoUrl) FriendField.photoUrl: photoUrl,
      if (markDeletionRequested)
        UserModelFields.deletionRequestedAt: FieldValue.serverTimestamp(),
    };
  }
}

abstract class AccountStatus {
  static const pendingDelete = 'pending_delete';
  static const deleted = 'deleted';
}
