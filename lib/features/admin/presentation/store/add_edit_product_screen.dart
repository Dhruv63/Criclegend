import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../store/domain/product_model.dart';
import '../../data/admin_store_repository.dart';

class AddEditProductScreen extends ConsumerStatefulWidget {
  final Product? product;
  const AddEditProductScreen({super.key, this.product});

  @override
  ConsumerState<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends ConsumerState<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  // Controllers
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountPriceController = TextEditingController();
  final _stockController = TextEditingController();

  String _selectedCategory = 'Bats';
  bool _isActive = true;
  bool _isLoading = false;

  // Images
  final List<String> _existingImages = [];
  final List<XFile> _newImages = []; // Changed to XFile

  final List<String> _categories = ['Bats', 'Balls', 'Pads', 'Helmets', 'Shoes', 'Jerseys', 'Accessories', 'Kits'];

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      final p = widget.product!;
      _nameController.text = p.name;
      _brandController.text = p.brand ?? '';
      _descController.text = p.description ?? '';
      _priceController.text = p.price.toString();
      _discountPriceController.text = p.discountPrice?.toString() ?? '';
      _stockController.text = p.stockQuantity.toString();
      _selectedCategory = p.category;
      _isActive = p.isActive;
      _existingImages.addAll(p.images);
    }
  }

  Future<void> _pickImage() async {
    final List<XFile> picked = await _picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() {
        _newImages.addAll(picked);
      });
    }
  }

  void _removeExistingImage(int index) {
    setState(() => _existingImages.removeAt(index));
  }

  void _removeNewImage(int index) {
    setState(() => _newImages.removeAt(index));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_existingImages.isEmpty && _newImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please upload at least one image")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(adminStoreRepositoryProvider);
      
      final data = {
        'name': _nameController.text.trim(),
        'brand': _brandController.text.trim(),
        'category': _selectedCategory,
        'description': _descController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'discount_price': _discountPriceController.text.isNotEmpty ? double.parse(_discountPriceController.text.trim()) : null,
        'stock_quantity': int.parse(_stockController.text.trim()),
        'is_active': _isActive,
      };

      if (widget.product == null) {
        // Create
        await repo.createProduct(data, _newImages);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Product Created Successfully")));
      } else {
        // Update
        await repo.updateProduct(
            widget.product!.id, 
            data, 
            newImages: _newImages, 
            existingImages: _existingImages
        );
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Product Updated Successfully")));
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? "Add Product" : "Edit Product"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            TextButton(
              onPressed: _submit,
              child: const Text("SAVE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            )
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Section 1: Basic Info
            const Text("Basic Information", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Product Name', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _brandController,
                    decoration: const InputDecoration(labelText: 'Brand', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                    items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setState(() => _selectedCategory = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder(), alignLabelWithHint: true),
              maxLines: 4,
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            
            const SizedBox(height: 32),
            
            // Section 2: Pricing & Inventory
            const Text("Pricing & Inventory", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(labelText: 'Original Price (₹)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _discountPriceController,
                    decoration: const InputDecoration(labelText: 'Discount Price (₹)', border: OutlineInputBorder(), helperText: 'Optional'),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                       if (v!.isNotEmpty) {
                         final original = double.tryParse(_priceController.text) ?? 0;
                         final discount = double.tryParse(v) ?? 0;
                         if (discount >= original) return 'Must be < Original';
                       }
                       return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _stockController,
              decoration: const InputDecoration(labelText: 'Stock Quantity', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),

             const SizedBox(height: 32),

            // Section 3: Status
            SwitchListTile(
              title: const Text("Active In Store"),
              subtitle: const Text("Inactive products are hidden from users"),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: 32),
            
            // Section 4: Images
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 const Text("Product Images", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                 TextButton.icon(
                   onPressed: _pickImage, 
                   icon: const Icon(Icons.add_photo_alternate), 
                   label: const Text("Add Images")
                 ),
               ],
             ),
             const SizedBox(height: 16),
             
             if (_existingImages.isEmpty && _newImages.isEmpty)
               Container(
                 height: 150,
                 decoration: BoxDecoration(
                   color: Colors.grey.shade100,
                   borderRadius: BorderRadius.circular(12),
                   border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                 ),
                 child: Center(child: Text("No images uploaded", style: TextStyle(color: Colors.grey.shade500))),
               )
             else
               SizedBox(
                 height: 120,
                 child: ListView(
                   scrollDirection: Axis.horizontal,
                   children: [
                     ..._existingImages.asMap().entries.map((entry) {
                       return Stack(
                         children: [
                           Container(
                             width: 120, margin: const EdgeInsets.only(right: 12),
                             decoration: BoxDecoration(
                               borderRadius: BorderRadius.circular(8),
                               image: DecorationImage(image: NetworkImage(entry.value), fit: BoxFit.cover),
                             ),
                           ),
                           Positioned(
                             top: 4, right: 16,
                             child: GestureDetector(
                               onTap: () => _removeExistingImage(entry.key),
                               child: const CircleAvatar(radius: 12, backgroundColor: Colors.red, child: Icon(Icons.close, size: 16, color: Colors.white)),
                             ),
                           ),
                         ],
                       );
                     }),
                     ..._newImages.asMap().entries.map((entry) {
                       return Stack(
                         children: [
                           Container(
                             width: 120, margin: const EdgeInsets.only(right: 12),
                             child: ClipRRect(
                               borderRadius: BorderRadius.circular(8),
                               child: _buildImagePreview(entry.value),
                             ),
                           ),
                           Positioned(
                             top: 4, right: 16,
                             child: GestureDetector(
                               onTap: () => _removeNewImage(entry.key),
                               child: const CircleAvatar(radius: 12, backgroundColor: Colors.red, child: Icon(Icons.close, size: 16, color: Colors.white)),
                             ),
                           ),
                           Positioned(
                             bottom: 4, right: 16,
                             child: Container(
                               padding: const EdgeInsets.all(4),
                               decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                               child: const Text("NEW", style: TextStyle(color: Colors.white, fontSize: 10)),
                             ),
                           ),
                         ],
                       );
                     }),
                   ],
                 ),
               ),
             
             const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
  
  Widget _buildImagePreview(XFile file) {
    if (kIsWeb) {
      return Image.network(file.path, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.error));
    } else {
       // Ideally use Image.file(File(file.path)) but avoiding dart:io for web safety in this single file.
       // We can use generic byte loading which is safe everywhere
       return FutureBuilder<Uint8List>(
         future: file.readAsBytes(),
         builder: (context, snapshot) {
           if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
             return Image.memory(snapshot.data!, fit: BoxFit.cover);
           }
           return const Center(child: CircularProgressIndicator(strokeWidth: 2));
         }
       );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _discountPriceController.dispose();
    _stockController.dispose();
    super.dispose();
  }
}
