import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/theme.dart';
import '../services/auth_service.dart';
import 'worker_dashboard_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  bool _isLoading = false;

  // Step 1: Profession
  String _selectedProfession = '';
  final List<String> _professions = ['Plumber', 'Electrician', 'Carpenter', 'Painter', 'Welder', 'Other'];

  // Step 2: Personal Info
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  String _gender = 'Male';
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _pincodeController = TextEditingController();
  List<String> _fetchedAreas = [];
  bool _isFetchingAreas = false;

  // Step 3: Professional Info
  final _experienceController = TextEditingController();
  List<String> _selectedAreas = [];
  List<String> _selectedSkills = [];
  final _customSkillController = TextEditingController();

  // Step 4: Projects
  List<File> _projectImages = [];

  final List<String> _otherSkills = ['Civil Work', 'Demolition', 'General Helper', 'Loading/Unloading', 'Cleaning', 'Miscellaneous'];
  final Map<String, List<String>> _professionSkills = {
    'Welder': ['Shed Work', 'Grill Work', 'Gate Work', 'Window Grills', 'Custom Fabrication'],
    'Plumber': ['Bathroom Fitting', 'Pipe Leakage', 'Motor Installation', 'Sanitary Work'],
    'Electrician': ['Wiring', 'Switchboard Repair', 'Inverter Installation', 'Fan/Light Fitting'],
    'Carpenter': ['Furniture Assembly', 'Door Repair', 'Cupboard Making', 'Polishing'],
    'Painter': ['Interior Painting', 'Exterior Painting', 'Texture Paint', 'Waterproofing'],
  };

  @override
  void initState() {
    super.initState();
    final user = _authService.currentUser;
    if (user != null) {
      _nameController.text = user.displayName ?? '';
      _mobileController.text = user.phoneNumber ?? '';
      _emailController.text = user.email ?? '';
    }
  }

  Future<void> _fetchAreasByPincode() async {
    final pincode = _pincodeController.text.trim();
    if (pincode.length != 6) return;

    setState(() => _isFetchingAreas = true);
    try {
      final response = await http.get(Uri.parse('https://api.postalpincode.in/pincode/$pincode'));
      final data = json.decode(response.body);
      if (data[0]['Status'] == 'Success') {
        final areas = (data[0]['PostOffice'] as List)
            .map((postOffice) => postOffice['Name'] as String)
            .toSet()
            .toList();
        setState(() => _fetchedAreas = areas);
      } else {
        setState(() => _fetchedAreas = []);
      }
    } catch (e) {
      setState(() => _fetchedAreas = []);
    } finally {
      setState(() => _isFetchingAreas = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _projectImages.add(File(image.path)));
    }
  }

  Future<void> _submitOnboarding() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Upload project images to Firebase Storage
      List<String> projectUrls = [];
      for (int i = 0; i < _projectImages.length; i++) {
        final ref = FirebaseStorage.instance.ref().child('worker_projects/${user.uid}/project_$i.jpg');
        await ref.putFile(_projectImages[i]);
        projectUrls.add(await ref.getDownloadURL());
      }

      // Determine approval status
      final isOther = _selectedProfession == 'Other';
      final approvalStatus = isOther ? 'pending' : 'auto_approved';

      // Save to Firestore
      await FirebaseFirestore.instance.collection('workers').doc(user.uid).set({
        'uid': user.uid,
        'name': _nameController.text.trim(),
        'age': int.tryParse(_ageController.text) ?? 0,
        'gender': _gender,
        'phone': _mobileController.text.trim(),
        'email': _emailController.text.trim(),
        'address': _addressController.text.trim(),
        'pincode': _pincodeController.text.trim(),
        'category': _selectedProfession,
        'experienceYears': int.tryParse(_experienceController.text) ?? 0,
        'serviceAreas': _selectedAreas,
        'skills': _selectedSkills,
        'projects': projectUrls,
        'approvalStatus': approvalStatus,
        'isActive': !isOther, // Auto-activate main 5, keep 'Other' inactive until approved
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Also update the main users collection
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'role': 'worker',
        'name': _nameController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const WorkerDashboardScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Step ${_currentStep + 1} of 4'),
        backgroundColor: AppTheme.background,
        leading: _currentStep > 0 
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _currentStep--)) 
            : null,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: _buildCurrentStep(),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0: return _buildProfessionStep();
      case 1: return _buildPersonalInfoStep();
      case 2: return _buildProfessionalInfoStep();
      case 3: return _buildProjectUploadStep();
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildProfessionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('What is your profession?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const Text('Select your primary trade to get started.', style: TextStyle(color: AppTheme.textSecondary)),
        const SizedBox(height: 24),
        ..._professions.map((prof) {
          final isSelected = _selectedProfession == prof;
          return GestureDetector(
            onTap: () => setState(() => _selectedProfession = prof),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primarySoft : AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.border),
              ),
              child: Row(
                children: [
                  Icon(isSelected ? Icons.check_circle : Icons.circle_outlined, color: isSelected ? AppTheme.primary : AppTheme.textSecondary),
                  const SizedBox(width: 12),
                  Text(prof, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          );
        }).toList(),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _selectedProfession.isEmpty ? null : () => setState(() => _currentStep = 1),
            child: const Text('Next'),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Personal Details', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 24),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person)),
          validator: (v) => v!.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Age', prefixIcon: Icon(Icons.cake)),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _gender,
                decoration: const InputDecoration(labelText: 'Gender', prefixIcon: Icon(Icons.wc)),
                items: ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                onChanged: (v) => setState(() => _gender = v!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _mobileController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Mobile Number', prefixIcon: Icon(Icons.phone)),
          validator: (v) => v!.length < 10 ? 'Valid mobile required' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email (Optional)', prefixIcon: Icon(Icons.email)),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _addressController,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'Full Address', prefixIcon: Icon(Icons.home)),
          validator: (v) => v!.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _pincodeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(labelText: 'Pincode', prefixIcon: Icon(Icons.pin_drop), counterText: ''),
                onChanged: (v) { if (v.length == 6) _fetchAreasByPincode(); },
                validator: (v) => v!.length != 6 ? 'Valid 6-digit pincode required' : null,
              ),
            ),
            const SizedBox(width: 12),
            if (_isFetchingAreas) const CircularProgressIndicator(),
          ],
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _formKey.currentState!.validate() ? () => setState(() => _currentStep = 2) : null,
            child: const Text('Next'),
          ),
        ),
      ],
    );
  }

  Widget _buildProfessionalInfoStep() {
    final availableSkills = _selectedProfession == 'Other' 
        ? _otherSkills 
        : (_professionSkills[_selectedProfession] ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Professional Details', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 24),
        TextFormField(
          controller: _experienceController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Years of Experience', prefixIcon: Icon(Icons.work)),
          validator: (v) => v!.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 24),
        const Text('Service Areas (Select all that apply)', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _fetchedAreas.map((area) {
            final isSelected = _selectedAreas.contains(area);
            return FilterChip(
              label: Text(area),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) _selectedAreas.add(area);
                  else _selectedAreas.remove(area);
                });
              },
            );
          }).toList(),
        ),
        if (_fetchedAreas.isEmpty && _pincodeController.text.length == 6)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('No areas found for this pincode. You can type custom areas below.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          ),
        const SizedBox(height: 16),
        // Allow manual area entry
        TextFormField(
          decoration: const InputDecoration(labelText: 'Add custom area (Optional)', hintText: 'Type and press enter'),
          onFieldSubmitted: (value) {
            if (value.trim().isNotEmpty && !_selectedAreas.contains(value.trim())) {
              setState(() => _selectedAreas.add(value.trim()));
            }
          },
        ),
        const SizedBox(height: 24),
        const Text('Skills & Expertise', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: availableSkills.map((skill) {
            final isSelected = _selectedSkills.contains(skill);
            return FilterChip(
              label: Text(skill),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) _selectedSkills.add(skill);
                  else _selectedSkills.remove(skill);
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _customSkillController,
          decoration: const InputDecoration(labelText: 'Add custom skill', hintText: 'Type and press enter'),
          onFieldSubmitted: (value) {
            if (value.trim().isNotEmpty && !_selectedSkills.contains(value.trim())) {
              setState(() => _selectedSkills.add(value.trim()));
              _customSkillController.clear();
            }
          },
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _formKey.currentState!.validate() && _selectedAreas.isNotEmpty && _selectedSkills.isNotEmpty
                ? () => setState(() => _currentStep = 3)
                : null,
            child: const Text('Next'),
          ),
        ),
      ],
    );
  }

  Widget _buildProjectUploadStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Showcase Your Work', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const Text('Upload photos of your previous projects. This helps customers trust you!', style: TextStyle(color: AppTheme.textSecondary)),
        const SizedBox(height: 24),
        
        if (_projectImages.isNotEmpty)
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _projectImages.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 12),
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(image: FileImage(_projectImages[index]), fit: BoxFit.cover),
                      ),
                    ),
                    Positioned(
                      top: 4, right: 16,
                      child: GestureDetector(
                        onTap: () => setState(() => _projectImages.removeAt(index)),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: const Icon(Icons.close, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.add_photo_alternate),
          label: const Text('Add Project Photo'),
        ),
        const SizedBox(height: 40),
        
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitOnboarding,
            child: _isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Submit for Review'),
          ),
        ),
        if (_selectedProfession == 'Other')
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              'Note: "Other" category profiles require admin approval before going live.',
              style: TextStyle(color: AppTheme.accent, fontSize: 13, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}