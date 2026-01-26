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
  });

  factory VendorItem.fromJson(Map<String, dynamic> json) {
    String imagePath = json['item_image_path'] ?? '';
    // Sanitise bad data from seeders
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
    );
  }

  // Helper code to get the correct URL for display
  String get fullImagePath {
    if (itemImagePath.isEmpty) return '';
    if (itemImagePath.startsWith('http')) return itemImagePath;
    // Assuming relative path stored in DB needs storage prefix
    // NOTE: This hostname should ideally come from a config, but hardcoding for now as per task
    return 'https://akum-connect.mamat.com.ng/storage/$itemImagePath';
  }
}
