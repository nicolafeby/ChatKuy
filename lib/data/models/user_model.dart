import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  final String id;

  final String name;
  final String email;
  final String? photoUrl;

  UserModel({this.id = '', required this.name, required this.email, this.photoUrl});

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  UserModel copyWith({String? id}) {
    return UserModel(id: id ?? this.id, name: name, email: email, photoUrl: photoUrl);
  }
}
