import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_data.dart';
import '../../widgets/product_image.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

class AddProductScreen extends StatefulWidget {
  final ProductModel? product;
  const AddProductScreen({super.key, this.product});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  late TextEditingController _weightController;
  late TextEditingController _stockController;
  late TextEditingController _imageController;
  
  late String _selectedCategory;
  late bool _isOrganic;
  bool _isLoading = false;
  
  Uint8List? _pickedImageBytes;
  String? _pickedImageName;
  String? _existingImageUrl;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? "");
    _descController = TextEditingController(text: widget.product?.description ?? "");
    _priceController = TextEditingController(text: widget.product?.price.toString() ?? "");
    _weightController = TextEditingController(text: widget.product?.weight ?? "");
    _stockController = TextEditingController(text: widget.product?.stockQuantity.toString() ?? "10");
    _imageController = TextEditingController(text: widget.product?.imageUrl ?? "");
    _selectedCategory = widget.product?.category ?? AppData.groceryCategories[0]['label'];
    _isOrganic = widget.product?.isOrganic ?? false;
    _existingImageUrl = widget.product?.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _weightController.dispose();
    _stockController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final user = Provider.of<UserModel>(context, listen: false);
    final productService = Provider.of<ProductService>(context, listen: false);

    if (user.uid == null || user.uid!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User session error. Please log in again.")));
      return;
    }

    String? imageUrl = _existingImageUrl;

    try {
      debugPrint('AddProductScreen: Starting submission...');
      
      // Upload image if a new one is picked
      if (_pickedImageBytes != null) {
        debugPrint('AddProductScreen: Uploading image...');
        final fileName = 'prod_${DateTime.now().millisecondsSinceEpoch}_${_pickedImageName ?? "image.jpg"}';
        imageUrl = await productService.uploadProductImage(_pickedImageBytes!, fileName)
            .timeout(const Duration(seconds: 30), onTimeout: () {
              throw 'Image upload timed out. Please check your connection.';
            });
        debugPrint('AddProductScreen: Image uploaded: $imageUrl');
      }

      if (imageUrl == null || imageUrl.isEmpty) {
        debugPrint('AddProductScreen: No image URL provided');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a product image")));
          setState(() => _isLoading = false);
        }
        return;
      }

      final newProduct = ProductModel(
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        price: double.tryParse(_priceController.text) ?? 0.0,
        imageUrl: imageUrl,
        category: _selectedCategory,
        vendorId: user.uid ?? '',
        vendorName: user.businessName ?? user.fullName ?? 'Store',
        vendorImageUrl: user.profilePictureUrl,
        stockQuantity: int.tryParse(_stockController.text) ?? 0,
        weight: _weightController.text.trim(),
        isOrganic: _isOrganic,
      );

      debugPrint('AddProductScreen: Saving product data...');
      if (widget.product != null) {
        // Update existing
        await productService.updateProduct(widget.product!.id!, {
          'name': _nameController.text.trim(),
          'description': _descController.text.trim(),
          'price': double.tryParse(_priceController.text) ?? 0.0,
          'imageUrl': imageUrl,
          'category': _selectedCategory,
          'vendorName': user.businessName ?? user.fullName ?? 'Store',
          'vendorImageUrl': user.profilePictureUrl,
          'stockQuantity': int.tryParse(_stockController.text) ?? 0,
          'weight': _weightController.text.trim(),
          'isOrganic': _isOrganic,
        }).timeout(const Duration(seconds: 20), onTimeout: () {
          throw 'Update timed out. Please check your connection.';
        });
      } else {
        // Add new
        await productService.addProduct(newProduct).timeout(const Duration(seconds: 20), onTimeout: () {
          throw 'Save timed out. Please check your connection.';
        });
      }
      
      debugPrint('AddProductScreen: Success!');
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.product != null ? "Product updated!" : "Product added!"), backgroundColor: AppColors.primaryGreen),
        );
      }
    } catch (e) {
      debugPrint('AddProductScreen: Error during submission: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to save product: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      debugPrint('AddProductScreen: Submission process finished.');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allCategories = [
      ...AppData.groceryCategories.map((e) => e['label']),
      ...AppData.snackCategories.map((e) => e['label']),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product != null ? "Edit Product" : "Add New Product"),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(_nameController, "Product Name", "e.g. Fresh Tomatoes", Icons.shopping_basket),
                  const SizedBox(height: 16),
                  _buildTextField(_descController, "Description", "Tell customers about your product", Icons.description, maxLines: 3),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(_priceController, "Price (Rs.)", "0.00", Icons.payments, keyboardType: TextInputType.number)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildTextField(_weightController, "Weight/Unit", "e.g. 1kg, 500g", Icons.scale, keyboardType: TextInputType.text)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(_stockController, "Initial Stock", "10", Icons.inventory, keyboardType: TextInputType.number)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Organic?", style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text("Yes", style: TextStyle(fontSize: 14)),
                              value: _isOrganic,
                              onChanged: (val) => setState(() => _isOrganic = val),
                              activeColor: AppColors.primaryGreen,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text("Category", style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.category, color: AppColors.primaryGreen),
                      border: OutlineInputBorder(),
                    ),
                    items: allCategories.map((cat) => DropdownMenuItem(
                      value: cat.toString(),
                      child: Text(cat.toString()),
                    )).toList(),
                    onChanged: (val) => setState(() => _selectedCategory = val!),
                  ),
                  const SizedBox(height: 24),
                  const Text("Product Image", style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                        image: (_pickedImageBytes != null)
                            ? DecorationImage(image: MemoryImage(_pickedImageBytes!), fit: BoxFit.contain)
                            : null,
                      ),
                      child: (_pickedImageBytes != null)
                          ? null
                          : (_existingImageUrl != null && _existingImageUrl!.isNotEmpty)
                              ? ProductImage(imageUrl: _existingImageUrl!, fit: BoxFit.contain)
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.grey.shade400),
                                    const SizedBox(height: 8),
                                    Text("Click to upload product photo", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                  ],
                                ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(widget.product != null ? "UPDATE PRODUCT" : "SAVE PRODUCT", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, 
    String label, 
    String hint, 
    IconData icon, 
    {int maxLines = 1, TextInputType keyboardType = TextInputType.text}
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.primaryGreen),
            border: const OutlineInputBorder(),
            focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.primaryGreen, width: 2)),
          ),
          validator: (value) => value == null || value.isEmpty ? "Required" : null,
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
      maxWidth: 1024,
      maxHeight: 1024,
    );

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _pickedImageBytes = bytes;
        _pickedImageName = pickedFile.name;
      });
    }
  }
}
