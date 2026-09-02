import 'package:cloud_firestore/cloud_firestore.dart';

class Lead {
  final String id;
  final String customerUid;
  final String customerName;
  final String customerPhone;
  final String category;
  final String city;
  final String area;
  final String description;
  final String status; // 'open', 'contacted', 'closed'
  final DateTime? createdAt;

  Lead({
    required this.id,
    required this.customerUid,
    required this.customerName,
    required this.customerPhone,
    required this.category,
    required this.city,
    this.area = '',
    required this.description,
    this.status = 'open',
    this.createdAt,
  });

  bool get isOpen => status == 'open';
  bool get isContacted => status == 'contacted';
  bool get isClosed => status == 'closed';

  factory Lead.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Lead.fromMap(data, doc.id);
  }

  factory Lead.fromMap(Map<String, dynamic> data, String id) {
    return Lead(
      id: id,
      customerUid: data['customerUid'] as String? ?? '',
      customerName: data['customerName'] as String? ?? '',
      customerPhone: data['customerPhone'] as String? ?? '',
      category: data['category'] as String? ?? '',
      city: data['city'] as String? ?? '',
      area: data['area'] as String? ?? '',
      description: data['description'] as String? ?? '',
      status: data['status'] as String? ?? 'open',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerUid': customerUid,
      'customerName': customerName.trim(),
      'customerPhone': customerPhone.trim(),
      'category': category.trim(),
      'city': city.trim(),
      'area': area.trim(),
      'description': description.trim(),
      'status': status,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  Lead copyWith({
    String? id,
    String? customerUid,
    String? customerName,
    String? customerPhone,
    String? category,
    String? city,
    String? area,
    String? description,
    String? status,
    DateTime? createdAt,
  }) {
    return Lead(
      id: id ?? this.id,
      customerUid: customerUid ?? this.customerUid,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      category: category ?? this.category,
      city: city ?? this.city,
      area: area ?? this.area,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}