import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/patient_controller.dart';
import '../../../../core/constants/app_colors.dart';

class PatientRegistrationScreen extends ConsumerStatefulWidget {
  const PatientRegistrationScreen({super.key});

  @override
  ConsumerState<PatientRegistrationScreen> createState() =>
      _PatientRegistrationScreenState();
}

class _PatientRegistrationScreenState
    extends ConsumerState<PatientRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _mrController = TextEditingController();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _nurseController = TextEditingController();
  final _addressController = TextEditingController();
  final _diagnosisController = TextEditingController();

  String? _selectedGender;
  bool _isLoading = false;
  bool _formValid = false;

  @override
  void initState() {
    super.initState();
    // Add listeners to controllers to make validation reactive as user types
    _mrController.addListener(_checkFormValidity);
    _nameController.addListener(_checkFormValidity);
    _ageController.addListener(_checkFormValidity);
    _addressController.addListener(_checkFormValidity);
    _diagnosisController.addListener(_checkFormValidity);
  }

  @override
  void dispose() {
    _mrController.removeListener(_checkFormValidity);
    _nameController.removeListener(_checkFormValidity);
    _ageController.removeListener(_checkFormValidity);
    _addressController.removeListener(_checkFormValidity);
    _diagnosisController.removeListener(_checkFormValidity);
    _mrController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _nurseController.dispose();
    _addressController.dispose();
    _diagnosisController.dispose();
    super.dispose();
  }

  void _checkFormValidity() {
    final valid = _mrController.text.trim().isNotEmpty &&
        _mrController.text.trim().length >= 2 &&
        _nameController.text.trim().isNotEmpty &&
        !RegExp(r'[0-9]').hasMatch(_nameController.text) &&
        _ageController.text.trim().isNotEmpty &&
        (int.tryParse(_ageController.text.trim()) ?? -1) >= 0 &&
        (int.tryParse(_ageController.text.trim()) ?? 999) <= 150 &&
        _selectedGender != null &&
        _addressController.text.trim().isNotEmpty &&
        _diagnosisController.text.trim().isNotEmpty;
    if (_formValid != valid) setState(() => _formValid = valid);
  }

  Future<void> _startShift() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final mrNumber = _mrController.text.trim().toUpperCase();
      
      final patientId = await ref.read(patientControllerProvider.notifier).savePatient(
            mrNumber: mrNumber,
            patientName: _nameController.text.trim(),
            age: int.parse(_ageController.text.trim()),
            gender: _selectedGender!,
            nurseName: _nurseController.text.trim(),
            address: _addressController.text.trim(),
            diagnosis: _diagnosisController.text.trim(),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Patient registered & shift started!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        context.go('/patient_dashboard/$patientId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  onChanged: _checkFormValidity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionHeader('Patient Information', Icons.person_outline),
                      const SizedBox(height: 16),
                      _buildCard([
                        _buildTextField(
                          controller: _mrController,
                          label: 'MR Number',
                          hint: 'e.g. SHF-1024',
                          icon: Icons.tag_rounded,
                          textCapitalization: TextCapitalization.characters,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Required';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _nameController,
                          label: 'Full Name',
                          hint: 'Enter patient name',
                          icon: Icons.person_rounded,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _ageController,
                                label: 'Age',
                                hint: 'Years',
                                icon: Icons.cake_rounded,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(child: _buildGenderDropdown()),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _addressController,
                          label: 'Home Address',
                          hint: 'Street, area, city',
                          icon: Icons.location_on_rounded,
                          maxLines: 2,
                        ),
                      ]),
                      const SizedBox(height: 24),
                      _sectionHeader('Medical Details', Icons.medical_services_outlined),
                      const SizedBox(height: 16),
                      _buildCard([
                        _buildTextField(
                          controller: _nurseController,
                          label: 'Assigned Nurse (Optional)',
                          hint: 'Nurse name',
                          icon: Icons.medical_information_rounded,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _diagnosisController,
                          label: 'Diagnosis',
                          hint: 'Primary diagnosis',
                          icon: Icons.monitor_heart_rounded,
                          maxLines: 3,
                        ),
                      ]),
                      const SizedBox(height: 40),
                      _buildSubmitButton(),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          _formValid
                              ? 'Shift time will be saved automatically'
                              : 'Fill all fields to enable Start Shift',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: _formValid ? AppColors.success : AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => context.go('/home'),
          ),
          const SizedBox(width: 8),
          Text(
            'Register New Patient',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: (_formValid && !_isLoading) ? _startShift : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _formValid ? AppColors.primary : Colors.grey[100],
          foregroundColor: _formValid ? Colors.white : Colors.grey[400],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : Text('Start Shift', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EDF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int maxLines = 1,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      maxLines: maxLines,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        counterText: '',
      ),
      validator: validator,
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedGender,
      decoration: InputDecoration(
        labelText: 'Gender',
        prefixIcon: const Icon(Icons.wc_rounded, color: AppColors.primary, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: const [
        DropdownMenuItem(value: 'Male', child: Text('Male')),
        DropdownMenuItem(value: 'Female', child: Text('Female')),
        DropdownMenuItem(value: 'Other', child: Text('Other')),
      ],
      onChanged: (val) {
        setState(() => _selectedGender = val);
        _checkFormValidity();
      },
      validator: (v) => v == null ? 'Required' : null,
    );
  }
}