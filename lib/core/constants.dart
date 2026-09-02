class AppConstants {
  // App Info
  static const String appName = 'FixMates';
  static const String appTagline = 'Direct Labour Aggregator Platform';

  // User Roles
  static const String roleWorker = 'worker';
  static const String roleCustomer = 'customer';

  // SharedPreferences Keys
  static const String prefUserRole = 'user_role';
  static const String prefUserUid = 'user_uid';
  static const String prefSelectedCity = 'selected_city';

  // Firestore Collections
  static const String collectionUsers = 'users';
  static const String collectionWorkers = 'workers';
  static const String collectionLeads = 'leads';
  static const String collectionContactEvents = 'contactEvents';

  // Lead Statuses
  static const String statusOpen = 'open';
  static const String statusContacted = 'contacted';
  static const String statusClosed = 'closed';

  // Worker Categories (10 standard trade categories)
  static const List<String> categories = [
    'Plumber',
    'Electrician',
    'Carpenter',
    'PVC Fitter',
    'Fabrication',
    'Painter',
    'Mason',
    'Cleaning',
    'Labour',
    'Assembly',
  ];

  // Default WhatsApp Message
  static const String defaultWhatsAppMessage =
      'Hi, I found your profile on FixMates and need help.';

  // Phone OTP Flag
  static const bool kOtpEnabled = true;
}