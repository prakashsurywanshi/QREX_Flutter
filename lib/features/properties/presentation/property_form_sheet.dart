// ignore_for_file: use_build_context_synchronously
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/models/property.dart';
import '../../../core/models/property_image.dart';
import '../../../core/models/property_type.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/form_fields.dart';
import 'properties_controller.dart';

const int _maxImages = 15;

class _CoverSelection {
  final int? existingId;
  final int? pickedIndex;

  const _CoverSelection({this.existingId, this.pickedIndex});

  bool get isExisting => existingId != null;
  bool get isPicked => pickedIndex != null;
}

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
  final _customAmenity = TextEditingController();
  List<String> _amenities = [];
  /// Catalog amenities valid for the type selected when this sheet opened, used
  /// to tell catalog entries apart from custom ones when the type changes.
  List<String> _catalogForCurrentType = [];
  List<String> _removedOnTypeChange = [];
  bool _featured = false;
  bool _visible = true;
  bool _saving = false;
  List<XFile> _pickedImages = [];
  List<PropertyImage> _existingImages = [];
  _CoverSelection? _cover;

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _title = TextEditingController(text: p?.title ?? '');
    _price = TextEditingController(
      text: p == null || p.price == 0 ? '' : p.price.toString(),
    );
    _area = TextEditingController(
      text: p == null || p.area == 0 ? '' : p.area.toString(),
    );
    _bedrooms = TextEditingController(
      text: (p?.bedrooms ?? 0) == 0 ? '' : '${p!.bedrooms}',
    );
    _bathrooms = TextEditingController(
      text: (p?.bathrooms ?? 0) == 0 ? '' : '${p!.bathrooms}',
    );
    _floors = TextEditingController(
      text: (p?.floors ?? 0) == 0 ? '' : '${p!.floors}',
    );
    _parking = TextEditingController(
      text: (p?.parking ?? 0) == 0 ? '' : '${p!.parking}',
    );
    _furnishing = TextEditingController(text: p?.furnishing ?? '');
    _possession = TextEditingController(
      text: p?.possessionDate == null || p!.possessionDate!.isEmpty
          ? ''
          : Formatters.date(p.possessionDate),
    );
    _address = TextEditingController(text: p?.address ?? '');
    _city = TextEditingController(text: p?.city ?? '');
    _state = TextEditingController(text: p?.state ?? '');
    _pincode = TextEditingController(text: p?.pincode ?? '');
    _description = TextEditingController(text: p?.description ?? '');
    _type = p?.type.isNotEmpty == true ? p!.type : null;
    _transaction = p?.transactionType.isNotEmpty == true
        ? p!.transactionType
        : null;
    _status = p?.status.isNotEmpty == true ? p!.status : null;
    _amenities = [...?p?.amenities];
    _featured = p?.featured ?? false;
    _visible = p?.isWebsiteVisible ?? true;
    _existingImages = [...?p?.images];
    final cover = p?.images.where((i) => i.isCover).firstOrNull;
    if (cover != null) _cover = _CoverSelection(existingId: cover.id);
  }

  @override
  void dispose() {
    for (final c in [
      _title,
      _price,
      _area,
      _bedrooms,
      _bathrooms,
      _floors,
      _parking,
      _furnishing,
      _possession,
      _address,
      _city,
      _state,
      _pincode,
      _description,
    ]) {
      c.dispose();
    }
    _customAmenity.dispose();
    super.dispose();
  }

  int get _totalImages => _existingImages.length + _pickedImages.length;

  List<String> _catalogFor(String? type) {
    final meta = ref
        .read(propertiesControllerProvider.notifier)
        .metaFor(type);
    return meta?.amenities ?? const [];
  }

  SpecRuleSet _specFor(String? type) {
    final meta = ref
        .read(propertiesControllerProvider.notifier)
        .metaFor(type);
    return meta?.spec ?? const SpecRuleSet();
  }

  void _toggleAmenity(String name) {
    setState(() {
      _amenities = _amenities.contains(name)
          ? _amenities.where((a) => a != name).toList()
          : [..._amenities, name];
    });
  }

  void _addCustomAmenity() {
    final name = _customAmenity.text.trim();
    if (name.isEmpty) return;
    if (_amenities.any((a) => a.toLowerCase() == name.toLowerCase())) {
      _customAmenity.clear();
      return;
    }
    setState(() => _amenities = [..._amenities, name]);
    _customAmenity.clear();
  }

  void _removeAmenity(String name) {
    setState(() => _amenities = _amenities.where((a) => a != name).toList());
  }

  /// Amenities that belong to the catalog but are invalid for [nextType] get
  /// dropped. Custom (off-catalog) entries are always preserved.
  void _onTypeChanged(String? nextType) {
    final nextCatalog = _catalogFor(nextType);
    final spec = _specFor(nextType);

    final pruned = _amenities
        .where((a) => _catalogForCurrentType.contains(a))
        .where((a) => !nextCatalog.contains(a))
        .toList();

    setState(() {
      _type = nextType;
      _catalogForCurrentType = nextCatalog;
      _removedOnTypeChange = pruned;
      if (pruned.isNotEmpty) {
        _amenities = _amenities.where((a) => !pruned.contains(a)).toList();
      }
      // Reset numeric specs this type does not use.
      if (!spec.shows('bedrooms')) _bedrooms.clear();
      if (!spec.shows('bathrooms')) _bathrooms.clear();
      if (!spec.shows('floors')) _floors.clear();
      if (!spec.shows('parking')) _parking.clear();
    });
  }

  Future<void> _addImages() async {
    final remaining = _maxImages - _totalImages;
    if (remaining <= 0) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('Maximum 15 images allowed.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take photo'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    final picker = ImagePicker();
    final picked = <XFile>[];
    if (source == ImageSource.camera) {
      final f = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (f != null) picked.add(f);
    } else {
      picked.addAll(
        await picker.pickMultiImage(
          maxWidth: 1920,
          maxHeight: 1920,
          imageQuality: 85,
        ),
      );
    }
    if (picked.isEmpty || !mounted) return;

    setState(() {
      _pickedImages = [..._pickedImages, ...picked.take(remaining)];
    });
  }

  void _removeExisting(int index) {
    if (_cover?.existingId == _existingImages[index].id) _cover = null;
    setState(() => _existingImages.removeAt(index));
  }

  void _removePicked(int index) {
    if (_cover?.pickedIndex == index) _cover = null;
    setState(() => _pickedImages.removeAt(index));
  }

  void _selectCover({int? existingId, int? pickedIndex}) {
    setState(
      () => _cover = _CoverSelection(
        existingId: existingId,
        pickedIndex: pickedIndex,
      ),
    );
  }

  /// Catalog chips for the selected type, a free-text field for anything else,
  /// and the selected set rendered with per-chip remove buttons.
  Widget _amenitiesSection(List<String> catalog) {
    final theme = Theme.of(context);
    final custom = _amenities
        .where((a) => !catalog.contains(a))
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text('Amenities', style: theme.textTheme.titleSmall),
        const SizedBox(height: 6),
        if (_removedOnTypeChange.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 16,
                  color: theme.colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Removed for this type: ${_removedOnTypeChange.join(', ')}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close, size: 14),
                  onPressed: () => setState(() => _removedOnTypeChange = []),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (_amenities.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final a in _amenities)
                InputChip(
                  label: Text(a),
                  labelStyle: theme.textTheme.labelSmall,
                  visualDensity: VisualDensity.compact,
                  onDeleted: () => _removeAmenity(a),
                  deleteIcon: const Icon(Icons.close, size: 14),
                ),
            ],
          ),
        if (_amenities.isNotEmpty) const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: 'Other amenity',
                controller: _customAmenity,
                hint: 'Add your own',
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _addCustomAmenity(),
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 22),
              child: OutlinedButton.icon(
                onPressed: _addCustomAmenity,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add'),
              ),
            ),
          ],
        ),
        if (catalog.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final a in catalog)
                FilterChip(
                  label: Text(a),
                  labelStyle: theme.textTheme.labelSmall,
                  visualDensity: VisualDensity.compact,
                  selected: _amenities.contains(a),
                  onSelected: (_) => _toggleAmenity(a),
                ),
            ],
          ),
        ],
        if (custom.isEmpty && catalog.isEmpty && _amenities.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'No amenity catalog available — add amenities manually.',
              style: theme.textTheme.bodySmall,
            ),
          ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final isEdit = widget.initial != null;
    final controller = ref.read(propertiesControllerProvider.notifier);

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
      'furnishing': _furnishing.text.trim().isEmpty
          ? null
          : _furnishing.text.trim(),
      'possession_date': _possession.text.trim().isEmpty
          ? null
          : _possession.text.trim(),
      'address': _address.text.trim().isEmpty ? null : _address.text.trim(),
      'city': _city.text.trim().isEmpty ? null : _city.text.trim(),
      'state': _state.text.trim().isEmpty ? null : _state.text.trim(),
      'pincode': _pincode.text.trim().isEmpty ? null : _pincode.text.trim(),
      'description': _description.text.trim().isEmpty
          ? null
          : _description.text.trim(),
      'amenities': _amenities,
      'featured': _featured,
      'is_website_visible': _visible,
    };

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (isEdit) {
        final originals = widget.initial!.images;
        for (final img in originals) {
          if (!_existingImages.any((e) => e.id == img.id)) {
            await controller.deletePropertyImage(widget.initial!.id, img.id);
          }
        }
      }

      final saved = isEdit
          ? await controller.updateProperty(widget.initial!.id, payload)
          : await controller.createProperty(payload);

      final uploaded = await controller.uploadPropertyImagesWithReturn(
        saved.id,
        _pickedImages.map((f) => f.path).toList(),
      );

      if (_cover != null) {
        final cover = _cover!;
        final int? targetId;
        if (cover.isExisting) {
          targetId = cover.existingId;
        } else {
          final idx = cover.pickedIndex;
          targetId = (idx != null && idx < uploaded.length)
              ? uploaded[idx].id
              : null;
        }
        if (targetId != null) {
          await controller.setCoverImage(saved.id, targetId);
        }
      }

      controller.refresh();
      widget.onSaved();
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Property updated.' : 'Property created.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      Navigator.of(context).pop();
    } catch (e) {
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lookups = ref.read(propertiesControllerProvider.notifier).lookups;
    final statuses = [
      if (lookups.statuses.isEmpty) 'Available',
      ...lookups.statuses,
    ];
    final spec = _specFor(_type);
    final catalogAmenities = _catalogFor(_type);
    // Seed the "previous catalog" on first build so type switches can tell
    // catalog entries apart from custom ones.
    if (_catalogForCurrentType.isEmpty && catalogAmenities.isNotEmpty) {
      _catalogForCurrentType = catalogAmenities;
    }

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
              Text(
                widget.initial!.propertyId,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 16),
            _ImageGridPicker(
              existing: _existingImages,
              picked: _pickedImages,
              maxCount: _maxImages,
              cover: _cover,
              enabled: !_saving,
              onAdd: _addImages,
              onRemoveExisting: _removeExisting,
              onRemovePicked: _removePicked,
              onSetCoverExisting: (id) => _selectCover(existingId: id),
              onSetCoverPicked: (index) => _selectCover(pickedIndex: index),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Title *',
              controller: _title,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Title is required' : null,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField(
                  label: 'Price (₹) *',
                  controller: _price,
                  keyboardType: TextInputType.number,
                  validator: (v) => num.tryParse((v ?? '').trim()) == null
                      ? 'Enter a valid amount'
                      : null,
                ),
                AmountInWordsHint(controller: _price),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: '${spec.areaLabel} *',
                    controller: _area,
                    keyboardType: TextInputType.number,
                    validator: (v) => num.tryParse((v ?? '').trim()) == null
                        ? 'Enter area'
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppDropdownField<String>(
                    label: 'Type *',
                    value: _type,
                    options: [for (final t in lookups.types) (t, t)],
                    onChanged: _onTypeChanged,
                  ),
                ),
              ],
            ),
            AppDropdownField<String>(
              label: 'Transaction',
              value: _transaction,
              options: const [
                ('Buy', 'Buy'),
                ('Rent', 'Rent'),
                ('Lease', 'Lease'),
              ],
              onChanged: (v) => setState(() => _transaction = v),
            ),
            AppDropdownField<String>(
              label: 'Status *',
              value: _status,
              options: [for (final s in statuses) (s, s)],
              onChanged: (v) => setState(() => _status = v),
            ),
            if (spec.shows('bedrooms') || spec.shows('bathrooms'))
              Row(
                children: [
                  if (spec.shows('bedrooms')) ...[
                    Expanded(
                      child: AppTextField(
                        label: 'BHK',
                        controller: _bedrooms,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  if (spec.shows('bathrooms'))
                    Expanded(
                      child: AppTextField(
                        label: 'Bathrooms',
                        controller: _bathrooms,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                ],
              ),
            if (spec.shows('floors') || spec.shows('parking'))
              Row(
                children: [
                  if (spec.shows('floors')) ...[
                    Expanded(
                      child: AppTextField(
                        label: 'Floors',
                        controller: _floors,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  if (spec.shows('parking'))
                    Expanded(
                      child: AppTextField(
                        label: 'Parking',
                        controller: _parking,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                ],
              ),
            if (spec.shows('furnishing'))
              AppTextField(label: 'Furnishing', controller: _furnishing),
            if (spec.shows('possession_date'))
              AppTextField(
                label: 'Possession date',
                controller: _possession,
                hint: 'e.g. Dec 2026',
              ),
            _amenitiesSection(catalogAmenities),
            AppTextField(label: 'Address', controller: _address),
            Row(
              children: [
                Expanded(
                  child: AppTextField(label: 'City', controller: _city),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppTextField(label: 'State', controller: _state),
                ),
              ],
            ),
            AppTextField(
              label: 'Pincode',
              controller: _pincode,
              keyboardType: TextInputType.number,
            ),
            AppTextField(
              label: 'Description',
              controller: _description,
              multiline: true,
            ),
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
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageGridPicker extends StatelessWidget {
  final List<PropertyImage> existing;
  final List<XFile> picked;
  final int maxCount;
  final _CoverSelection? cover;
  final bool enabled;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemoveExisting;
  final ValueChanged<int> onRemovePicked;
  final ValueChanged<int> onSetCoverExisting;
  final ValueChanged<int> onSetCoverPicked;

  const _ImageGridPicker({
    required this.existing,
    required this.picked,
    required this.maxCount,
    required this.cover,
    required this.enabled,
    required this.onAdd,
    required this.onRemoveExisting,
    required this.onRemovePicked,
    required this.onSetCoverExisting,
    required this.onSetCoverPicked,
  });

  @override
  Widget build(BuildContext context) {
    final total = existing.length + picked.length;
    final canAdd = total < maxCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Photos', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            Text(
              '$total/$maxCount',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: total + (canAdd ? 1 : 0),
          itemBuilder: (context, index) {
            if (index < existing.length) {
              final img = existing[index];
              return _ImageTile(
                isCover: cover?.existingId == img.id,
                enabled: enabled,
                onRemove: enabled ? () => onRemoveExisting(index) : null,
                onSetCover: enabled ? () => onSetCoverExisting(img.id) : null,
                child: Image.network(
                  img.path,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _errorPlaceholder(context),
                ),
              );
            }
            if (index < existing.length + picked.length) {
              final idx = index - existing.length;
              final file = picked[idx];
              return _ImageTile(
                isCover: cover?.pickedIndex == idx,
                enabled: enabled,
                onRemove: enabled ? () => onRemovePicked(idx) : null,
                onSetCover: enabled ? () => onSetCoverPicked(idx) : null,
                child: Image.file(File(file.path), fit: BoxFit.cover),
              );
            }
            return _AddTile(enabled: enabled, onTap: onAdd);
          },
        ),
        const SizedBox(height: 6),
        Text(
          'Tap the star to set the cover photo.',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ],
    );
  }

  Widget _errorPlaceholder(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.image_not_supported,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _ImageTile extends StatelessWidget {
  final bool isCover;
  final bool enabled;
  final Widget child;
  final VoidCallback? onRemove;
  final VoidCallback? onSetCover;

  const _ImageTile({
    required this.isCover,
    required this.enabled,
    required this.child,
    this.onRemove,
    this.onSetCover,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        fit: StackFit.expand,
        children: [
          child,
          if (isCover)
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, size: 12, color: Color(0xFFF9A825)),
                    SizedBox(width: 2),
                    Text(
                      'COVER',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (onSetCover != null)
            Positioned(
              top: 2,
              left: 2,
              child: IconButton(
                onPressed: onSetCover,
                visualDensity: VisualDensity.compact,
                iconSize: 18,
                tooltip: 'Set as cover',
                icon: const Icon(Icons.star_border, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.4),
                ),
              ),
            ),
          if (onRemove != null)
            Positioned(
              top: 2,
              right: 2,
              child: IconButton(
                onPressed: onRemove,
                visualDensity: VisualDensity.compact,
                iconSize: 18,
                tooltip: 'Remove',
                icon: const Icon(Icons.close, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.4),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _AddTile({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_a_photo_outlined,
              color: theme.colorScheme.primary,
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              'Add',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
