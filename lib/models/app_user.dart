import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String photoUrl;
  final String role; // 'worker' or 'customer'
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AppUser({
    required this.uid,
    required this.name,
    this.email = '',
    this.phone = '',
    this.photoUrl = '',
    required this.role,
    this.createdAt,
    this.updatedAt,
  });

  bool get isWorker => role == 'worker';
  bool get isCustomer => role == 'customer';

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AppUser.fromMap(data, doc.id);
  }

  factory AppUser.fromMap(Map<String, dynamic> data, String uid) {
    return AppUser(
      uid: uid,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      photoUrl: data['photoUrl'] as String? ?? '',
      role: data['role'] as String? ?? 'customer',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'photoUrl': photoUrl.trim(),
      'role': role,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  AppUser copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
    String? role,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}