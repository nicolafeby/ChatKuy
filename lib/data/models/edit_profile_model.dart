import 'package:chatkuy/data/models/user_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'edit_profile_model.g.dart';

@JsonSerializable(explicitToJson: true)
class EditProfileModel {
  final String name;
  final String email;
  final Gender gender;
  final String username;
  final String phoneNumber;
  final String photoUrl;

  const EditProfileModel({
    required this.email,
    required this.gender,
    required this.name,
    required this.phoneNumber,
    required this.photoUrl,
    required this.username,
  });

  factory EditProfileModel.fromJson(Map<String, dynamic> json) => _$EditProfileModelFromJson(json);

  Map<String, dynamic> toJson() => _$EditProfileModelToJson(this);

  EditProfileModel copyWith({
    String? name,
    String? email,
    Gender? gender,
    String? username,
    String? phoneNumber,
    String? photoUrl,
  }) {
    return EditProfileModel(
      email: email ?? this.email,
      gender: gender ?? this.gender,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      username: username ?? this.username,
    );
  }
}
