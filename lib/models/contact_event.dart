import 'package:cloud_firestore/cloud_firestore.dart';

class ContactEvent {
  final String id;
  final String actorUid;
  final String workerUid;
  final String? leadId;
  final String type; // 'call' or 'whatsapp'
  final DateTime? createdAt;

  ContactEvent({
    required this.id,
    required this.actorUid,
    required this.workerUid,
    this.leadId,
    required this.type,
    this.createdAt,
  });

  factory ContactEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ContactEvent.fromMap(data, doc.id);
  }

  factory ContactEvent.fromMap(Map<String, dynamic> data, String id) {
    return ContactEvent(
      id: id,
      actorUid: data['actorUid'] as String? ?? '',
      workerUid: data['workerUid'] as String? ?? '',
      leadId: data['leadId'] as String?,
      type: data['type'] as String? ?? 'call',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'actorUid': actorUid,
      'workerUid': workerUid,
      'leadId': leadId,
      'type': type,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}