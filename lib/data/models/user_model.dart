import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@HiveType(typeId: 5)
enum Gender {
  @HiveField(0)
  male('Laki-laki'),
  @HiveField(1)
  female('Perempuan'),
  @HiveField(2)
  secret('Rahasia');

  final String value;
  const Gender(this.value);
}

@HiveType(typeId: 6)
@JsonSerializable()
class UserModel {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String? username;
  @HiveField(3)
  final String email;
  @HiveField(4)
  final String? photoUrl;
  @HiveField(5)
  final bool? isEmailVerified;
  @HiveField(6)
  final bool? isOnline;
  @HiveField(7)
  // @TimestampConverter()
  @HiveField(8)
  final DateTime? lastOnlineAt;
  @HiveField(9)
  final String fcmToken;
  @HiveField(10)
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
