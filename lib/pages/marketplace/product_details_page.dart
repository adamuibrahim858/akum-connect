import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/vendor_item.dart';
import '../../services/vendor_service.dart';

class ProductDetailsPage extends StatefulWidget {
  final int productId;
  final VendorItem? previewItem;

  const ProductDetailsPage({
    super.key,
    required this.productId,
    this.previewItem,
  });

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  late Future<VendorItem> _itemFuture;
  final VendorService _vendorService = VendorService();

  @override
  void initState() {
    super.initState();
    _itemFuture = _vendorService.fetchVendorById(widget.productId);
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (!await launchUrl(launchUri)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not call $phoneNumber')));
      }
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri launchUri = Uri(scheme: 'mailto', path: email);
    if (!await launchUrl(launchUri)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not email $email')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<VendorItem>(
        future: _itemFuture,
        initialData: widget.previewItem,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text("Error: ${snapshot.error}"),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: Text("Item not found"));
          }

          final item = snapshot.data!;
          final bool isPreview =
              snapshot.connectionState == ConnectionState.waiting;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Image
                Hero(
                  tag: 'product_${item.id}',
                  child: Container(
                    height: 300,
                    width: double.infinity,
                    decoration: const BoxDecoration(color: Colors.white),
                    child: CachedNetworkImage(
                      imageUrl: item.fullImagePath.isNotEmpty
                          ? item.fullImagePath
                          : 'https://invalid-url.com', // triggers error widget safely
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.image_not_supported,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),

                if (isPreview) const LinearProgressIndicator(),

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Price
                      Text(
                        '₦${item.itemPrice}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Product Name
                      Text(
                        item.itemName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Description
                      const Text(
                        "Description",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.itemDescription.isNotEmpty
                            ? item.itemDescription
                            : "No description available.",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 32),
                      const Divider(thickness: 1),
                      const SizedBox(height: 16),

                      // Seller Info Card
                      Text(
                        'Seller Information',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.green.withValues(
                                      alpha: 0.1,
                                    ),
                                    child: Text(
                                      item.name.isNotEmpty
                                          ? item.name[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        if (item.department.isNotEmpty)
                                          Text(
                                            'Department: ${item.department}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        if (item.faculty.isNotEmpty)
                                          Text(
                                            'Faculty: ${item.faculty}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.black87,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _actionButton(
                                    icon: Icons.phone,
                                    label: "Call",
                                    color: Colors.green,
                                    onTap: () => _makePhoneCall(item.phone),
                                  ),
                                  _actionButton(
                                    icon: Icons.email,
                                    label: "Email",
                                    color: Colors.blue,
                                    onTap: () => _sendEmail(item.email),
                                  ),
                                  // Optional WhatsApp could go here
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
