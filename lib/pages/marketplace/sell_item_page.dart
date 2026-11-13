import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/student_info.dart';
import '../../services/vendor_service.dart';

class SellItemPage extends StatefulWidget {
  const SellItemPage({super.key});

  @override
  State<SellItemPage> createState() => _SellItemPageState();
}

class _SellItemPageState extends State<SellItemPage> {
  final _formKey = GlobalKey<FormState>();
  final _itemNameController = TextEditingController();
  final _itemDescriptionController = TextEditingController();
  final _itemPriceController = TextEditingController();

  // Seller info controllers (prefilled if Student profile exists in Hive)
  final _sellerNameController = TextEditingController();
  final _sellerPhoneController = TextEditingController();
  final _sellerDeptController = TextEditingController();
  final _sellerFacultyController = TextEditingController();

  String _selectedCategory = 'Laptops & Gadgets';
  final List<String> _categories = [
    'Laptops & Gadgets',
    'Textbooks',
    'Hostel Essentials',
    'Fashion & Wears',
    'Food & Snacks',
    'Campus Services',
  ];

  // Preset sample campus images students can choose from if they don't have a camera/file handy
  final List<Map<String, String>> _sampleImages = [
    {'label': 'Laptop', 'url': 'https://images.unsplash.com/photo-1588872657578-7efd1f1555ed?w=800&q=80'},
    {'label': 'Textbook', 'url': 'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=800&q=80'},
    {'label': 'Hostel Fan', 'url': 'https://images.unsplash.com/photo-1618941716939-553df3c6c278?w=800&q=80'},
    {'label': 'Headphones', 'url': 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=800&q=80'},
    {'label': 'Sneakers', 'url': 'https://images.unsplash.com/photo-1552346154-21d32810aba3?w=800&q=80'},
    {'label': 'Snacks / Food', 'url': 'https://images.unsplash.com/photo-1587668178277-295251f900ce?w=800&q=80'},
  ];

  XFile? _pickedXFile;
  Uint8List? _imageBytes;
  String? _selectedPresetUrl;
  bool _isLoading = false;

  final VendorService _vendorService = VendorService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      if (Hive.isBoxOpen('students')) {
        final box = Hive.box<Student>('students');
        if (box.isNotEmpty) {
          final currentUser = box.getAt(box.length - 1);
          if (currentUser != null) {
            setState(() {
              _sellerNameController.text = currentUser.fullName;
              _sellerPhoneController.text = currentUser.phone;
              _sellerDeptController.text = currentUser.department;
              _sellerFacultyController.text = currentUser.faculty;
            });
          }
        }
      }
    } catch (_) {
      // Continue gracefully if Hive not initialized or empty
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 85,
      );

      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _pickedXFile = picked;
          _imageBytes = bytes;
          _selectedPresetUrl = null; // Clear preset if file picked
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick image: $e')),
        );
      }
    }
  }

  Future<void> _submitItem() async {
    if (!_formKey.currentState!.validate()) return;

    String imagePath = 'https://images.unsplash.com/photo-1526170375885-4d8ecf77b99f?w=800&q=80';
    if (_selectedPresetUrl != null && _selectedPresetUrl!.isNotEmpty) {
      imagePath = _selectedPresetUrl!;
    } else if (_pickedXFile != null && _pickedXFile!.path.isNotEmpty) {
      imagePath = _pickedXFile!.path;
    }

    final name = _sellerNameController.text.trim().isEmpty ? 'Campus Student' : _sellerNameController.text.trim();
    final phone = _sellerPhoneController.text.trim().isEmpty ? '08000000000' : _sellerPhoneController.text.trim();
    final dept = _sellerDeptController.text.trim().isEmpty ? 'Undergraduate' : _sellerDeptController.text.trim();
    final faculty = _sellerFacultyController.text.trim().isEmpty ? 'AKUM Campus' : _sellerFacultyController.text.trim();

    setState(() => _isLoading = true);

    await _vendorService.postVendorItem(
      name: name,
      email: '$name@students.akum.edu.ng'.toLowerCase().replaceAll(' ', '.'),
      phone: phone,
      matricNo: 'AKUM/${DateTime.now().year}/0001',
      faculty: faculty,
      department: dept,
      itemName: _itemNameController.text.trim(),
      itemDescription: _itemDescriptionController.text.trim(),
      itemPrice: _itemPriceController.text.trim().replaceAll('₦', ''),
      imagePath: imagePath,
      category: _selectedCategory,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Item published live on AKUM Marketplace!'),
            ],
          ),
          backgroundColor: Color(0xFF1B5E20),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _itemDescriptionController.dispose();
    _itemPriceController.dispose();
    _sellerNameController.dispose();
    _sellerPhoneController.dispose();
    _sellerDeptController.dispose();
    _sellerFacultyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Post Item for Sale'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Picker Header Card
              _buildImagePickerSection(),

              const SizedBox(height: 20),

              // Item Information Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Product Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Item Name
                    TextFormField(
                      controller: _itemNameController,
                      decoration: _inputDecoration(
                        label: 'Item Title',
                        hint: 'e.g. HP Pavilion 15 Core i5 or Guyton Physiology',
                        icon: Icons.shopping_bag_outlined,
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty ? 'Please enter item title' : null,
                    ),

                    const SizedBox(height: 14),

                    // Category Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: _inputDecoration(
                        label: 'Category',
                        icon: Icons.category_outlined,
                      ),
                      items: _categories.map((cat) {
                        return DropdownMenuItem(value: cat, child: Text(cat));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCategory = val);
                      },
                    ),

                    const SizedBox(height: 14),

                    // Price Input
                    TextFormField(
                      controller: _itemPriceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: _inputDecoration(
                        label: 'Selling Price',
                        hint: 'e.g. 15,000',
                        prefixText: '₦ ',
                        icon: Icons.payments_outlined,
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty ? 'Please enter a price' : null,
                    ),

                    const SizedBox(height: 14),

                    // Description Input
                    TextFormField(
                      controller: _itemDescriptionController,
                      maxLines: 4,
                      decoration: _inputDecoration(
                        label: 'Item Description & Condition',
                        hint: 'Describe condition, specs, reason for selling, or meetup details...',
                        icon: Icons.notes_rounded,
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty ? 'Please describe your item' : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Seller Contact Details Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Seller Contact & Campus Location',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Full Name
                    TextFormField(
                      controller: _sellerNameController,
                      decoration: _inputDecoration(
                        label: 'Your Full Name',
                        hint: 'e.g. Aliyu Abubakar',
                        icon: Icons.person_outline,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Enter your name' : null,
                    ),

                    const SizedBox(height: 14),

                    // Phone / WhatsApp
                    TextFormField(
                      controller: _sellerPhoneController,
                      keyboardType: TextInputType.phone,
                      decoration: _inputDecoration(
                        label: 'Phone / WhatsApp Number',
                        hint: 'e.g. 08012345678',
                        icon: Icons.phone_android_outlined,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Enter your phone number' : null,
                    ),

                    const SizedBox(height: 14),

                    // Department
                    TextFormField(
                      controller: _sellerDeptController,
                      decoration: _inputDecoration(
                        label: 'Department',
                        hint: 'e.g. Computer Science',
                        icon: Icons.school_outlined,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Submit Button
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitItem,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_circle_outline, size: 20),
                  label: Text(
                    _isLoading ? 'Publishing Listing...' : 'Post Item for Sale',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePickerSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Product Photo',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Upload a photo or select a campus preset image',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),

          // Main Image Preview Box
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildImagePreviewWidget(),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Quick Presets Row
          const Text(
            'Or pick a matching campus photo preset:',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _sampleImages.map((sample) {
                final isSelected = _selectedPresetUrl == sample['url'];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPresetUrl = sample['url'];
                      _pickedXFile = null;
                      _imageBytes = null;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFE8F5E9) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF1B5E20) : const Color(0xFFE2E8F0),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected) ...[
                          const Icon(Icons.check, size: 14, color: Color(0xFF1B5E20)),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          sample['label']!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? const Color(0xFF1B5E20) : const Color(0xFF334155),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreviewWidget() {
    if (_imageBytes != null) {
      return Image.memory(_imageBytes!, fit: BoxFit.cover, width: double.infinity);
    }
    if (_selectedPresetUrl != null) {
      return Image.network(_selectedPresetUrl!, fit: BoxFit.cover, width: double.infinity);
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.add_a_photo_outlined, size: 44, color: Color(0xFF1B5E20)),
          SizedBox(height: 8),
          Text(
            'Tap to choose image from device',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
          ),
          SizedBox(height: 4),
          Text(
            'JPG, PNG or choose from presets below',
            style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    String? prefixText,
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixText: prefixText,
      prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
      prefixIcon: icon != null ? Icon(icon, size: 20, color: const Color(0xFF64748B)) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF1B5E20), width: 1.8),
      ),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}
