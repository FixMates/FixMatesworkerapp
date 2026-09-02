import 'package:cloud_firestore/cloud_firestore.dart';

class WorkerProfile {
  final String uid;
  final String name;
  final String phone;
  final String whatsapp;
  final String category;
  final List<String> skills;
  final String city;
  final String area;
  final int experienceYears;
  final String expectedCharges;
  final String bio;
  final bool consentGiven;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  WorkerProfile({
    required this.uid,
    required this.name,
    required this.phone,
    this.whatsapp = '',
    required this.category,
    this.skills = const [],
    required this.city,
    this.area = '',
    this.experienceYears = 0,
    this.expectedCharges = '',
    this.bio = '',
    this.consentGiven = false,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  /// Check if the worker profile has the minimum required fields completed
  bool get isComplete {
    return name.trim().isNotEmpty &&
        phone.trim().isNotEmpty &&
        category.trim().isNotEmpty &&
        city.trim().isNotEmpty &&
        consentGiven == true;
  }

  /// Get WhatsApp number, falling back to phone if whatsapp is empty
  String get effectiveWhatsApp {
    return whatsapp.trim().isNotEmpty ? whatsapp.trim() : phone.trim();
  }

  /// Skills as comma-separated string for display/editing
  String get skillsFormatted => skills.join(', ');

  factory WorkerProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return WorkerProfile.fromMap(data, doc.id);
  }

  factory WorkerProfile.fromMap(Map<String, dynamic> data, String uid) {
    return WorkerProfile(
      uid: uid,
      name: data['name'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      whatsapp: data['whatsapp'] as String? ?? '',
      category: data['category'] as String? ?? '',
      skills: (data['skills'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      city: data['city'] as String? ?? '',
      area: data['area'] as String? ?? '',
      experienceYears: (data['experienceYears'] as num?)?.toInt() ?? 0,
      expectedCharges: data['expectedCharges'] as String? ?? '',
      bio: data['bio'] as String? ?? '',
      consentGiven: data['consentGiven'] as bool? ?? false,
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name.trim(),
      'phone': phone.trim(),
      'whatsapp': effectiveWhatsApp,
      'category': category.trim(),
      'skills': skills,
      'city': city.trim(),
      'area': area.trim(),
      'experienceYears': experienceYears,
      'expectedCharges': expectedCharges.trim(),
      'bio': bio.trim(),
      'consentGiven': consentGiven,
      'isActive': isActive,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  WorkerProfile copyWith({
    String? uid,
    String? name,
    String? phone,
    String? whatsapp,
    String? category,
    List<String>? skills,
    String? city,
    String? area,
    int? experienceYears,
    String? expectedCharges,
    String? bio,
    bool? consentGiven,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorkerProfile(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      whatsapp: whatsapp ?? this.whatsapp,
      category: category ?? this.category,
      skills: skills ?? this.skills,
      city: city ?? this.city,
      area: area ?? this.area,
      experienceYears: experienceYears ?? this.experienceYears,
      expectedCharges: expectedCharges ?? this.expectedCharges,
      bio: bio ?? this.bio,
      consentGiven: consentGiven ?? this.consentGiven,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}