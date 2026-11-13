class VendorItem {
  final int id;
  final String itemName;
  final String itemPrice;
  final String itemDescription;
  final String itemImagePath;
  final String name; // Seller Name
  final String faculty;
  final String department;
  final String phone;
  final String email;

  // E-commerce enhancements (AliExpress, Jumia, Temu style)
  final String category;
  final String? originalPrice;
  final double rating;
  final int reviewsCount;
  final String condition;
  final String? badge;
  final int soldCount;
  final bool isFeatured;

  VendorItem({
    required this.id,
    required this.itemName,
    required this.itemPrice,
    required this.itemDescription,
    required this.itemImagePath,
    required this.name,
    required this.faculty,
    required this.department,
    required this.phone,
    required this.email,
    this.category = 'All',
    this.originalPrice,
    this.rating = 4.8,
    this.reviewsCount = 18,
    this.condition = 'Like New',
    this.badge,
    this.soldCount = 12,
    this.isFeatured = false,
  });

  factory VendorItem.fromJson(Map<String, dynamic> json) {
    String imagePath = json['item_image_path'] ?? '';
    if (imagePath.contains('placeholder.com')) {
      imagePath = '';
    }

    return VendorItem(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      itemName: json['item_name'] ?? 'Unknown Item',
      itemPrice: json['item_price']?.toString() ?? '0.00',
      itemDescription: json['item_description'] ?? '',
      itemImagePath: imagePath,
      name: json['name'] ?? 'Unknown Seller',
      faculty: json['faculty'] ?? '',
      department: json['department'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      category: json['category'] ?? 'All',
      originalPrice: json['original_price']?.toString(),
      rating: (json['rating'] is num) ? (json['rating'] as num).toDouble() : 4.8,
      reviewsCount: json['reviews_count'] ?? 18,
      condition: json['condition'] ?? 'Like New',
      badge: json['badge'],
      soldCount: json['sold_count'] ?? 12,
      isFeatured: json['is_featured'] ?? false,
    );
  }

  // Calculate discount percentage if original price exists
  int get discountPercentage {
    if (originalPrice == null || originalPrice!.isEmpty) return 0;
    try {
      final cleanCurrent = double.parse(itemPrice.replaceAll(',', '').replaceAll('₦', '').trim());
      final cleanOrig = double.parse(originalPrice!.replaceAll(',', '').replaceAll('₦', '').trim());
      if (cleanOrig > cleanCurrent && cleanOrig > 0) {
        return (((cleanOrig - cleanCurrent) / cleanOrig) * 100).round();
      }
    } catch (_) {}
    return 0;
  }

  // Helper code to get display image URL
  String get fullImagePath {
    if (itemImagePath.isEmpty) {
      return 'https://images.unsplash.com/photo-1526170375885-4d8ecf77b99f?w=600&q=80';
    }
    if (itemImagePath.startsWith('http://') || itemImagePath.startsWith('https://')) {
      return itemImagePath;
    }
    return itemImagePath;
  }
}
