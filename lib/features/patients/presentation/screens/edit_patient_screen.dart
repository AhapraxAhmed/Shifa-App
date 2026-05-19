import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/patient_provider.dart';
import '../providers/patient_controller.dart';
import '../../../../core/constants/app_colors.dart';

class EditPatientScreen extends ConsumerStatefulWidget {
  final String patientId;
  const EditPatientScreen({super.key, required this.patientId});

  @override
  ConsumerState<EditPatientScreen> createState() => _EditPatientScreenState();
}

class _EditPatientScreenState extends ConsumerState<EditPatientScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _nurseController;
  late TextEditingController _addressController;
  late TextEditingController _diagnosisController;

  String? _selectedGender;
  String? _selectedStatus;
  bool _isLoading = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _ageController = TextEditingController();
    _nurseController = TextEditingController();
    _addressController = TextEditingController();
    _diagnosisController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _nurseController.dispose();
    _addressController.dispose();
    _diagnosisController.dispose();
    super.dispose();
  }

  void _prefillData(dynamic patient) {
    if (_initialized || patient == null) return;
    _nameController.text = patient.patientName;
    _ageController.text = patient.age.toString();
    _nurseController.text = patient.nurseName;
    _addressController.text = patient.address;
    _diagnosisController.text = patient.diagnosis;
    _selectedGender = patient.gender;
    _selectedStatus = patient.status;
    _initialized = true;
  }

  Future<void> _updatePatient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(patientControllerProvider.notifier).updatePatient(
            patientId: widget.patientId,
            patientName: _nameController.text.trim(),
            age: int.parse(_ageController.text.trim()),
            gender: _selectedGender!,
            nurseName: _nurseController.text.trim(),
            address: _addressController.text.trim(),
            diagnosis: _diagnosisController.text.trim(),
            status: _selectedStatus ?? 'active',
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Patient details updated successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating patient: $e'),
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
    final patientAsync = ref.watch(patientStreamProvider(widget.patientId));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Edit Patient Details',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey[100]),
        ),
      ),
      body: patientAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (patient) {
          if (patient == null) {
            return const Center(child: Text('Patient not found'));
          }

          _prefillData(patient);

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader('Patient Information', Icons.person_outline),
                    const SizedBox(height: 16),
                    _buildCard([
                      _buildTextField(
                        controller: _nameController,
                        label: 'Full Name',
                        hint: 'Enter patient name',
                        icon: Icons.person_rounded,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (RegExp(r'[0-9]').hasMatch(v)) return 'Name cannot contain numbers';
                          return null;
                        },
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
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Required';
                                final age = int.tryParse(v);
                                if (age == null || age < 0 || age > 150) return 'Invalid age';
                                return null;
                              },
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
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _sectionHeader('Medical & Clinical Details', Icons.medical_services_outlined),
                    const SizedBox(height: 16),
                    _buildCard([
                      _buildStatusDropdown(),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _nurseController,
                        label: 'Assigned Nurse',
                        hint: 'Nurse name',
                        icon: Icons.medical_information_rounded,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _diagnosisController,
                        label: 'Diagnosis',
                        hint: 'Primary diagnosis',
                        icon: Icons.monitor_heart_rounded,
                        maxLines: 3,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                    ]),
                    const SizedBox(height: 40),
                    _buildSubmitButton(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.outfit(
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
            color: Colors.black.withOpacity(0.04),
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
      value: _selectedGender,
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
      },
      validator: (v) => v == null ? 'Required' : null,
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedStatus,
      decoration: InputDecoration(
        labelText: 'Clinical Status',
        prefixIcon: const Icon(Icons.star_rounded, color: AppColors.primary, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: const [
        DropdownMenuItem(value: 'active', child: Text('Active')),
        DropdownMenuItem(value: 'stable', child: Text('Stable')),
        DropdownMenuItem(value: 'critical', child: Text('Critical')),
        DropdownMenuItem(value: 'completed', child: Text('Completed')),
      ],
      onChanged: (val) {
        setState(() => _selectedStatus = val);
      },
      validator: (v) => v == null ? 'Required' : null,
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: !_isLoading ? _updatePatient : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : Text(
                'Save Changes',
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}