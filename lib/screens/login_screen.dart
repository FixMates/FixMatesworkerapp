import 'dart:async';
import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../models/app_user.dart';
import '../models/worker_profile.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/loading_indicator.dart';
import 'worker_main_screen.dart';
import 'worker_profile_setup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  bool _isLoading = false;

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  String? _verificationId;
  int? _resendToken;
  bool _otpSent = false;
  int _timerSeconds = 30;
  Timer? _countdownTimer;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() => _timerSeconds = 30);
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds > 0) {
        setState(() => _timerSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _handlePostLoginNavigation(AppUser appUser) async {
    final WorkerProfile? profile =
        await _firestoreService.getWorkerProfile(appUser.uid);

    if (!mounted) return;

    if (profile != null && profile.isComplete) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const WorkerMainScreen()),
        (route) => false,
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => WorkerProfileSetupScreen(
            isInitialSetup: true,
            existingProfile: profile,
          ),
        ),
        (route) => false,
      );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      final AppUser? appUser = await _authService.signInWithGoogle(
        appRole: AppConstants.roleWorker,
      );

      if (!mounted) return;

      if (appUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      await _handlePostLoginNavigation(appUser);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Google login failed: $e');
      }
    }
  }

  Future<void> _sendOtp() async {
    final rawPhone = _phoneController.text.trim();
    if (rawPhone.isEmpty) {
      _showError('Please enter your 10-digit mobile number');
      return;
    }

    final normalized = AppUtils.normalizePhoneNumber(rawPhone);
    if (normalized.length < 12) {
      _showError('Please enter a valid 10-digit Indian phone number');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.verifyPhoneNumber(
        phoneNumber: normalized,
        resendToken: _resendToken,
        onCodeSent: (verificationId, resendToken) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _resendToken = resendToken;
            _otpSent = true;
            _isLoading = false;
          });
          _startResendTimer();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('6-digit OTP sent successfully.'),
              backgroundColor: AppTheme.success,
            ),
          );
        },
        onVerificationFailed: (e) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          _showError(e.message ?? 'Verification failed.');
        },
        onVerificationCompleted: (credential) async {
          if (credential.smsCode != null && _verificationId != null) {
            _otpController.text = credential.smsCode!;
            await _verifyOtp();
          }
        },
        onCodeAutoRetrievalTimeout: (verificationId) {
          if (mounted) {
            setState(() => _verificationId = verificationId);
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Check your internet and try again ($e).');
      }
    }
  }

  Future<void> _verifyOtp() async {
    final smsCode = _otpController.text.trim();
    if (smsCode.length != 6) {
      _showError('Please enter the complete 6-digit OTP');
      return;
    }

    if (_verificationId == null) {
      _showError('Verification session expired. Please request OTP again.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final appUser = await _authService.verifyOtpAndSignIn(
        verificationId: _verificationId!,
        smsCode: smsCode,
        appRole: AppConstants.roleWorker,
        phoneNumber: AppUtils.normalizePhoneNumber(_phoneController.text),
      );

      if (!mounted) return;

      if (appUser != null) {
        await _handlePostLoginNavigation(appUser);
      } else {
        setState(() => _isLoading = false);
        _showError('Authentication failed.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Invalid OTP code. Please try again.');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const LoadingIndicator(message: 'Authenticating...')
            : Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.build,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      const Text(
                        'FixMates Worker',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Connect with local customers and receive direct daily leads.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Google Sign-In
                      OutlinedButton(
                        onPressed: _handleGoogleSignIn,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: AppTheme.border, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.g_mobiledata, size: 28, color: Colors.blue),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Continue with Google',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (AppConstants.kOtpEnabled) ...[
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            const Expanded(child: Divider(color: AppTheme.border)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'OR USE PHONE',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade500,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                            const Expanded(child: Divider(color: AppTheme.border)),
                          ],
                        ),
                        const SizedBox(height: 20),

                        if (!_otpSent) ...[
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Mobile Number',
                              hintText: '9876543210',
                              prefixIcon: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                child: Text(
                                  '+91',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          ElevatedButton(
                            onPressed: _sendOtp,
                            child: const Text('Send Verification Code'),
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.sms_outlined, color: AppTheme.primary, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '+91 ${_phoneController.text.trim()}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _otpSent = false;
                                          _otpController.clear();
                                        });
                                      },
                                      child: const Text('Change', style: TextStyle(fontSize: 13)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _otpController,
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 8,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: '000000',
                                    counterText: '',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: _verifyOtp,
                                  child: const Text('Verify & Login'),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (_timerSeconds > 0)
                                      Text(
                                        'Resend code in ${_timerSeconds}s',
                                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                      )
                                    else
                                      TextButton(
                                        onPressed: _sendOtp,
                                        child: const Text(
                                          'Resend code',
                                          style: TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],

                      const SizedBox(height: 32),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shield_outlined, size: 14, color: AppTheme.textSecondary),
                          SizedBox(width: 6),
                          Text(
                            'Free registration for all skilled workers',
                            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}