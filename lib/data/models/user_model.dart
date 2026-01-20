import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

enum Gender {
  male('Laki-laki'),
  female('Perempuan'),
  secret('Rahasia');


  final String value;
  const Gender(this.value);
}

@JsonSerializable()
class UserModel {
  final String id;

  final String name;
  final String? username;
  final String email;
  final String? photoUrl;
  final bool? isEmailVerified;
  final bool? isOnline;
  // @TimestampConverter()
  final DateTime? lastOnlineAt;
  final String fcmToken;
  final Gender? gender;

  UserModel({
    this.id = '',
    required this.name,
    required this.email,
    this.photoUrl,
    required this.isEmailVerified,
    this.isOnline,
    this.username,
    this.lastOnlineAt,
    required this.fcmToken,
    this.gender,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  UserModel copyWith({
    String? id,
    bool? isEmailVerified,
    bool? isOnline,
    DateTime? lastOnlineAt,
    String? fcmToken,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name,
      email: email,
      photoUrl: photoUrl,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isOnline: isOnline ?? this.isOnline,
      username: username,
      lastOnlineAt: lastOnlineAt ?? this.lastOnlineAt,
      fcmToken: fcmToken ?? this.fcmToken,
      gender: gender,
    );
  }
}
