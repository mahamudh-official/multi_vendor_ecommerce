/// Mock product entity for local development (Step 1).
///
/// This will be replaced by a real domain entity backed by the API in Step 3.
/// The UI layer (home_page.dart) uses this model — when the real BLoC/API
/// is ready, the widget only needs to change its data source, not its rendering.
class MockProduct {
  const MockProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.originalPrice,
    required this.rating,
    required this.reviewCount,
    required this.category,
    required this.sellerName,
    this.badge,
  });

  final String id;
  final String name;
  final double price;
  final double? originalPrice;
  final double rating;
  final int reviewCount;
  final String category;
  final String sellerName;
  final String? badge;

  bool get hasDiscount =>
      originalPrice != null && originalPrice! > price;

  double get discountPercent {
    if (!hasDiscount) return 0;
    return ((originalPrice! - price) / originalPrice! * 100).roundToDouble();
  }
}

/// Static mock data — local only, no network calls.
const List<MockProduct> kMockProducts = [
  MockProduct(
    id: '1',
    name: 'Premium Wireless Headphones',
    price: 79.99,
    originalPrice: 129.99,
    rating: 4.8,
    reviewCount: 2341,
    category: 'Electronics',
    sellerName: 'TechStore Pro',
    badge: 'Best Seller',
  ),
  MockProduct(
    id: '2',
    name: 'Minimal Leather Wallet',
    price: 34.99,
    originalPrice: null,
    rating: 4.6,
    reviewCount: 891,
    category: 'Accessories',
    sellerName: 'Craft & Co',
    badge: 'New',
  ),
  MockProduct(
    id: '3',
    name: 'Organic Cotton T-Shirt',
    price: 24.99,
    originalPrice: 39.99,
    rating: 4.4,
    reviewCount: 567,
    category: 'Fashion',
    sellerName: 'EcoWear',
    badge: null,
  ),
  MockProduct(
    id: '4',
    name: 'Smart Home Hub',
    price: 149.99,
    originalPrice: 199.99,
    rating: 4.7,
    reviewCount: 1203,
    category: 'Electronics',
    sellerName: 'SmartLife',
    badge: 'Hot',
  ),
  MockProduct(
    id: '5',
    name: 'Artisan Coffee Blend',
    price: 18.99,
    originalPrice: null,
    rating: 4.9,
    reviewCount: 3420,
    category: 'Food & Drink',
    sellerName: 'Roasters Guild',
    badge: 'Top Rated',
  ),
  MockProduct(
    id: '6',
    name: 'Yoga Mat Pro',
    price: 49.99,
    originalPrice: 69.99,
    rating: 4.5,
    reviewCount: 782,
    category: 'Sports',
    sellerName: 'FitLife Store',
    badge: null,
  ),
];

/// Mock categories for the category chip row.
const List<String> kMockCategories = [
  'All',
  'Electronics',
  'Fashion',
  'Accessories',
  'Sports',
  'Food & Drink',
  'Home & Living',
  'Books',
];
