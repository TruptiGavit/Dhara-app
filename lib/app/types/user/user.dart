import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class UserRM {
  @JsonKey(name: 'first_name')
  final String? firstName;

  @JsonKey(name: 'last_name')
  final String? lastName;

  final String? name;

  final String? email;

  final String? picture;

  UserRM({this.name, this.firstName, this.lastName, this.email, this.picture});

  factory UserRM.fromJson(Map<String, dynamic> json) => _$UserRMFromJson(json);
  Map<String, dynamic> toJson() => _$UserRMToJson(this);

  String? getName() {
    if (name != null && name!.isNotEmpty) {
      return name;
    } 
    // else if (firstName != null && lastName != null) {
    //   return "$firstName $lastName";
    // } else 
    
    if (firstName != null) {
      return firstName;
    } else if (lastName != null) {
      return lastName;
    }

    return null;
  }
}
