import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/looking_request_model.dart';
import 'providers/looking_providers.dart';
import '../../../../features/auth/presentation/providers/auth_providers.dart';

class CreateLookingScreen extends ConsumerStatefulWidget {
  const CreateLookingScreen({super.key});

  @override
  ConsumerState<CreateLookingScreen> createState() =>
      _CreateLookingScreenState();
}

class _CreateLookingScreenState extends ConsumerState<CreateLookingScreen> {
  final _formKey = GlobalKey<FormState>();

  // State
  int _step = 1;
  String? _selectedCategory;
  final _cityController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contactController = TextEditingController();
  String _selectedSkill = 'Tennis Ball'; // Default
  bool _isUrgent = false;

  final List<String> _categories = [
    'Player',
    'Opponent',
    'Umpire',
    'Ground',
    'Academy',
  ];
  final List<String> _skills = [
    'Tennis Ball',
    'Leather Ball',
    'Corporate',
    'Pro',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'New Request',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Progress Bar
          LinearProgressIndicator(
            value: _step / 3,
            backgroundColor: Colors.grey.shade100,
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _buildStepContent(),
            ),
          ),

          // Bottom Bar
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                if (_step > 1)
                  TextButton(
                    onPressed: () => setState(() => _step--),
                    child: const Text('Back'),
                  ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _handleNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _step == 3 ? 'Post Request' : 'Next',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What are you looking for?',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: _categories
                  .map((cat) => _buildCategoryCard(cat))
                  .toList(),
            ),
          ],
        );
      case 2:
        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fill in the details',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // City
              TextFormField(
                controller: _cityController,
                decoration: _inputDecoration(
                  'City / Location',
                  Icons.location_on_outlined,
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Skill Level (Conditional)
              if ([
                'Player',
                'Opponent',
                'Umpire',
              ].contains(_selectedCategory)) ...[
                DropdownButtonFormField<String>(
                  initialValue: _selectedSkill,
                  decoration: _inputDecoration(
                    'Skill / Ball Type',
                    Icons.sports_cricket_outlined,
                  ),
                  items: _skills
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedSkill = v!),
                ),
                const SizedBox(height: 16),
              ],

              // Contact
              TextFormField(
                controller: _contactController,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration('WhatsApp / Phone', Icons.phone),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: _inputDecoration(
                  'Description (e.g. Need keeper for 20 overs)',
                  Icons.description_outlined,
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 24),

              // Urgency
              SwitchListTile(
                title: const Text('Urgent Requirement?'),
                subtitle: const Text('Highlight this post in red'),
                value: _isUrgent,
                activeThumbColor: AppColors.error,
                onChanged: (v) => setState(() => _isUrgent = v),
              ),
            ],
          ),
        );

      case 3:
        return Column(
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 80,
              color: AppColors.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Ready to Post!',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your request will be visible to everyone in $_cityController.text',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            _buildReviewRow('Category', _selectedCategory!),
            _buildReviewRow('Location', _cityController.text),
            _buildReviewRow('Status', _isUrgent ? 'Urgent' : 'Normal'),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildReviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(String title) {
    final isSelected = _selectedCategory == title;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = title),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade200,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIconForCategory(title),
              color: isSelected ? AppColors.primary : Colors.grey,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? AppColors.primary : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForCategory(String c) {
    switch (c) {
      case 'Player':
        return Icons.person;
      case 'Opponent':
        return Icons.shield;
      case 'Umpire':
        return Icons.sports;
      case 'Ground':
        return Icons.stadium;
      case 'Academy':
        return Icons.school;
      default:
        return Icons.help;
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  void _handleNext() async {
    if (_step == 1) {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Select a category')));
        return;
      }
      setState(() => _step++);
    } else if (_step == 2) {
      if (_formKey.currentState!.validate()) {
        setState(() => _step++);
      }
    } else {
      // POST
      try {
        final user = ref.read(userProvider);
        if (user == null) throw 'Not Logged In';

        final request = LookingRequest(
          id: '', // Generated by DB
          userId: user.id,
          category: _selectedCategory!,
          locationCity: _cityController.text,
          skillLevel: _selectedSkill,
          urgencyLevel: _isUrgent ? 'Urgent' : 'Normal',
          description: _descriptionController.text,
          contactNumber: _contactController.text,
          createdAt: DateTime.now(),
        );

        await ref.read(lookingRepositoryProvider).createRequest(request);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Posted Successfully!')));
          context.pop(); // Close wizard
          // Trigger refresh if needed (provider is autoDispose so usually fine)
          ref.refresh(lookingRequestsProvider);
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
