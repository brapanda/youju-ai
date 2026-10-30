import 'package:flutter/foundation.dart';

enum ListingKind { sale, rent }

@immutable
class Property {
  const Property({required this.id, required this.address, required this.area,
    required this.price, required this.beds, required this.baths,
    required this.sqft, required this.kind, required this.type,
    required this.image, required this.longitude, required this.latitude,
    this.tag = '新上房源'});
  final String id, address, area, type, image, tag;
  final int price, beds, baths, sqft;
  final ListingKind kind;
  final double longitude, latitude;
  String get formattedPrice {
    final s = price.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return '\$$s${kind == ListingKind.rent ? ' / 月' : ''}';
  }
}

// All attributes, coordinates and prices are invented for UI review.
// Photographs are cropped from the user's reference video and are not
// assertions about the depicted property's location, price or availability.
const demoProperties = <Property>[
  Property(id:'demo-1', address:'25 Chicago Lane', area:'Markham · Wismer', price:799000, beds:3, baths:3, sqft:1450, kind:ListingKind.sale, type:'联排别墅', image:'assets/images/courtyard.jpg', longitude:-79.275, latitude:43.886, tag:'精选好房'),
  Property(id:'demo-2', address:'18 Garden Walk', area:'Markham · Unionville', price:928000, beds:3, baths:2, sqft:1680, kind:ListingKind.sale, type:'联排别墅', image:'assets/images/townhouse.jpg', longitude:-79.31, latitude:43.86, tag:'新上房源'),
  Property(id:'demo-3', address:'70 Temperance Street', area:'Toronto · Downtown', price:649000, beds:1, baths:1, sqft:620, kind:ListingKind.sale, type:'公寓', image:'assets/images/living.jpg', longitude:-79.382, latitude:43.65, tag:'城市生活'),
  Property(id:'demo-4', address:'88 Harbour Street', area:'Toronto · Waterfront', price:2800, beds:2, baths:2, sqft:890, kind:ListingKind.rent, type:'公寓', image:'assets/images/interior.jpg', longitude:-79.377, latitude:43.641, tag:'品质出租'),
  Property(id:'demo-5', address:'12 Willow Avenue', area:'Richmond Hill · Bayview', price:1289000, beds:4, baths:3, sqft:2150, kind:ListingKind.sale, type:'独立屋', image:'assets/images/townhouse.jpg', longitude:-79.42, latitude:43.86, tag:'宽敞家庭空间'),
  Property(id:'demo-6', address:'36 Parkside Lane', area:'Markham · Cornell', price:3400, beds:3, baths:3, sqft:1500, kind:ListingKind.rent, type:'联排别墅', image:'assets/images/courtyard.jpg', longitude:-79.24, latitude:43.88, tag:'新上出租'),
];

class SearchFilter {
  const SearchFilter({this.query = '', this.kind, this.type, this.minBeds = 0, this.maxPrice});
  final String query;
  final ListingKind? kind;
  final String? type;
  final int minBeds;
  final double? maxPrice;
  List<Property> apply(Iterable<Property> source) => source.where((p) {
    final q = query.toLowerCase().trim();
    return (q.isEmpty || '${p.address} ${p.area} ${p.type}'.toLowerCase().contains(q))
      && (kind == null || p.kind == kind)
      && (type == null || p.type == type)
      && p.beds >= minBeds
      && (maxPrice == null || p.price <= maxPrice!);
  }).toList();
  int get activeCount => (kind != null ? 1 : 0) + (type != null ? 1 : 0) + (minBeds > 0 ? 1 : 0) + (maxPrice != null ? 1 : 0);
}
