import 'package:flutter_test/flutter_test.dart';
import 'package:youju_ai/core/catalog.dart';

void main() {
  group('Property catalog filters', () {
    test('combines address, transaction, type, bedrooms and price', () {
      const filter = SearchFilter(
        query: '  MARKHAM ',
        kind: ListingKind.sale,
        type: '联排别墅',
        minBeds: 3,
        maxPrice: 900000,
      );
      expect(filter.apply(demoProperties).map((p) => p.id), ['demo-1']);
      expect(filter.activeCount, 4);
    });

    test('rent budget applies to monthly rents', () {
      const filter = SearchFilter(kind: ListingKind.rent, maxPrice: 3000);
      expect(filter.apply(demoProperties).map((p) => p.id), ['demo-4']);
    });

    test('missing matches return no records rather than the full catalog', () {
      expect(const SearchFilter(query: 'no-such-address').apply(demoProperties), isEmpty);
      expect(const SearchFilter(minBeds: 5).apply(demoProperties), isEmpty);
    });

    test('price upper bound and minimum bedrooms include equality', () {
      const filter = SearchFilter(kind: ListingKind.sale, minBeds: 3, maxPrice: 799000);
      expect(filter.apply(demoProperties).map((p) => p.id), ['demo-1']);
    });

    test('reset returns every record without mutating the catalog', () {
      final idsBefore = demoProperties.map((p) => p.id).toList();
      const SearchFilter(kind: ListingKind.sale).apply(demoProperties);
      expect(const SearchFilter().apply(demoProperties), hasLength(6));
      expect(demoProperties.map((p) => p.id), idsBefore);
    });

    test('formats sale prices and monthly rents distinctly', () {
      expect(demoProperties[0].formattedPrice, r'$799,000');
      expect(demoProperties[3].formattedPrice, r'$2,800 / 月');
    });
  });
}
