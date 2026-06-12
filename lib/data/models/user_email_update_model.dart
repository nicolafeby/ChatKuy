import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_email_update_model.g.dart';

@JsonSerializable(createFactory: false, includeIfNull: false)
class UserEmailUpdateModel {
  final String? email;
  final String? pendingEmail;
  final bool? isEmailVerified;
  final bool? isOnline;

  @JsonKey(toJson: _dateToFirestore)
  final DateTime? lastOnlineAt;

  @JsonKey(includeToJson: false)
  final bool clearPendingEmail;

  const UserEmailUpdateModel({
    this.email,
    this.pendingEmail,
    this.isEmailVerified,
    this.isOnline,
    this.lastOnlineAt,
    this.clearPendingEmail = false,
  });

  const UserEmailUpdateModel.pendingVerification({
    required String email,
  }) : this(pendingEmail: email);

  const UserEmailUpdateModel.verified({
    required String email,
  }) : this(
          email: email,
          isEmailVerified: true,
          clearPendingEmail: true,
        );

  const UserEmailUpdateModel.loginVerified({
    required String email,
    required DateTime lastOnlineAt,
  }) : this(
          email: email,
          isOnline: true,
          lastOnlineAt: lastOnlineAt,
          clearPendingEmail: true,
        );

  Map<String, dynamic> toJson() => _$UserEmailUpdateModelToJson(this);

  Map<String, dynamic> toFirestoreJson() {
    return {
      ...toJson(),
      if (clearPendingEmail) 'pendingEmail': FieldValue.delete(),
    };
  }

  static DateTime? _dateToFirestore(DateTime? value) => value;
}
