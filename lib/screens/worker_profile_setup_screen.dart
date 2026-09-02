import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../models/worker_profile.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/category_dropdown.dart';
import '../widgets/loading_indicator.dart';
import 'worker_main_screen.dart';

class WorkerProfileSetupScreen extends StatefulWidget {
  final bool isInitialSetup;
  final WorkerProfile? existingProfile;

  const WorkerProfileSetupScreen({
    super.key,
    this.isInitialSetup = false,
    this.existingProfile,
  });

  @override
  State<WorkerProfileSetupScreen> createState() => _WorkerProfileSetupScreenState();
}

class _WorkerProfileSetupScreenState extends State<WorkerProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _whatsappController;
  late TextEditingController _cityController;
  late TextEditingController _areaController;
  late TextEditingController _experienceController;
  late TextEditingController _chargesController;
  late TextEditingController _bioController;
  late TextEditingController _skillInputController;

  String? _selectedCategory;
  List<String> _skills = [];
  bool _consentGiven = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final p = widget.existingProfile;
    final user = _authService.currentUser;

    _nameController = TextEditingController(text: p?.name ?? user?.displayName ?? '');
    _phoneController = TextEditingController(
      text: p?.phone.isNotEmpty == true
          ? AppUtils.extractDigits(p!.phone)
          : (user?.phoneNumber != null ? AppUtils.extractDigits(user!.phoneNumber!) : ''),
    );
    _whatsappController = TextEditingController(text: p?.whatsapp ?? '');
    _cityController = TextEditingController(text: p?.city ?? '');
    _areaController = TextEditingController(text: p?.area ?? '');
    _experienceController =
        TextEditingController(text: p != null && p.experienceYears > 0 ? p.experienceYears.toString() : '');
    _chargesController = TextEditingController(text: p?.expectedCharges ?? '');
    _bioController = TextEditingController(text: p?.bio ?? '');
    _skillInputController = TextEditingController();

    _selectedCategory = p?.category;
    _skills = p?.skills != null ? List<String>.from(p!.skills) : [];
    _consentGiven = p?.consentGiven ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _cityController.dispose();
    _areaController.dispose();
    _experienceController.dispose();
    _chargesController.dispose();
    _bioController.dispose();
    _skillInputController.dispose();
    super.dispose();
  }

  void _addSkill() {
    final skill = _skillInputController.text.trim();
    if (skill.isNotEmpty && !_skills.contains(skill)) {
      setState(() {
        _skills.add(skill);
        _skillInputController.clear();
      });
    }
  }

  void _removeSkill(String skill) {
    setState(() => _skills.remove(skill));
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_consentGiven) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the consent to display contact details to customers.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final user = _authService.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final updatedProfile = WorkerProfile(
        uid: user.uid,
        name: _nameController.text.trim(),
        phone: AppUtils.normalizePhoneNumber(_phoneController.text),
        whatsapp: _whatsappController.text.trim().isNotEmpty
            ? AppUtils.normalizePhoneNumber(_whatsappController.text)
            : '',
        category: _selectedCategory!,
        skills: _skills,
        city: _cityController.text.trim(),
        area: _areaController.text.trim(),
        experienceYears: int.tryParse(_experienceController.text.trim()) ?? 0,
        expectedCharges: _chargesController.text.trim(),
        bio: _bioController.text.trim(),
        consentGiven: _consentGiven,
        isActive: true,
        updatedAt: DateTime.now(),
      );

      await _firestoreService.saveWorkerProfile(updatedProfile);

      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile saved. You are live.'),
          backgroundColor: AppTheme.success,
        ),
      );

      if (widget.isInitialSetup) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const WorkerMainScreen()),
          (route) => false,
        );
      } else {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Check your internet and try again ($e).'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isInitialSetup ? 'Create Worker Profile' : 'Edit Profile',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
        ),
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Saving profile...')
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Your professional profile',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Fill in your details accurately so local customers can contact and hire you.',
                      style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 24),

                    // Full Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                        hintText: 'e.g. Ramesh Kumar',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (val) =>
                          (val == null || val.trim().isEmpty) ? 'Full name is required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Primary Trade Category
                    CategoryDropdown(
                      value: _selectedCategory,
                      onChanged: (val) => setState(() => _selectedCategory = val),
                      validator: (val) =>
                          (val == null || val.isEmpty) ? 'Please select your trade category' : null,
                    ),
                    const SizedBox(height: 16),

                    // Phone Numbers
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Calling Phone Number *',
                        hintText: '9876543210',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: (val) =>
                          (val == null || val.trim().length < 10) ? 'Enter valid 10-digit number' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _whatsappController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'WhatsApp Number (Optional)',
                        hintText: 'Leave empty if same as calling number',
                        prefixIcon: Icon(Icons.chat_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Location
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cityController,
                            decoration: const InputDecoration(
                              labelText: 'City *',
                              hintText: 'Bangalore',
                              prefixIcon: Icon(Icons.location_city_outlined),
                            ),
                            validator: (val) =>
                                (val == null || val.trim().isEmpty) ? 'City required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _areaController,
                            decoration: const InputDecoration(
                              labelText: 'Area / Locality',
                              hintText: 'Mathikere',
                              prefixIcon: Icon(Icons.near_me_outlined),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Experience & Charges
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _experienceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Experience (Years) *',
                              hintText: '5',
                              prefixIcon: Icon(Icons.work_history_outlined),
                            ),
                            validator: (val) =>
                                (val == null || val.trim().isEmpty) ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _chargesController,
                            decoration: const InputDecoration(
                              labelText: 'Visiting Charges',
                              hintText: '500',
                              prefixIcon: Icon(Icons.currency_rupee),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Skills Tags
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _skillInputController,
                            decoration: const InputDecoration(
                              labelText: 'Add Skill Tags',
                              hintText: 'e.g. Pipe Fitting, Wiring',
                              prefixIcon: Icon(Icons.add_circle_outline),
                            ),
                            onSubmitted: (_) => _addSkill(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _addSkill,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              minimumSize: const Size(64, 54),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            child: const Text('Add'),
                          ),
                        ),
                      ],
                    ),
                    if (_skills.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _skills.map((skill) {
                          return Chip(
                            label: Text(skill),
                            onDeleted: () => _removeSkill(skill),
                            backgroundColor: AppTheme.primarySoft,
                            labelStyle: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600),
                            deleteIconColor: AppTheme.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            side: BorderSide.none,
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Short Bio
                    TextFormField(
                      controller: _bioController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Short Bio',
                        hintText: 'Specialized in residential plumbing, emergency water leaks, and sanitary installation.',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Required Consent Checkbox
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primarySoft,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _consentGiven,
                            onChanged: (val) => setState(() => _consentGiven = val ?? false),
                            activeColor: AppTheme.primary,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(top: 10),
                              child: Text(
                                'I agree to show my contact details to customers on the FixMates platform.',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Save Profile Button
                    ElevatedButton(
                      onPressed: _saveProfile,
                      child: const Text('Save Profile'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}