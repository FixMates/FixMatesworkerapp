import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../models/app_user.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirestoreService _firestoreService = FirestoreService();

  // Current Firebase User
  User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with Google and handle user document creation/retrieval in Firestore.
  /// Always saves user with the given [appRole] ('worker' or 'customer').
  Future<AppUser?> signInWithGoogle({required String appRole}) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled popup
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final User? firebaseUser = userCredential.user;

      if (firebaseUser == null) return null;

      // Check if user already exists in Firestore
      AppUser? appUser = await _firestoreService.getUser(firebaseUser.uid);

      if (appUser == null) {
        // New user: Create user document with the designated role
        appUser = AppUser(
          uid: firebaseUser.uid,
          name: firebaseUser.displayName ?? googleUser.displayName ?? 'User',
          email: firebaseUser.email ?? googleUser.email,
          phone: firebaseUser.phoneNumber ?? '',
          photoUrl: firebaseUser.photoURL ?? googleUser.photoUrl ?? '',
          role: appRole,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _firestoreService.saveUser(appUser);
      }

      // Cache session locally
      await saveCachedSession(appUser.uid, appUser.role);

      return appUser;
    } catch (e) {
      rethrow;
    }
  }

  /// Request SMS OTP to the provided [phoneNumber]
  /// Note: Phone OTP has per-message cost on Firebase; Google Login is 100% free and recommended.
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(FirebaseAuthException e) onVerificationFailed,
    required Function(PhoneAuthCredential credential) onVerificationCompleted,
    required Function(String verificationId) onCodeAutoRetrievalTimeout,
    int? resendToken,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      forceResendingToken: resendToken,
      verificationCompleted: onVerificationCompleted,
      verificationFailed: onVerificationFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout,
    );
  }

  /// Verify OTP code and sign in to Firebase
  Future<AppUser?> verifyOtpAndSignIn({
    required String verificationId,
    required String smsCode,
    required String appRole,
    String? phoneNumber,
  }) async {
    try {
      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final User? firebaseUser = userCredential.user;

      if (firebaseUser == null) return null;

      // Check if user already exists in Firestore
      AppUser? appUser = await _firestoreService.getUser(firebaseUser.uid);

      if (appUser == null) {
        appUser = AppUser(
          uid: firebaseUser.uid,
          name: firebaseUser.displayName ?? 'User',
          email: firebaseUser.email ?? '',
          phone: firebaseUser.phoneNumber ?? phoneNumber ?? '',
          photoUrl: firebaseUser.photoURL ?? '',
          role: appRole,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _firestoreService.saveUser(appUser);
      }

      // Cache session locally
      await saveCachedSession(appUser.uid, appUser.role);

      return appUser;
    } catch (e) {
      rethrow;
    }
  }

  /// Cache user session in SharedPreferences
  Future<void> saveCachedSession(String uid, String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefUserUid, uid);
    await prefs.setString(AppConstants.prefUserRole, role);
  }

  /// Get cached session from SharedPreferences
  Future<Map<String, String?>?> getCachedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString(AppConstants.prefUserUid);
    final role = prefs.getString(AppConstants.prefUserRole);
    if (uid != null && role != null) {
      return {'uid': uid, 'role': role};
    }
    return null;
  }

  /// Clear cached session
  Future<void> clearCachedSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.prefUserUid);
    await prefs.remove(AppConstants.prefUserRole);
  }

  /// Sign out from Firebase and Google, and clear cached session
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
    await clearCachedSession();
  }
}