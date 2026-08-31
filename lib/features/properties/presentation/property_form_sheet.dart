// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/property.dart';
import '../../../widgets/form_fields.dart';
import 'properties_controller.dart';

class PropertyFormSheet extends ConsumerStatefulWidget {
  final Property? initial;
  final VoidCallback onSaved;

  const PropertyFormSheet({super.key, this.initial, required this.onSaved});

  @override
  ConsumerState<PropertyFormSheet> createState() => _PropertyFormSheetState();
}

class _PropertyFormSheetState extends ConsumerState<PropertyFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _price;
  late final TextEditingController _area;
  late final TextEditingController _bedrooms;
  late final TextEditingController _bathrooms;
  late final TextEditingController _floors;
  late final TextEditingController _parking;
  late final TextEditingController _furnishing;
  late final TextEditingController _possession;
  late final TextEditingController _address;
  late final TextEditingController _city;
  late final TextEditingController _state;
  late final TextEditingController _pincode;
  late final TextEditingController _description;
  String? _type;
  String? _transaction;
  String? _status;
  bool _featured = false;
  bool _visible = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _title = TextEditingController(text: p?.title ?? '');
    _price = TextEditingController(text: p == null || p.price == 0 ? '' : p.price.toString());
    _area = TextEditingController(text: p == null || p.area == 0 ? '' : p.area.toString());
    _bedrooms = TextEditingController(text: (p?.bedrooms ?? 0) == 0 ? '' : '${p!.bedrooms}');
    _bathrooms = TextEditingController(text: (p?.bathrooms ?? 0) == 0 ? '' : '${p!.bathrooms}');
    _floors = TextEditingController(text: (p?.floors ?? 0) == 0 ? '' : '${p!.floors}');
    _parking = TextEditingController(text: (p?.parking ?? 0) == 0 ? '' : '${p!.parking}');
    _furnishing = TextEditingController(text: p?.furnishing ?? '');
    _possession = TextEditingController(text: p?.possessionDate ?? '');
    _address = TextEditingController(text: p?.address ?? '');
    _city = TextEditingController(text: p?.city ?? '');
    _state = TextEditingController(text: p?.state ?? '');
    _pincode = TextEditingController(text: p?.pincode ?? '');
    _description = TextEditingController(text: p?.description ?? '');
    _type = p?.type.isNotEmpty == true ? p!.type : null;
    _transaction = p?.transactionType.isNotEmpty == true ? p!.transactionType : null;
    _status = p?.status.isNotEmpty == true ? p!.status : null;
    _featured = p?.featured ?? false;
    _visible = p?.isWebsiteVisible ?? true;
  }

  @override
  void dispose() {
    for (final c in [
      _title, _price, _area, _bedrooms, _bathrooms, _floors, _parking,
      _furnishing, _possession, _address, _city, _state, _pincode, _description,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final isEdit = widget.initial != null;

    final payload = <String, dynamic>{
      'title': _title.text.trim(),
      'type': _type ?? 'Apartment',
      'transaction_type': _transaction ?? 'Buy',
      'status': _status ?? 'Available',
      'price': num.tryParse(_price.text.trim()) ?? 0,
      'area': num.tryParse(_area.text.trim()) ?? 0,
      'bedrooms': int.tryParse(_bedrooms.text.trim()) ?? 0,
      'bathrooms': int.tryParse(_bathrooms.text.trim()) ?? 0,
      'floors': int.tryParse(_floors.text.trim()) ?? 1,
      'parking': int.tryParse(_parking.text.trim()) ?? 0,
      'furnishing': _furnishing.text.trim().isEmpty ? null : _furnishing.text.trim(),
      'possession_date': _possession.text.trim().isEmpty ? null : _possession.text.trim(),
      'address': _address.text.trim().isEmpty ? null : _address.text.trim(),
      'city': _city.text.trim().isEmpty ? null : _city.text.trim(),
      'state': _state.text.trim().isEmpty ? null : _state.text.trim(),
      'pincode': _pincode.text.trim().isEmpty ? null : _pincode.text.trim(),
      'description': _description.text.trim().isEmpty ? null : _description.text.trim(),
      'featured': _featured,
      'is_website_visible': _visible,
    };

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final controller = ref.read(propertiesControllerProvider.notifier);
    try {
      if (isEdit) {
        await controller.updateProperty(widget.initial!.id, payload);
      } else {
        await controller.createProperty(payload);
      }
      widget.onSaved();
      messenger..clearSnackBars()..showSnackBar(SnackBar(
          content: Text(isEdit ? 'Property updated.' : 'Property created.'),
          behavior: SnackBarBehavior.floating));
      Navigator.of(context).pop();
    } catch (e) {
      messenger.clearSnackBars();
      messenger.showSnackBar(SnackBar(
        content: Text(e.toString()),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lookups = ref
        .read(propertiesControllerProvider.notifier)
        .lookups;
    final statuses = [
      if (lookups.statuses.isEmpty) 'Available',
      ...lookups.statuses,
    ];

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.6,
      maxChildSize: 1.0,
      expand: false,
      builder: (ctx, scrollCtrl) => Form(
        key: _formKey,
        child: ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Text(
              widget.initial == null ? 'Add Property' : 'Edit Property',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (widget.initial != null)
              Text(widget.initial!.propertyId,
                  style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            AppTextField(
                label: 'Title *', controller: _title,
                validator: (v) => v == null || v.trim().isEmpty ? 'Title is required' : null),
            AppTextField(
                label: 'Price (₹) *', controller: _price,
                keyboardType: TextInputType.number,
                validator: (v) => num.tryParse((v ?? '').trim()) == null ? 'Enter a valid amount' : null),
            Row(
              children: [
                Expanded(
                    child: AppTextField(label: 'Area (sq.ft) *', controller: _area,
                        keyboardType: TextInputType.number,
                        validator: (v) => num.tryParse((v ?? '').trim()) == null ? 'Enter area' : null)),
                const SizedBox(width: 10),
                Expanded(child: AppDropdownField<String>(
                    label: 'Type *', value: _type,
                    options: [for (final t in lookups.types) (t, t)],
                    onChanged: (v) => setState(() => _type = v))),
              ],
            ),
            AppDropdownField<String>(
                label: 'Transaction', value: _transaction,
                options: const [
                  ('Buy', 'Buy'),
                  ('Rent', 'Rent'),
                  ('Lease', 'Lease'),
                ],
                onChanged: (v) => setState(() => _transaction = v)),
            AppDropdownField<String>(
                label: 'Status *', value: _status,
                options: [for (final s in statuses) (s, s)],
                onChanged: (v) => setState(() => _status = v)),
            Row(
              children: [
                Expanded(child: AppTextField(label: 'BHK', controller: _bedrooms, keyboardType: TextInputType.number)),
                const SizedBox(width: 10),
                Expanded(child: AppTextField(label: 'Bathrooms', controller: _bathrooms, keyboardType: TextInputType.number)),
              ],
            ),
            Row(
              children: [
                Expanded(child: AppTextField(label: 'Floors', controller: _floors, keyboardType: TextInputType.number)),
                const SizedBox(width: 10),
                Expanded(child: AppTextField(label: 'Parking', controller: _parking, keyboardType: TextInputType.number)),
              ],
            ),
            AppTextField(label: 'Furnishing', controller: _furnishing),
            AppTextField(label: 'Possession date', controller: _possession,
                hint: 'e.g. Dec 2026'),
            AppTextField(label: 'Address', controller: _address),
            Row(
              children: [
                Expanded(child: AppTextField(label: 'City', controller: _city)),
                const SizedBox(width: 10),
                Expanded(child: AppTextField(label: 'State', controller: _state)),
              ],
            ),
            AppTextField(label: 'Pincode', controller: _pincode,
                keyboardType: TextInputType.number),
            AppTextField(label: 'Description', controller: _description, multiline: true),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Featured'),
              value: _featured,
              onChanged: (v) => setState(() => _featured = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Visible on website'),
              value: _visible,
              onChanged: (v) => setState(() => _visible = v),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: _saving
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}