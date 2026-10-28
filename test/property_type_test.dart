import 'package:flutter_test/flutter_test.dart';
import 'package:qrex_mobile/core/models/property_type.dart';

/// Mirrors the backend `spec_rules` payload for a Plot.
Map<String, dynamic> plotSpec() => {
      'visible': ['price', 'area', 'parking', 'possession_date'],
      'required': ['price', 'area'],
      'hidden': ['bedrooms', 'bathrooms', 'floors', 'furnishing'],
      'defaults': {'bedrooms': 0, 'bathrooms': 0, 'floors': 1, 'parking': 0},
      'area_label': 'Plot Area (sq.ft)',
    };

void main() {
  group('SpecRuleSet', () {
    test('parses the backend payload', () {
      final spec = SpecRuleSet.fromJson(plotSpec());

      expect(spec.visible, contains('area'));
      expect(spec.hides('bedrooms'), isTrue);
      expect(spec.hides('parking'), isFalse);
      expect(spec.isRequired('price'), isTrue);
      expect(spec.isRequired('area'), isTrue);
      expect(spec.isRequired('bedrooms'), isFalse);
    });

    test('splits the area label into name and unit', () {
      expect(SpecRuleSet.fromJson(plotSpec()).areaName, 'Plot Area');
      expect(SpecRuleSet.fromJson(plotSpec()).areaUnit, 'sq.ft');

      final acres = SpecRuleSet.fromJson({
        ...plotSpec(),
        'area_label': 'Land Area (acres)',
      });
      expect(acres.areaName, 'Land Area');
      expect(acres.areaUnit, 'acres');
    });

    test('degrades to showing every field when the catalog is unavailable', () {
      final spec = SpecRuleSet.fromJson(null);

      expect(spec.visible, isEmpty);
      for (final f in [
        'price',
        'area',
        'bedrooms',
        'bathrooms',
        'floors',
        'parking',
        'furnishing',
        'possession_date',
      ]) {
        expect(spec.shows(f), isTrue, reason: '$f should stay visible');
      }
    });

    test('tolerates a malformed payload', () {
      final spec = SpecRuleSet.fromJson({'visible': 'nope'});

      expect(spec.visible, isEmpty);
      expect(spec.areaLabel, 'Area (sq.ft)');
      expect(spec.defaults, isEmpty);
    });
  });

  group('PropertyTypeMeta', () {
    test('parses a catalog entry', () {
      final meta = PropertyTypeMeta.fromJson({
        'name': 'Plot',
        'slug': 'plot',
        'description': 'Land parcel',
        'amenities': ['Corner Plot', 'Gated Township'],
        'spec': plotSpec(),
      });

      expect(meta.name, 'Plot');
      expect(meta.slug, 'plot');
      expect(meta.amenities, ['Corner Plot', 'Gated Township']);
      expect(meta.spec.areaName, 'Plot Area');
    });

    test('falls back to a neutral spec when spec is missing', () {
      final meta = PropertyTypeMeta.fromJson({
        'name': 'Other',
        'slug': 'other',
        'amenities': <String>[],
      });

      expect(meta.spec.visible, isEmpty);
      expect(meta.spec.shows('bedrooms'), isTrue);
    });
  });

  group('PropertyTypeOptions', () {
    test('parses the single-type payload from the show endpoint', () {
      final opts = PropertyTypeOptions.fromJson({
        'amenities': ['Corner Plot'],
        'spec': plotSpec(),
      });

      expect(opts.amenities, ['Corner Plot']);
      expect(opts.spec.hides('bedrooms'), isTrue);
    });

    test('tolerates a missing payload', () {
      final opts = PropertyTypeOptions.fromJson(null);

      expect(opts.amenities, isEmpty);
      expect(opts.spec.visible, isEmpty);
    });
  });

  group('type-switch pruning', () {
    // Mirrors _onTypeChanged: only entries from the previous type's catalog are
    // dropped, so custom amenities always survive a type change.
    List<String> prune({
      required List<String> selected,
      required List<String> previousCatalog,
      required List<String> nextCatalog,
    }) =>
        selected
            .where((a) => previousCatalog.contains(a))
            .where((a) => !nextCatalog.contains(a))
            .toList();

    test('drops catalog amenities that are invalid for the new type', () {
      final pruned = prune(
        selected: ['Corner Plot', 'Lift', 'Own Solar Panel'],
        previousCatalog: ['Corner Plot', 'Gated Township', 'Lift'],
        nextCatalog: ['Own Solar Panel', 'Fertile Soil'],
      );

      expect(pruned, ['Corner Plot', 'Lift']);
    });

    test('keeps custom amenities across a type change', () {
      final selected = ['Own Solar Panel', 'Corner Plot'];

      final removed = prune(
        selected: selected,
        previousCatalog: ['Corner Plot', 'Gated Township'],
        nextCatalog: ['Fertile Soil'],
      );

      final kept = selected.where((a) => !removed.contains(a)).toList();
      expect(kept, contains('Own Solar Panel'));
      expect(kept, isNot(contains('Corner Plot')));
    });

    test('prunes nothing when switching between compatible types', () {
      final pruned = prune(
        selected: ['Parking', 'Lift'],
        previousCatalog: ['Parking', 'Lift', 'Gym'],
        nextCatalog: ['Parking', 'Lift', 'Power Backup'],
      );

      expect(pruned, isEmpty);
    });
  });
}