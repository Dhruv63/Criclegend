import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/data/auth_provider.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  final _locationController = TextEditingController(); // City/State
  String _role = 'Batsman'; // Default
  bool _isSeller = false;

  final List<String> _roles = ['Batsman', 'Bowler', 'All-rounder', 'Wicket Keeper'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
             GestureDetector(
               onTap: () {
                 // TODO: Image Picker Logic
               },
               child: CircleAvatar(
                 radius: 50,
                 backgroundColor: Colors.grey.shade200,
                 child: const Icon(Icons.camera_alt, size: 40, color: Colors.grey),
               ),
             ),
             const SizedBox(height: 24),
             TextFormField(
               controller: _nameController,
               decoration: const InputDecoration(labelText: 'Full Name'),
             ),
             const SizedBox(height: 16),
             TextFormField(
               controller: _locationController,
               decoration: const InputDecoration(labelText: 'Location (City)'),
             ),
             const SizedBox(height: 16),
             DropdownButtonFormField<String>(
               value: _role,
               decoration: const InputDecoration(labelText: 'Playing Role'),
               items: _roles.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
               onChanged: (val) => setState(() => _role = val!),
             ),
             const SizedBox(height: 24),
             SwitchListTile(
               title: const Text('Register as Seller?'),
               subtitle: const Text('List cricket gear, grounds, or academies'),
               value: _isSeller,
               onChanged: (val) => setState(() => _isSeller = val),
             ),
             const SizedBox(height: 32),
             SizedBox(
               width: double.infinity,
               child: ElevatedButton(
                 onPressed: () async {
                   if (_nameController.text.isEmpty || _locationController.text.isEmpty) {
                     ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text('Please fill all fields')),
                     );
                     return;
                   }
                   
                   try {
                     await ref.read(authRepositoryProvider).updateProfile(
                       name: _nameController.text.trim(),
                       location: _locationController.text.trim(),
                       role: _role,
                       isSeller: _isSeller,
                     );
                     if (context.mounted) {
                        context.go('/home');
                     }
                   } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error saving profile: $e')),
                        );
                      }
                   }
                 },
                 child: const Text('Save & Continue'),
               ),
             ),
          ],
        ),
      ),
    );
  }
}
