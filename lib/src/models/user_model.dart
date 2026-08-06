import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '_copy_with.dart';

/// Immutable snapshot of a signed-in Firebase user.
///
/// Built from [User] by [UserModel.fromFirebaseUser] and exposed through
/// `currentUserProvider`.
@immutable
class UserModel {
  /// Firebase UID — always present.
  final String uid;

  /// Phone number if the user has a phone credential.
  final String? phoneNumber;

  /// Email address if the user has an email credential.
  final String? email;

  /// Display name from the Firebase profile.
  final String? displayName;

  /// Photo URL from the Firebase profile.
  final String? photoURL;

  /// Account creation timestamp.
  final DateTime? creationTime;

  /// Last sign-in timestamp.
  final DateTime? lastSignInTime;

  /// Whether the email address has been verified.
  final bool isEmailVerified;

  /// Sign-in methods connected to this account, e.g. `['phone', 'password']`.
  final List<String> providerIds;

  const UserModel({
    required this.uid,
    this.phoneNumber,
    this.email,
    this.displayName,
    this.photoURL,
    this.creationTime,
    this.lastSignInTime,
    this.isEmailVerified = false,
    this.providerIds = const [],
  });

  /// Builds a [UserModel] from a Firebase [User].
  factory UserModel.fromFirebaseUser(User user) {
    return UserModel(
      uid: user.uid,
      phoneNumber: user.phoneNumber,
      email: user.email,
      displayName: user.displayName,
      photoURL: user.photoURL,
      creationTime: user.metadata.creationTime,
      lastSignInTime: user.metadata.lastSignInTime,
      isEmailVerified: user.emailVerified,
      providerIds: user.providerData.map((p) => p.providerId).toList(),
    );
  }

  /// Empty user — a null-safe sentinel.
  static const UserModel empty = UserModel(uid: '');

  /// `true` when this instance carries no real user.
  bool get isEmpty => uid.isEmpty;

  /// `true` when a phone credential is connected.
  bool get hasPhoneProvider => providerIds.contains('phone');

  /// `true` when an email/password credential is connected.
  bool get hasPasswordProvider => providerIds.contains('password');

  /// Kept so 1.x call sites keep compiling. Prefer [hasPhoneProvider].
  ///
  /// The old name implied a verification step of its own; there isn't one.
  /// A phone credential on the account *is* the proof.
  @Deprecated('Renamed to hasPhoneProvider. Will be removed in 3.0.0.')
  bool get isPhoneVerified => hasPhoneProvider;

  /// Returns a copy with the given fields replaced.
  ///
  /// Nullable fields accept an explicit `null` to clear them.
  UserModel copyWith({
    String? uid,
    Object? phoneNumber = kUnset,
    Object? email = kUnset,
    Object? displayName = kUnset,
    Object? photoURL = kUnset,
    Object? creationTime = kUnset,
    Object? lastSignInTime = kUnset,
    bool? isEmailVerified,
    List<String>? providerIds,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      phoneNumber: pick<String>(phoneNumber, this.phoneNumber),
      email: pick<String>(email, this.email),
      displayName: pick<String>(displayName, this.displayName),
      photoURL: pick<String>(photoURL, this.photoURL),
      creationTime: pick<DateTime>(creationTime, this.creationTime),
      lastSignInTime: pick<DateTime>(lastSignInTime, this.lastSignInTime),
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      providerIds: providerIds ?? this.providerIds,
    );
  }

  /// Serialises to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'uid': uid,
        'phoneNumber': phoneNumber,
        'email': email,
        'displayName': displayName,
        'photoURL': photoURL,
        'creationTime': creationTime?.toIso8601String(),
        'lastSignInTime': lastSignInTime?.toIso8601String(),
        'isEmailVerified': isEmailVerified,
        'providerIds': providerIds,
      };

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
      providerIds:
          (json['providerIds'] as List?)?.cast<String>() ?? const <String>[],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.uid == uid &&
        other.phoneNumber == phoneNumber &&
        other.email == email &&
        other.displayName == displayName &&
        other.photoURL == photoURL &&
        other.creationTime == creationTime &&
        other.lastSignInTime == lastSignInTime &&
        other.isEmailVerified == isEmailVerified &&
        listEquals(other.providerIds, providerIds);
  }

  @override
  int get hashCode => Object.hash(
        uid,
        phoneNumber,
        email,
        displayName,
        photoURL,
        creationTime,
        lastSignInTime,
        isEmailVerified,
        Object.hashAll(providerIds),
      );

  @override
  String toString() =>
      'UserModel(uid: $uid, phone: $phoneNumber, email: $email, '
      'providers: $providerIds)';
}
