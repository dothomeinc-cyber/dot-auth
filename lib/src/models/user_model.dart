import 'package:firebase_auth/firebase_auth.dart';

/// Immutable model representing a signed-in Firebase user.
///
/// Created automatically from [FirebaseAuth.instance.currentUser] via
/// [UserModel.fromFirebaseUser]. Exposed through [currentUserProvider].
class UserModel {
  /// Firebase UID — always present.
  final String uid;

  /// Phone number if user signed in with phone auth.
  final String? phoneNumber;

  /// Email address if user signed in with email auth.
  final String? email;

  /// Display name from Firebase profile.
  final String? displayName;

  /// Photo URL from Firebase profile.
  final String? photoURL;

  /// Account creation timestamp.
  final DateTime? creationTime;

  /// Last sign-in timestamp.
  final DateTime? lastSignInTime;

  /// Whether the user's email address has been verified.
  final bool isEmailVerified;

  /// Whether the user signed in with a phone number.
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

  /// Creates a [UserModel] from a Firebase [User] object.
  factory UserModel.fromFirebaseUser(User firebaseUser) {
    return UserModel(
      uid: firebaseUser.uid,
      phoneNumber: firebaseUser.phoneNumber,
      email: firebaseUser.email,
      displayName: firebaseUser.displayName,
      photoURL: firebaseUser.photoURL,
      creationTime: firebaseUser.metadata.creationTime,
      lastSignInTime: firebaseUser.metadata.lastSignInTime,
      isEmailVerified: firebaseUser.emailVerified,
      isPhoneVerified: firebaseUser.phoneNumber != null,
    );
  }

  /// Empty user — useful as a null-safe sentinel.
  static const UserModel empty = UserModel(uid: '');

  /// Returns a copy with the given fields replaced.
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

  /// Serialises to a JSON-compatible map.
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

  /// Deserialises from a JSON-compatible map.
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
  String toString() =>
      'UserModel(uid: $uid, phoneNumber: $phoneNumber, email: $email)';
}
