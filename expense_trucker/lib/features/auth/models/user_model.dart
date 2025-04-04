class UserModel {
  final String uid;
  final String email;
  final String name;
  final String? photoUrl;
  final String preferredCurrency;
  final DateTime createdAt;
  final DateTime lastUpdated;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.photoUrl,
    required this.preferredCurrency,
    required this.createdAt,
    required this.lastUpdated,
  });

  // Create a new user from Firebase auth
  factory UserModel.createNew({
    required String uid,
    required String email,
    required String name,
    String? photoUrl,
    String preferredCurrency = 'ETB',
  }) {
    final now = DateTime.now();
    return UserModel(
      uid: uid,
      email: email,
      name: name,
      photoUrl: photoUrl,
      preferredCurrency: preferredCurrency,
      createdAt: now,
      lastUpdated: now,
    );
  }

  // Create from Json (Firestore)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      photoUrl: json['photoUrl'] as String?,
      preferredCurrency: json['preferredCurrency'] as String? ?? 'ETB',
      createdAt: (json['createdAt'] as Map<String, dynamic>?)?['_seconds'] !=
              null
          ? DateTime.fromMillisecondsSinceEpoch(
              ((json['createdAt'] as Map<String, dynamic>)['_seconds'] as int) *
                  1000,
            )
          : DateTime.now(),
      lastUpdated:
          (json['lastUpdated'] as Map<String, dynamic>?)?['_seconds'] != null
              ? DateTime.fromMillisecondsSinceEpoch(
                  ((json['lastUpdated'] as Map<String, dynamic>)['_seconds']
                          as int) *
                      1000,
                )
              : DateTime.now(),
    );
  }

  // Convert to Json (Firestore)
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'preferredCurrency': preferredCurrency,
      'createdAt': createdAt,
      'lastUpdated': lastUpdated,
    };
  }

  // Clone with method to update user properties
  UserModel copyWith({
    String? name,
    String? photoUrl,
    String? preferredCurrency,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      preferredCurrency: preferredCurrency ?? this.preferredCurrency,
      createdAt: createdAt,
      lastUpdated: DateTime.now(),
    );
  }
}
