import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../community/data/community_repository.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _textController = TextEditingController();
  final CommunityRepository _repo = CommunityRepository();
  final ImagePicker _picker = ImagePicker();
  
  File? _selectedImage;
  bool _isUploading = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source, imageQuality: 70);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  Future<void> _submitPost() async {
    if (_textController.text.trim().isEmpty && _selectedImage == null) return;

    setState(() => _isUploading = true);

    try {
      List<String> mediaUrls = [];
      
      // 1. Upload Image if exists
      if (_selectedImage != null) {
        final userId = Supabase.instance.client.auth.currentUser!.id;
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileExt = _selectedImage!.path.split('.').last;
        final fileName = '$timestamp.$fileExt';
        final filePath = '$userId/$fileName';

        // Upload to 'post_images' bucket
        await Supabase.instance.client.storage
            .from('post_images')
            .upload(filePath, _selectedImage!);

        // Get Public URL
        final imageUrl = Supabase.instance.client.storage
            .from('post_images')
            .getPublicUrl(filePath);
            
        mediaUrls.add(imageUrl);
      }

      // 2. Create Post in DB
      await _repo.createPost(_textController.text.trim(), mediaUrls: mediaUrls);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post published!')));
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error posting: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    // We assume user profile is cached or we just use placeholder for now since we are inside the screen
    // ideally we fetch profile, but for MVP we can just show "Me" or generic avatar
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Create Post', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: ElevatedButton(
              onPressed: _isUploading || (_textController.text.isEmpty && _selectedImage == null) ? null : _submitPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                elevation: 0,
              ),
              child: _isUploading 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Post', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          if (_isUploading) const LinearProgressIndicator(color: AppColors.primary, backgroundColor: Colors.white),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Info 
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.grey.shade200,
                        child: const Icon(Icons.person, color: Colors.grey), // Placeholder
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Legendary User', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), 
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Text('Public', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                SizedBox(width: 4),
                                Icon(Icons.public, size: 10, color: Colors.grey)
                              ],
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Text Input
                  TextField(
                    controller: _textController,
                    maxLines: null,
                    decoration: const InputDecoration(
                      hintText: "What's on your mind, Legend?",
                      border: InputBorder.none,
                      hintStyle: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    style: const TextStyle(fontSize: 18),
                    onChanged: (val) => setState((){}),
                  ),
                  
                  const SizedBox(height: 20),

                  // Image Preview
                  if (_selectedImage != null)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_selectedImage!, width: double.infinity, height: 300, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedImage = null),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                              child: const Icon(Icons.close, color: Colors.white, size: 20),
                            ),
                          ),
                        )
                      ],
                    )
                ],
              ),
            ),
          ),

          // Bottom Actions
          Container(
            padding: EdgeInsets.only(
              left: 16, 
              right: 16, 
              top: 12, 
              bottom: MediaQuery.of(context).viewInsets.bottom + 12
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                const Text('Add to your post', style: TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.photo_library, color: Colors.green),
                  onPressed: () => _pickImage(ImageSource.gallery),
                ),
                IconButton(
                  icon: const Icon(Icons.camera_alt, color: Colors.blue),
                  onPressed: () => _pickImage(ImageSource.camera),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
