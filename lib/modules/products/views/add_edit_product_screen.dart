import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../data/models/product_model.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/services/firestore_service.dart';
import '../../../data/services/notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/constants/app_constants.dart';

class AddEditProductScreen extends StatefulWidget {
  const AddEditProductScreen({
    super.key,
  });

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final AuthController _authController = Get.find<AuthController>();
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  final ImagePicker _imagePicker = ImagePicker();
  final NotificationService _notificationService = NotificationService();

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _categoryController = TextEditingController();
  
  DateTime? _expiryDate;
  String? _imageUrl;
  bool _isLoading = false;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args != null && args is ProductModel) {
      _initializeEditMode(args);
    }
  }

  void _initializeEditMode(ProductModel product) {
    _nameController.text = product.productName;
    _quantityController.text = product.quantity.toString();
    _categoryController.text = product.category ?? '';
    _expiryDate = product.expiryDate;
    _imageUrl = product.productImage;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() => _isUploadingImage = true);
      
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: AppConstants.imageQuality,
      );

      if (image != null) {
        // Upload to Firebase Storage
        final userId = _authController.currentUser.value!.userId;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final file = File(image.path);
        final url = await _storageService.uploadProductImage(userId, fileName, file);
        
        setState(() => _imageUrl = url);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _selectExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (picked != null) {
      setState(() => _expiryDate = picked);
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_expiryDate == null) {
      Get.snackbar(
        'Error',
        'Please select an expiry date',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = _authController.currentUser.value!.userId;
      final args = Get.arguments;
      
      if (args == null || args is! ProductModel) {
        // Add new product
        final productId = '${DateTime.now().millisecondsSinceEpoch}';
        final product = ProductModel.create(
          productId: productId,
          productName: _nameController.text.trim(),
          quantity: int.parse(_quantityController.text),
          expiryDate: _expiryDate!,
          productImage: _imageUrl,
          category: _categoryController.text.trim().isEmpty 
              ? null 
              : _categoryController.text.trim(),
        );

        await _firestoreService.createProduct(userId, product);

        // Schedule expiry notifications if expiry date is in the future (date-only comparison)
        final now = DateTime.now();
        final normalizedNow = DateTime(now.year, now.month, now.day);
        final normalizedExpiryDate = DateTime(product.expiryDate.year, product.expiryDate.month, product.expiryDate.day);
        if (normalizedExpiryDate.isAfter(normalizedNow)) {
          await _notificationService.scheduleProductExpiryNotifications(
            productId: product.productId,
            productName: product.productName,
            expiryDate: product.expiryDate,
          );
        }

        // Use GetX root snackbar to persist across navigation
        Get.snackbar(
          'Success',
          AppConstants.successProductAdded,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.primary,
          colorText: Get.theme.colorScheme.onPrimary,
          margin: const EdgeInsets.all(16),
        );
      } else {
        // Update existing product
        final existingProduct = args;
        final updatedProduct = existingProduct.copyWith(
          productName: _nameController.text.trim(),
          quantity: int.parse(_quantityController.text),
          expiryDate: _expiryDate!,
          productImage: _imageUrl,
          category: _categoryController.text.trim().isEmpty
              ? null
              : _categoryController.text.trim(),
        );

        await _firestoreService.updateProduct(userId, updatedProduct);

        // Cancel old expiry notifications and schedule new ones
        await _notificationService.cancelProductExpiryNotifications(existingProduct.productId);
        // Schedule new notifications if expiry date is in the future (date-only comparison)
        final now = DateTime.now();
        final normalizedNow = DateTime(now.year, now.month, now.day);
        final normalizedExpiryDate = DateTime(updatedProduct.expiryDate.year, updatedProduct.expiryDate.month, updatedProduct.expiryDate.day);
        if (normalizedExpiryDate.isAfter(normalizedNow)) {
          await _notificationService.scheduleProductExpiryNotifications(
            productId: updatedProduct.productId,
            productName: updatedProduct.productName,
            expiryDate: updatedProduct.expiryDate,
          );
        }

        // Use GetX root snackbar to persist across navigation
        Get.snackbar(
          'Success',
          AppConstants.successProductUpdated,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.primary,
          colorText: Get.theme.colorScheme.onPrimary,
          margin: const EdgeInsets.all(16),
        );
      }

      Get.back(result: true);
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    final isEditMode = args != null && args is ProductModel;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Product' : 'Add Product'),
        backgroundColor: AppColors.surfaceElevated,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              _buildImageSection(),
              const SizedBox(height: 24),

              // Product Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  hintText: 'Enter product name',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
                validator: Validators.validateProductName,
              ),
              const SizedBox(height: 16),

              // Quantity
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  hintText: 'Enter quantity',
                  prefixIcon: Icon(Icons.format_list_numbered),
                ),
                validator: Validators.validateQuantity,
              ),
              const SizedBox(height: 16),

              // Category
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category (Optional)',
                  hintText: 'Enter category',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // Expiry Date
              InkWell(
                onTap: _selectExpiryDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Expiry Date',
                    prefixIcon: const Icon(Icons.calendar_today),
                    errorText: _expiryDate == null ? 'Expiry date is required' : null,
                  ),
                  child: Text(
                    _expiryDate != null
                        ? DateFormat('yyyy-MM-dd').format(_expiryDate!)
                        : 'Select expiry date',
                    style: TextStyle(
                      color: _expiryDate != null 
                          ? AppColors.textPrimary 
                          : AppColors.textHint,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProduct,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.surface,
                          ),
                        )
                      : Text(isEditMode ? 'Update Product' : 'Add Product'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: _isUploadingImage
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.broken_image,
                              size: 48,
                              color: AppColors.textHint,
                            );
                          },
                        ),
                      )
                    : const Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 48,
                        color: AppColors.textHint,
                      ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Camera'),
              ),
              const SizedBox(width: 16),
              TextButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Gallery'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
