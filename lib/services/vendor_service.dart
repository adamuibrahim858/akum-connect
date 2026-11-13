import '../models/vendor_item.dart';

class VendorService {
  // Singleton pattern so items posted in SellItemPage persist across page switches
  static final VendorService _instance = VendorService._internal();
  factory VendorService() => _instance;

  VendorService._internal() {
    _initDefaultItems();
  }

  final List<VendorItem> _items = [];

  void _initDefaultItems() {
    if (_items.isNotEmpty) return;

    _items.addAll([
      VendorItem(
        id: 1,
        itemName: 'HP Pavilion 15 (Core i5, 8GB RAM, 512GB SSD)',
        itemPrice: '185,000',
        originalPrice: '220,000',
        category: 'Laptops & Gadgets',
        itemDescription:
            'Very clean UK-used HP Pavilion 15. Intel Core i5 10th Gen, 8GB DDR4 RAM, 512GB NVMe SSD, backlit keyboard, FHD 1080p display. Battery backup lasts 5-6 hours on normal student workload (coding, browsing, slides). Comes with original charger and free laptop sleeve.',
        itemImagePath:
            'https://images.unsplash.com/photo-1588872657578-7efd1f1555ed?w=800&q=80',
        name: 'Ibrahim Bello',
        faculty: 'Faculty of Computing',
        department: 'Computer Science',
        phone: '08034567891',
        email: 'ibrahim.bello@students.akum.edu.ng',
        badge: 'FLASH SALE',
        rating: 4.9,
        reviewsCount: 38,
        condition: 'Like New',
        soldCount: 14,
        isFeatured: true,
      ),
      VendorItem(
        id: 2,
        itemName: 'Apple MacBook Air M1 (Silver, 256GB SSD, 94% Battery)',
        itemPrice: '450,000',
        originalPrice: '495,000',
        category: 'Laptops & Gadgets',
        itemDescription:
            'Pristine condition Apple MacBook Air M1 with 8-core CPU and 7-core GPU, 8GB unified memory, 256GB SSD. Battery health is at 94% with only 78 cycle counts. Perfect for programming, UI design, and academic research. Comes in original box with 30W USB-C brick and braided cable.',
        itemImagePath:
            'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=800&q=80',
        name: 'Fatima Zahra',
        faculty: 'Faculty of Computing',
        department: 'Software Engineering',
        phone: '08123456780',
        email: 'fatima.zahra@students.akum.edu.ng',
        badge: 'TOP CHOICE',
        rating: 5.0,
        reviewsCount: 52,
        condition: 'Like New',
        soldCount: 9,
        isFeatured: true,
      ),
      VendorItem(
        id: 3,
        itemName: 'Oraimo 20000mAh Ultra-Fast Charging Power Bank',
        itemPrice: '18,500',
        originalPrice: '24,000',
        category: 'Laptops & Gadgets',
        itemDescription:
            'Original Oraimo 20,000mAh high capacity power bank with 22.5W two-way fast charge. Multi-protection safety system, dual USB outputs, Type-C in/out, and LED digital battery percentage display. Survived entire exam week on campus without blackout worries.',
        itemImagePath:
            'https://images.unsplash.com/photo-1609592424109-dd9892f1b177?w=800&q=80',
        name: 'Usman Danladi',
        faculty: 'Faculty of Engineering',
        department: 'Electrical Engineering',
        phone: '08087654321',
        email: 'usman.danladi@students.akum.edu.ng',
        badge: 'BEST SELLER',
        rating: 4.8,
        reviewsCount: 64,
        condition: 'Brand New',
        soldCount: 42,
        isFeatured: true,
      ),
      VendorItem(
        id: 4,
        itemName: 'Wireless Active Noise-Cancelling Bluetooth Over-Ear Headphones',
        itemPrice: '14,000',
        originalPrice: '19,500',
        category: 'Laptops & Gadgets',
        itemDescription:
            'Deep bass studio sound with active hybrid noise cancelling (ANC). 40 hours battery life with quick charge (10 mins gives 4 hours playback). Soft protein memory foam earcups for prolonged library study sessions. Foldable design with aux cable included.',
        itemImagePath:
            'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=800&q=80',
        name: 'Aisha Mohammed',
        faculty: 'Faculty of Arts & Social Sciences',
        department: 'Mass Communication',
        phone: '09012345678',
        email: 'aisha.m@students.akum.edu.ng',
        badge: '-28% OFF',
        rating: 4.7,
        reviewsCount: 29,
        condition: 'Brand New',
        soldCount: 21,
        isFeatured: false,
      ),
      VendorItem(
        id: 5,
        itemName: 'Essential Engineering Mathematics (K.A. Stroud, 7th Edition)',
        itemPrice: '6,500',
        originalPrice: '10,000',
        category: 'Textbooks',
        itemDescription:
            'The gold standard handbook for all 100L - 300L engineering and physical sciences math courses (MTH 101, 102, 201, 202). Clear worked examples, practice problems with answers, and step-by-step calculus foundations. Clean pages with minimal pencil highlights.',
        itemImagePath:
            'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=800&q=80',
        name: 'Samuel Okafor',
        faculty: 'Faculty of Engineering',
        department: 'Civil Engineering',
        phone: '08023456789',
        email: 'samuel.okafor@students.akum.edu.ng',
        badge: 'MUST HAVE',
        rating: 4.9,
        reviewsCount: 45,
        condition: 'Fairly Used',
        soldCount: 30,
        isFeatured: false,
      ),
      VendorItem(
        id: 6,
        itemName: 'Guyton & Hall Textbook of Medical Physiology (South Asian Ed.)',
        itemPrice: '16,000',
        originalPrice: '22,000',
        category: 'Textbooks',
        itemDescription:
            'Indispensable reference for medical, nursing, and basic medical science students. Comprehensive coverage of cardiovascular, neurophysiology, endocrine, and renal systems with full-color diagrams. Hardcover binding with clean unmarked pages.',
        itemImagePath:
            'https://images.unsplash.com/photo-1532012164546-f432f2e3777f?w=800&q=80',
        name: 'Zainab Aliyu',
        faculty: 'Faculty of Health Sciences',
        department: 'Medicine & Surgery',
        phone: '08134567892',
        email: 'zainab.aliyu@students.akum.edu.ng',
        badge: 'HOT DEAL',
        rating: 5.0,
        reviewsCount: 22,
        condition: 'Like New',
        soldCount: 16,
        isFeatured: true,
      ),
      VendorItem(
        id: 7,
        itemName: 'Introduction to Algorithms (CLRS 3rd Edition, Hardcover)',
        itemPrice: '12,000',
        originalPrice: '15,000',
        category: 'Textbooks',
        itemDescription:
            'The comprehensive algorithms bible covering data structures, dynamic programming, greedy algorithms, graph theory, and NP-completeness. Crucial for CSC 202, CSC 301, and technical coding interviews.',
        itemImagePath:
            'https://images.unsplash.com/photo-1512820790803-83ca734da794?w=800&q=80',
        name: 'David Adeleke',
        faculty: 'Faculty of Computing',
        department: 'Computer Science',
        phone: '08098765432',
        email: 'david.adeleke@students.akum.edu.ng',
        badge: 'STUDENT PICK',
        rating: 4.8,
        reviewsCount: 19,
        condition: 'Like New',
        soldCount: 11,
        isFeatured: false,
      ),
      VendorItem(
        id: 8,
        itemName: 'Complete Nigerian Law of Contract Summary & Past Questions',
        itemPrice: '4,500',
        originalPrice: '7,000',
        category: 'Textbooks',
        itemDescription:
            'Comprehensive spiral-bound compendium covering Offer & Acceptance, Consideration, Capacity, Mistake, Misrepresentation, and Discharge of Contract with Supreme Court case citations and 5 years solved past examination questions.',
        itemImagePath:
            'https://images.unsplash.com/photo-1457369804613-52c61a468e7d?w=800&q=80',
        name: 'Halima Garba',
        faculty: 'Faculty of Law',
        department: 'Private & Property Law',
        phone: '08167890123',
        email: 'halima.garba@students.akum.edu.ng',
        badge: '-35% OFF',
        rating: 4.9,
        reviewsCount: 31,
        condition: 'Brand New',
        soldCount: 27,
        isFeatured: false,
      ),
      VendorItem(
        id: 9,
        itemName: 'Rechargeable Solar-Ready Desk Fan with Dual LED Reading Lamps',
        itemPrice: '19,500',
        originalPrice: '25,000',
        category: 'Hostel Essentials',
        itemDescription:
            'Hostel life saver during heat and power outage! 12-inch 3-speed oscillating desk fan with built-in 6000mAh battery (runs 6-9 hours). Features bright adjustable dual LED night study lights, USB phone charging port, and DC solar panel input socket.',
        itemImagePath:
            'https://images.unsplash.com/photo-1618941716939-553df3c6c278?w=800&q=80',
        name: 'Maryam Sani',
        faculty: 'Faculty of Science',
        department: 'Biological Sciences',
        phone: '08056789012',
        email: 'maryam.sani@students.akum.edu.ng',
        badge: 'CAMPUS FAVORITE',
        rating: 4.9,
        reviewsCount: 57,
        condition: 'Brand New',
        soldCount: 48,
        isFeatured: true,
      ),
      VendorItem(
        id: 10,
        itemName: '2-Burner Stainless Tabletop Gas Cooker + 3kg Gas Cylinder Set',
        itemPrice: '38,000',
        originalPrice: '45,000',
        category: 'Hostel Essentials',
        itemDescription:
            'Complete hostel kitchen setup ready to cook! Automatic piezoelectric ignition (no matches needed), durable stainless steel top, heavy cast burners. Includes full 3kg gas cylinder, premium hose, and regulator clamp. Selling because graduating.',
        itemImagePath:
            'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?w=800&q=80',
        name: 'Emmanuel Eze',
        faculty: 'Faculty of Arts & Social Sciences',
        department: 'Economics',
        phone: '08145678901',
        email: 'emmanuel.eze@students.akum.edu.ng',
        badge: 'HOSTEL PACK',
        rating: 4.8,
        reviewsCount: 23,
        condition: 'Like New',
        soldCount: 8,
        isFeatured: false,
      ),
      VendorItem(
        id: 11,
        itemName: 'Fast Boiling 2.0L Stainless Steel Electric Water Kettle',
        itemPrice: '7,500',
        originalPrice: '11,000',
        category: 'Hostel Essentials',
        itemDescription:
            '1500W rapid boil electric kettle with automatic shut-off and boil-dry protection. 360-degree rotational power base, cool-touch ergonomic handle, and food-grade stainless steel interior. Perfect for morning tea, noodles, and hot water.',
        itemImagePath:
            'https://images.unsplash.com/photo-1574269909862-7e1d70bb8078?w=800&q=80',
        name: 'Khadija Umar',
        faculty: 'Faculty of Science',
        department: 'Microbiology',
        phone: '08031234567',
        email: 'khadija.umar@students.akum.edu.ng',
        badge: '-31% OFF',
        rating: 4.6,
        reviewsCount: 39,
        condition: 'Brand New',
        soldCount: 34,
        isFeatured: false,
      ),
      VendorItem(
        id: 12,
        itemName: 'Heavy-Duty Foldable Metal Clothes Drying Rack & Hanger Pack',
        itemPrice: '8,500',
        originalPrice: '12,000',
        category: 'Hostel Essentials',
        itemDescription:
            'Space-saving 2-tier collapsible clothes drying horse rack. Holds over 20kg of wet laundry easily. Rust-proof coated iron pipes with anti-skid rubber feet. Folds flat in 2 seconds to slip under the hostel bunk bed. Comes with 10 free clothes clips.',
        itemImagePath:
            'https://images.unsplash.com/photo-1582735689369-4fe89db7114c?w=800&q=80',
        name: 'Amina Kassim',
        faculty: 'Faculty of Arts & Social Sciences',
        department: 'Sociology',
        phone: '08178901234',
        email: 'amina.kassim@students.akum.edu.ng',
        badge: 'DORM READY',
        rating: 4.7,
        reviewsCount: 17,
        condition: 'Like New',
        soldCount: 15,
        isFeatured: false,
      ),
      VendorItem(
        id: 13,
        itemName: 'AKUM University Branded Premium Fleece Hoodie (Forest Green)',
        itemPrice: '15,000',
        originalPrice: '20,000',
        category: 'Fashion & Wears',
        itemDescription:
            'Official university colors thick combed cotton-fleece hoodie with high-definition embroidered AKUM crest on chest. Kangaroo pouch pocket, ribbed cuffs, and drawstring hood. Unbelievably warm during Harmattan morning lectures.',
        itemImagePath:
            'https://images.unsplash.com/photo-1556905055-8f358a7a47b2?w=800&q=80',
        name: 'Campus Brand Hub',
        faculty: 'Student Affairs Division',
        department: 'Campus Merch Store',
        phone: '08022223344',
        email: 'merchandise@akum.edu.ng',
        badge: 'OFFICIAL MERCH',
        rating: 5.0,
        reviewsCount: 88,
        condition: 'Brand New',
        soldCount: 76,
        isFeatured: true,
      ),
      VendorItem(
        id: 14,
        itemName: 'Nike Air Force 1 Low-Top Sneakers (Triple White, Unisex)',
        itemPrice: '24,000',
        originalPrice: '32,000',
        category: 'Fashion & Wears',
        itemDescription:
            'Iconic street and campus sneaker with premium leather upper, perforated toe box for airflow, and encapsulated air-cushioned midsole. Size 42, 43, 44 available. 100% clean condition, pairs well with jeans, chinos, and faculty polo shirts.',
        itemImagePath:
            'https://images.unsplash.com/photo-1552346154-21d32810aba3?w=800&q=80',
        name: 'Chinedu Obi',
        faculty: 'Faculty of Management Sciences',
        department: 'Accounting',
        phone: '08189012345',
        email: 'chinedu.obi@students.akum.edu.ng',
        badge: 'POPULAR',
        rating: 4.8,
        reviewsCount: 41,
        condition: 'Brand New',
        soldCount: 29,
        isFeatured: true,
      ),
      VendorItem(
        id: 15,
        itemName: 'Tailored Formal Senate Shirt & Trousers Pair (Navy Blue & White)',
        itemPrice: '16,500',
        originalPrice: '22,000',
        category: 'Fashion & Wears',
        itemDescription:
            'Crisp formal button-down cotton shirt paired with slim-fit formal trousers. Designed strictly compliant with university senate dress code for presentations, seminars, and defense days. Wrinkle-resistant material.',
        itemImagePath:
            'https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf?w=800&q=80',
        name: 'Abubakar Sadiq',
        faculty: 'Faculty of Management Sciences',
        department: 'Business Administration',
        phone: '08067890123',
        email: 'abubakar.sadiq@students.akum.edu.ng',
        badge: 'SENATE READY',
        rating: 4.7,
        reviewsCount: 14,
        condition: 'Brand New',
        soldCount: 19,
        isFeatured: false,
      ),
      VendorItem(
        id: 16,
        itemName: 'Ergonomic Waterproof Campus Laptop Backpack with USB Charging Port',
        itemPrice: '13,500',
        originalPrice: '18,000',
        category: 'Fashion & Wears',
        itemDescription:
            'Multi-compartment student backpack with dedicated 15.6 inch padded laptop pocket, anti-theft hidden pocket, water bottle side mesh, and external USB passthrough port for power banks. High-density water-resistant nylon.',
        itemImagePath:
            'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=800&q=80',
        name: 'Grace John',
        faculty: 'Faculty of Management Sciences',
        department: 'Public Administration',
        phone: '08156789012',
        email: 'grace.john@students.akum.edu.ng',
        badge: 'BEST SELLER',
        rating: 4.9,
        reviewsCount: 63,
        condition: 'Brand New',
        soldCount: 54,
        isFeatured: false,
      ),
      VendorItem(
        id: 17,
        itemName: 'Fresh Gourmet Red Velvet & Vanilla Cupcakes Box (Pack of 6)',
        itemPrice: '4,500',
        originalPrice: '6,000',
        category: 'Food & Snacks',
        itemDescription:
            'Moist, freshly-baked artisan cupcakes topped with fluffy cream cheese swirl and Belgian chocolate shavings. Baked daily with quality butter and love. Free hostel corridor delivery within 30 minutes!',
        itemImagePath:
            'https://images.unsplash.com/photo-1587668178277-295251f900ce?w=800&q=80',
        name: 'Hauwa Kitchen',
        faculty: 'Faculty of Agriculture',
        department: 'Food Science & Technology',
        phone: '08078901234',
        email: 'hauwa.kitchen@students.akum.edu.ng',
        badge: 'FRESH TODAY',
        rating: 5.0,
        reviewsCount: 74,
        condition: 'Freshly Made',
        soldCount: 92,
        isFeatured: true,
      ),
      VendorItem(
        id: 18,
        itemName: 'Crispy Tender Beef Kilishi Pack (Gusau Recipe, 250g Vacuum Pack)',
        itemPrice: '3,500',
        originalPrice: '4,500',
        category: 'Food & Snacks',
        itemDescription:
            'Authentic Northern dried lean beef kilishi infused with traditional yaji pepper spice, groundnut powder, and ginger garlic glaze. Non-greasy, rich in protein, and hygienically vacuum sealed to last months in your locker.',
        itemImagePath:
            'https://images.unsplash.com/photo-1544025162-d76694265947?w=800&q=80',
        name: 'Mukhtar Kabir',
        faculty: 'Faculty of Agriculture',
        department: 'Animal Science',
        phone: '08190123456',
        email: 'mukhtar.kabir@students.akum.edu.ng',
        badge: 'TOP SNACK',
        rating: 4.9,
        reviewsCount: 59,
        condition: 'Freshly Sealed',
        soldCount: 83,
        isFeatured: false,
      ),
      VendorItem(
        id: 19,
        itemName: 'Final Year Project Typing, NUC Formatting & Hardcover Binding',
        itemPrice: '5,000',
        originalPrice: '8,000',
        category: 'Campus Services',
        itemDescription:
            'Fast, accurate academic project typesetting following strict university departmental guidelines (Times New Roman 12, double spaced, APA/IEEE reference styling). Plagiarism check report included. Express 24h turnaround available.',
        itemImagePath:
            'https://images.unsplash.com/photo-1586075010923-2dd4570fb338?w=800&q=80',
        name: 'SmartPrint Academic Hub',
        faculty: 'Central University Library Complex',
        department: 'Digital Printing Center',
        phone: '08033334455',
        email: 'smartprint@akum.edu.ng',
        badge: 'VERIFIED PRO',
        rating: 4.9,
        reviewsCount: 96,
        condition: 'Professional Service',
        soldCount: 110,
        isFeatured: true,
      ),
      VendorItem(
        id: 20,
        itemName: 'Creative Graphic Design, Event Flyers & Association Banners',
        itemPrice: '3,000',
        originalPrice: '5,000',
        category: 'Campus Services',
        itemDescription:
            'Eye-catching social media flyers for departmental week, faculty elections, Christian/Muslim fellowship summits, birthday shoot covers, and business logos. Delivers high-res PNG, PDF, and source files within 12 hours.',
        itemImagePath:
            'https://images.unsplash.com/photo-1626785774573-4b799315345d?w=800&q=80',
        name: 'Farouk Tech & Design',
        faculty: 'Faculty of Computing',
        department: 'Computer Engineering',
        phone: '08044445566',
        email: 'farouk.design@students.akum.edu.ng',
        badge: '-40% OFF',
        rating: 4.8,
        reviewsCount: 42,
        condition: 'Digital Service',
        soldCount: 65,
        isFeatured: false,
      ),
    ]);
  }

  Future<List<VendorItem>> fetchVendors() async {
    // Return cloned list to prevent unwanted mutations
    return List<VendorItem>.from(_items);
  }

  Future<VendorItem> fetchVendorById(int id) async {
    return _items.firstWhere(
      (item) => item.id == id,
      orElse: () => _items.first,
    );
  }

  Future<void> postVendorItem({
    required String name,
    required String email,
    required String phone,
    required String matricNo,
    required String faculty,
    required String department,
    required String itemName,
    required String itemDescription,
    required String itemPrice,
    required String imagePath,
    String category = 'General',
  }) async {
    // Generate new unique ID
    final newId = DateTime.now().millisecondsSinceEpoch;

    final newItem = VendorItem(
      id: newId,
      itemName: itemName,
      itemPrice: itemPrice,
      originalPrice: null,
      category: category,
      itemDescription: itemDescription,
      itemImagePath: imagePath.isNotEmpty
          ? imagePath
          : 'https://images.unsplash.com/photo-1526170375885-4d8ecf77b99f?w=800&q=80',
      name: name,
      faculty: faculty,
      department: department,
      phone: phone,
      email: email,
      badge: 'NEW ARRIVAL',
      rating: 5.0,
      reviewsCount: 1,
      condition: 'Listed by Student',
      soldCount: 0,
      isFeatured: true,
    );

    // Prepend so new items appear right at top of feed
    _items.insert(0, newItem);
  }

  // Get all unique categories for tabs
  List<String> getCategories() {
    final Set<String> categories = {'All'};
    for (final item in _items) {
      if (item.category.isNotEmpty) {
        categories.add(item.category);
      }
    }
    return categories.toList();
  }
}
