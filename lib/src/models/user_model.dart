import 'package:firebase_auth/firebase_auth.dart';

class UserModel {
  final String uid;
  final String? phoneNumber;
  final String? email;
  final String? displayName;
  final String? photoURL;
  final DateTime? creationTime;
  final DateTime? lastSignInTime;
  final bool isEmailVerified;
  final bool isPhoneVerified;

  const UserModel({
    required this.uid,
    this.phoneNumber,
    this.email,
    this.displayName,
    this.photoURL,
    this.creationTime,
    this.lastSignInTime,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
  });

  factory UserModel.fromFirebaseUser(User firebaseUser) {
    return UserModel(
      uid: firebaseUser.uid,
      phoneNumber: firebaseUser.phoneNumber,
      email: firebaseUser.email,
      displayName: firebaseUser.displayName,
      photoURL: firebaseUser.photoURL,
      // Fixed: removed unnecessary ?. operator
      creationTime: firebaseUser.metadata.creationTime,
      lastSignInTime: firebaseUser.metadata.lastSignInTime,
      isEmailVerified: firebaseUser.emailVerified,
      isPhoneVerified: firebaseUser.phoneNumber != null,
    );
  }

  static const UserModel empty = UserModel(uid: '');

  UserModel copyWith({
    String? uid,
    String? phoneNumber,
    String? email,
    String? displayName,
    String? photoURL,
    DateTime? creationTime,
    DateTime? lastSignInTime,
    bool? isEmailVerified,
    bool? isPhoneVerified,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      creationTime: creationTime ?? this.creationTime,
      lastSignInTime: lastSignInTime ?? this.lastSignInTime,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'phoneNumber': phoneNumber,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'creationTime': creationTime?.toIso8601String(),
      'lastSignInTime': lastSignInTime?.toIso8601String(),
      'isEmailVerified': isEmailVerified,
      'isPhoneVerified': isPhoneVerified,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      photoURL: json['photoURL'] as String?,
      creationTime: json['creationTime'] != null
          ? DateTime.parse(json['creationTime'] as String)
          : null,
      lastSignInTime: json['lastSignInTime'] != null
          ? DateTime.parse(json['lastSignInTime'] as String)
          : null,
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      isPhoneVerified: json['isPhoneVerified'] as bool? ?? false,
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, phoneNumber: $phoneNumber, email: $email)';
  }
}
