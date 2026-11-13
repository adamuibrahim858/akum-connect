import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/vendor_item.dart';
import '../../services/vendor_service.dart';
import 'product_details_page.dart';
import 'sell_item_page.dart';

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({super.key});

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  final VendorService _vendorService = VendorService();
  final TextEditingController _searchController = TextEditingController();

  List<VendorItem> _allItems = [];
  List<VendorItem> _filteredItems = [];
  bool _isLoading = true;

  String _selectedCategory = 'All';
  String _selectedSort = 'Featured'; // Featured, Price: Low to High, Price: High to Low, Rating
  final Set<int> _favoriteIds = {};

  // Promo Banners (AliExpress / Jumia carousel style)
  final List<Map<String, dynamic>> _promoBanners = [
    {
      'title': 'Semester Tech Deals',
      'subtitle': 'Laptops, powerbanks & audio up to 30% OFF',
      'tag': 'CAMPUS EXCLUSIVE',
      'color1': const Color(0xFF1B5E20),
      'color2': const Color(0xFF388E3C),
      'icon': Icons.laptop_mac_rounded,
    },
    {
      'title': 'Hostel Room Starter Pack',
      'subtitle': 'Fans, kettles, gas cookers & drying racks',
      'tag': 'STUDENT ESSENTIALS',
      'color1': const Color(0xFFE65100),
      'color2': const Color(0xFFF57C00),
      'icon': Icons.roofing_rounded,
    },
    {
      'title': 'Academic Book Exchange',
      'subtitle': 'Past questions, syllabus textbooks & summaries',
      'tag': 'SAVE UP TO 45%',
      'color1': const Color(0xFF0D47A1),
      'color2': const Color(0xFF1976D2),
      'icon': Icons.menu_book_rounded,
    },
  ];
  int _activeBannerIndex = 0;
  final PageController _bannerController = PageController();

  @override
  void initState() {
    super.initState();
    _loadItems();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bannerController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    final items = await _vendorService.fetchVendors();
    if (mounted) {
      setState(() {
        _allItems = items;
        _isLoading = false;
        _applyFilters();
      });
    }
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();
    List<VendorItem> result = List.from(_allItems);

    // 1. Search Query
    if (query.isNotEmpty) {
      result = result.where((item) {
        final nameMatch = item.itemName.toLowerCase().contains(query);
        final descMatch = item.itemDescription.toLowerCase().contains(query);
        final sellerMatch = item.name.toLowerCase().contains(query);
        final deptMatch = item.department.toLowerCase().contains(query);
        final catMatch = item.category.toLowerCase().contains(query);
        return nameMatch || descMatch || sellerMatch || deptMatch || catMatch;
      }).toList();
    }

    // 2. Category Filter
    if (_selectedCategory != 'All') {
      result = result.where((item) => item.category == _selectedCategory).toList();
    }

    // 3. Sorting
    if (_selectedSort == 'Price: Low to High') {
      result.sort((a, b) => _parsePrice(a.itemPrice).compareTo(_parsePrice(b.itemPrice)));
    } else if (_selectedSort == 'Price: High to Low') {
      result.sort((a, b) => _parsePrice(b.itemPrice).compareTo(_parsePrice(a.itemPrice)));
    } else if (_selectedSort == 'Top Rated') {
      result.sort((a, b) => b.rating.compareTo(a.rating));
    } else if (_selectedSort == 'Popular') {
      result.sort((a, b) => b.soldCount.compareTo(a.soldCount));
    } else {
      // Featured
      result.sort((a, b) {
        if (a.isFeatured == b.isFeatured) return b.id.compareTo(a.id);
        return a.isFeatured ? -1 : 1;
      });
    }

    setState(() {
      _filteredItems = result;
    });
  }

  double _parsePrice(String price) {
    try {
      return double.parse(price.replaceAll(',', '').replaceAll('₦', '').trim());
    } catch (_) {
      return 0.0;
    }
  }

  void _toggleFavorite(int id) {
    setState(() {
      if (_favoriteIds.contains(id)) {
        _favoriteIds.remove(id);
      } else {
        _favoriteIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final categories = _vendorService.getCategories();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: _buildECommerceAppBar(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SellItemPage()),
          );
          if (result == true) {
            _loadItems();
          }
        },
        icon: const Icon(Icons.add_shopping_cart_rounded, color: Colors.white),
        label: const Text(
          'Sell on Campus',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1B5E20),
        elevation: 4,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
            )
          : RefreshIndicator(
              color: const Color(0xFF1B5E20),
              onRefresh: _loadItems,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Promotional Deals Carousel (Jumia / Temu header banners)
                  SliverToBoxAdapter(
                    child: _buildBannerCarousel(),
                  ),

                  // Horizontal Category Pills
                  SliverToBoxAdapter(
                    child: _buildCategoryTabs(categories),
                  ),

                  // Filter & Count Bar
                  SliverToBoxAdapter(
                    child: _buildSortFilterHeader(),
                  ),

                  // Product Grid or Empty State
                  _filteredItems.isEmpty
                      ? SliverFillRemaining(
                          hasScrollBody: false,
                          child: _buildEmptyState(),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
                          sliver: SliverGrid(
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 260,
                              childAspectRatio: 0.63,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final item = _filteredItems[index];
                                return _buildECommerceCard(item);
                              },
                              childCount: _filteredItems.length,
                            ),
                          ),
                        ),
                ],
              ),
            ),
    );
  }

  // Modern E-commerce App Bar
  PreferredSizeWidget _buildECommerceAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1B5E20),
      foregroundColor: Colors.white,
      elevation: 0,
      title: const Row(
        children: [
          Icon(Icons.storefront_rounded, size: 22, color: Colors.white),
          SizedBox(width: 8),
          Text(
            'AKUM Campus Mall',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.3),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Safety Guidelines',
          icon: const Icon(Icons.shield_outlined),
          onPressed: _showSafetyGuidelinesDialog,
        ),
        IconButton(
          tooltip: 'Saved Items (${_favoriteIds.length})',
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.favorite_border_rounded),
              if (_favoriteIds.isNotEmpty)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${_favoriteIds.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _favoriteIds.isEmpty
                      ? 'No items saved to favorites yet.'
                      : '${_favoriteIds.length} item(s) saved in your campus wishlist.',
                ),
                backgroundColor: const Color(0xFF1B5E20),
              ),
            );
          },
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(62),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search laptops, textbooks, hostel gear...',
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF1B5E20), size: 22),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : const Icon(Icons.tune_rounded, color: Color(0xFF64748B), size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Promotional Deals Banner Carousel
  Widget _buildBannerCarousel() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Column(
        children: [
          SizedBox(
            height: 124,
            child: PageView.builder(
              controller: _bannerController,
              itemCount: _promoBanners.length,
              onPageChanged: (idx) => setState(() => _activeBannerIndex = idx),
              itemBuilder: (context, index) {
                final promo = _promoBanners[index];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [promo['color1'] as Color, promo['color2'] as Color],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (promo['color1'] as Color).withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                promo['tag'] as String,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              promo['title'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              promo['subtitle'] as String,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          promo['icon'] as IconData,
                          size: 34,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          // Dots Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_promoBanners.length, (idx) {
              final isActive = idx == _activeBannerIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 18 : 6,
                height: 5,
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF1B5E20) : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // Horizontal Category Tabs
  Widget _buildCategoryTabs(List<String> categories) {
    return Container(
      height: 44,
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = cat == _selectedCategory;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _selectedCategory = cat;
                  _applyFilters();
                });
              },
              selectedColor: const Color(0xFF1B5E20),
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF334155),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF1B5E20) : const Color(0xFFE2E8F0),
                ),
              ),
              showCheckmark: false,
              elevation: isSelected ? 2 : 0,
            ),
          );
        },
      ),
    );
  }

  // Sort and Filter Row
  Widget _buildSortFilterHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                '${_filteredItems.length} Products Found',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              if (_selectedCategory != 'All') ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _selectedCategory,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                ),
              ],
            ],
          ),

          // Sort Dropdown
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedSort,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF1B5E20)),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1B5E20)),
              borderRadius: BorderRadius.circular(12),
              items: const [
                DropdownMenuItem(value: 'Featured', child: Text('Sort: Featured')),
                DropdownMenuItem(value: 'Popular', child: Text('Sort: Best Sellers')),
                DropdownMenuItem(value: 'Top Rated', child: Text('Sort: Top Rated')),
                DropdownMenuItem(value: 'Price: Low to High', child: Text('Price: Low to High')),
                DropdownMenuItem(value: 'Price: High to Low', child: Text('Price: High to Low')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedSort = val;
                    _applyFilters();
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // Modern E-commerce Product Card (AliExpress / Temu / Jumia Style)
  Widget _buildECommerceCard(VendorItem item) {
    final isFav = _favoriteIds.contains(item.id);
    final discount = item.discountPercentage;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailsPage(
              productId: item.id,
              previewItem: item,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with Overlays
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'product_${item.id}',
                    child: CachedNetworkImage(
                      imageUrl: item.fullImagePath,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: const Color(0xFFF1F5F9),
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: const Color(0xFFF1F5F9),
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.grey,
                          size: 32,
                        ),
                      ),
                    ),
                  ),

                  // Floating Badges (Top Left)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item.badge != null && item.badge!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDC2626), // Temu / AliExpress vibrant red
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 3,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Text(
                              item.badge!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        if (discount > 0) ...[
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE65100),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '-$discount%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Favorite Button (Top Right)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () => _toggleFavorite(item.id),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          size: 16,
                          color: isFav ? Colors.red : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),

                  // Condition Chip (Bottom Left)
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.condition,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Product Details Block
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Product Title
                    Text(
                      item.itemName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                        height: 1.25,
                      ),
                    ),

                    // Price & Discount Line
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            const Text(
                              '₦',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1B5E20),
                              ),
                            ),
                            Text(
                              item.itemPrice,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1B5E20),
                              ),
                            ),
                            if (item.originalPrice != null) ...[
                              const SizedBox(width: 5),
                              Text(
                                '₦${item.originalPrice}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  decoration: TextDecoration.lineThrough,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 3),

                        // Rating & Sold Stats
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 13, color: Color(0xFFF59E0B)),
                            const SizedBox(width: 2),
                            Text(
                              item.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF334155),
                              ),
                            ),
                            Text(
                              ' (${item.reviewsCount})',
                              style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                            ),
                            const Spacer(),
                            Text(
                              '${item.soldCount} sold',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Vendor Info footer
                    Row(
                      children: [
                        const Icon(Icons.person_pin_circle_outlined, size: 12, color: Color(0xFF1B5E20)),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            '${item.name} • ${item.department}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Empty State
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 64,
                color: Color(0xFF1B5E20),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No items match your search',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try adjusting your search terms or switch to another category.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _selectedCategory = 'All';
                  _selectedSort = 'Featured';
                  _applyFilters();
                });
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reset All Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Safety Guidelines Dialog
  void _showSafetyGuidelinesDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.verified_user_rounded, color: Color(0xFF1B5E20)),
            SizedBox(width: 8),
            Text('Campus Trade Safety'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Abdulkadir Kure University Peer-to-Peer Trading Guidelines:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              SizedBox(height: 12),
              _SafetyTip(
                number: '1',
                title: 'Meet in Daylight at Campus Landmarks',
                detail: 'Arrange physical exchanges at verified spots such as the University Central Library, Student Center, or Faculty Cafeteria.',
              ),
              _SafetyTip(
                number: '2',
                title: 'Inspect the Product Thoroughly',
                detail: 'Test electronics, verify textbook editions and check serial numbers before transferring money.',
              ),
              _SafetyTip(
                number: '3',
                title: 'No Advance Payments for Strangers',
                detail: 'Never wire deposits or delivery fees to unverified students before seeing the item physically.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF1B5E20)),
            child: const Text('GOT IT, STAY SAFE', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _SafetyTip extends StatelessWidget {
  final String number;
  final String title;
  final String detail;

  const _SafetyTip({
    required this.number,
    required this.title,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: const Color(0xFF1B5E20),
            child: Text(
              number,
              style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
