import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants.dart';
import '../models/app_user.dart';
import '../models/contact_event.dart';
import '../models/lead.dart';
import '../models/worker_profile.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _usersCollection =>
      _firestore.collection(AppConstants.collectionUsers);
  CollectionReference get _workersCollection =>
      _firestore.collection(AppConstants.collectionWorkers);
  CollectionReference get _leadsCollection =>
      _firestore.collection(AppConstants.collectionLeads);
  CollectionReference get _contactEventsCollection =>
      _firestore.collection(AppConstants.collectionContactEvents);

  // ================= USERS =================

  Future<void> saveUser(AppUser user) async {
    await _usersCollection.doc(user.uid).set(user.toMap(), SetOptions(merge: true));
  }

  Future<AppUser?> getUser(String uid) async {
    final doc = await _usersCollection.doc(uid).get();
    if (doc.exists) {
      return AppUser.fromFirestore(doc);
    }
    return null;
  }

  // ================= WORKERS =================

  Future<void> saveWorkerProfile(WorkerProfile profile) async {
    await _workersCollection
        .doc(profile.uid)
        .set(profile.toMap(), SetOptions(merge: true));
  }

  Future<WorkerProfile?> getWorkerProfile(String uid) async {
    final doc = await _workersCollection.doc(uid).get();
    if (doc.exists) {
      return WorkerProfile.fromFirestore(doc);
    }
    return null;
  }

  Stream<WorkerProfile?> streamWorkerProfile(String uid) {
    return _workersCollection.doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return WorkerProfile.fromFirestore(doc);
      }
      return null;
    });
  }

  Stream<List<WorkerProfile>> streamActiveWorkers() {
    return _workersCollection
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => WorkerProfile.fromFirestore(doc))
          .where((w) => w.consentGiven == true)
          .toList();
    });
  }

  // ================= LEADS =================

  Future<void> createLead(Lead lead) async {
    await _leadsCollection.add(lead.toMap());
  }

  Stream<List<Lead>> streamOpenLeads() {
    return _leadsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Lead.fromFirestore(doc))
          .where((l) => l.status != AppConstants.statusClosed)
          .toList();
    });
  }

  Stream<List<Lead>> streamMyLeads(String customerUid) {
    return _leadsCollection
        .where('customerUid', isEqualTo: customerUid)
        .snapshots()
        .map((snapshot) {
      final leads = snapshot.docs.map((doc) => Lead.fromFirestore(doc)).toList();
      leads.sort((a, b) {
        final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      return leads;
    });
  }

  Future<void> updateLeadStatus(String leadId, String status) async {
    try {
      await _leadsCollection.doc(leadId).update({'status': status});
    } catch (_) {}
  }

  // ================= CONTACT EVENTS & STATS =================

  Future<void> logContactEvent({
    required String actorUid,
    required String workerUid,
    String? leadId,
    required String type,
  }) async {
    try {
      await _contactEventsCollection.add({
        'actorUid': actorUid,
        'workerUid': workerUid,
        'leadId': leadId,
        'type': type,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Stream<Map<String, int>> streamWorkerStats(String workerUid) {
    return _contactEventsCollection.snapshots().map((snapshot) {
      final events =
          snapshot.docs.map((doc) => ContactEvent.fromFirestore(doc)).toList();

      final workerEvents = events.where((e) => e.workerUid == workerUid).toList();
      final totalViews = workerEvents.length;
      final whatsappClicks =
          workerEvents.where((e) => e.type == 'whatsapp').length;
      final leadsContacted = events
          .where((e) =>
              e.actorUid == workerUid &&
              e.leadId != null &&
              e.leadId!.isNotEmpty)
          .length;

      return {
        'views': totalViews,
        'chats': whatsappClicks,
        'leads': leadsContacted,
      };
    });
  }

  Stream<int> streamContactCountForLead(String leadId) {
    return _contactEventsCollection
        .where('leadId', isEqualTo: leadId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // ================= DEBUG / SEEDING =================

  Future<void> seedSampleWorkers() async {
    final sampleWorkers = [
      WorkerProfile(
        uid: 'sample_worker_1',
        name: 'Ramesh Sharma',
        phone: '+919876543210',
        whatsapp: '+919876543210',
        category: 'Plumber',
        skills: ['Pipe repair', 'Tap replacement', 'Bathroom fitting', 'Water tank cleaning'],
        city: 'Bangalore',
        area: 'Indiranagar',
        experienceYears: 7,
        expectedCharges: '350',
        bio: 'Experienced residential plumber with 7+ years in water fittings and leak repairs.',
        consentGiven: true,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      WorkerProfile(
        uid: 'sample_worker_2',
        name: 'Suresh Kumar',
        phone: '+919811223344',
        whatsapp: '+919811223344',
        category: 'Electrician',
        skills: ['Wiring', 'Switchboard installation', 'Inverter repair', 'MCB fix'],
        city: 'Bangalore',
        area: 'Koramangala',
        experienceYears: 5,
        expectedCharges: '300',
        bio: 'Certified electrician for home wirings, short circuit issues, and all electrical fittings.',
        consentGiven: true,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      WorkerProfile(
        uid: 'sample_worker_3',
        name: 'Manjunath Gowda',
        phone: '+919845012345',
        whatsapp: '+919845012345',
        category: 'Carpenter',
        skills: ['Furniture assembly', 'Door repair', 'Modular kitchen', 'Wardrobe repair'],
        city: 'Bangalore',
        area: 'HSR Layout',
        experienceYears: 10,
        expectedCharges: '500',
        bio: 'Master carpenter specializing in modern modular furniture and door repair.',
        consentGiven: true,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      WorkerProfile(
        uid: 'sample_worker_4',
        name: 'Mohammad Rafiq',
        phone: '+919890123456',
        whatsapp: '+919890123456',
        category: 'Painter',
        skills: ['Interior painting', 'Exterior emulsion', 'Texture art', 'Waterproofing'],
        city: 'Bangalore',
        area: 'Whitefield',
        experienceYears: 6,
        expectedCharges: '400',
        bio: 'Fast and clean painting services with top brands like Asian Paints and Berger.',
        consentGiven: true,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      WorkerProfile(
        uid: 'sample_worker_5',
        name: 'Vikram Singh',
        phone: '+919829012345',
        whatsapp: '+919829012345',
        category: 'Fabrication',
        skills: ['Grill welding', 'Iron gate repair', 'Rooftop fabrication', 'Shutter repair'],
        city: 'Bangalore',
        area: 'Hebbal',
        experienceYears: 8,
        expectedCharges: '600',
        bio: 'Expert in mild steel and stainless steel fabrication, window grills, and gates.',
        consentGiven: true,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    for (final worker in sampleWorkers) {
      await saveWorkerProfile(worker);
    }
  }
}