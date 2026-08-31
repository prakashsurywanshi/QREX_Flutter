// ignore_for_file: use_build_context_synchronously

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../widgets/form_fields.dart';
import 'media_controller.dart';

class MediaUploadSheet extends ConsumerStatefulWidget {
  final List<String> folders;
  final VoidCallback onUploaded;

  const MediaUploadSheet(
      {super.key, required this.folders, required this.onUploaded});

  @override
  ConsumerState<MediaUploadSheet> createState() => _MediaUploadSheetState();
}

class _MediaUploadSheetState extends ConsumerState<MediaUploadSheet> {
  final _name = TextEditingController();
  final _property = TextEditingController();
  String? _folder;
  PlatformFile? _file;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _folder = widget.folders.isEmpty ? null : widget.folders.first;
  }

  @override
  void dispose() {
    _name.dispose();
    _property.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null && result.files.isNotEmpty) {
      final f = result.files.first;
      if (f.path == null) {
        _toast('Unsupported file source.');
        return;
      }
      setState(() {
        _file = f;
        if (_name.text.trim().isEmpty) {
          _name.text = f.name;
        }
      });
    }
  }

  void _toast(String message, {bool isError = false}) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.inverseSurface,
        behavior: SnackBarBehavior.floating,
      ));
  }

  Future<void> _upload() async {
    final name = _name.text.trim();
    if (_file == null || name.isEmpty || _folder == null) {
      _toast('Pick a file, name, and folder.', isError: true);
      return;
    }
    if (_file!.size > 51200 * 1024) {
      _toast('File exceeds the 50 MB limit.', isError: true);
      return;
    }
    setState(() => _uploading = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref
          .read(mediaControllerProvider.notifier)
          .uploadFile(
            filePath: _file!.path!,
            fileName: _file!.name,
            name: name,
            folder: _folder!,
            propertyName: _property.text.trim(),
          );
      widget.onUploaded();
      messenger
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(
          content: Text('File uploaded.'),
          behavior: SnackBarBehavior.floating,
        ));
      if (mounted) navigator.pop();
    } catch (e) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Upload File', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          InkWell(
            onTap: _uploading ? null : _pickFile,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                border: Border.all(color: theme.colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    _file == null ? Icons.cloud_upload_outlined : Icons.check,
                    color: theme.colorScheme.primary,
                    size: 34,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _file?.name ?? 'Tap to choose a file',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _file == null
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_file != null)
                    Text(
                      '${(_file!.size / (1024 * 1024)).toStringAsFixed(2)} MB',
                      style: theme.textTheme.labelSmall,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'File Name *',
            controller: _name,
            icon: Icons.label_outline,
          ),
          AppTextField(
            label: 'Property Name (optional)',
            controller: _property,
            icon: Icons.apartment,
          ),
          AppDropdownField<String>(
            label: 'Folder',
            value: _folder,
            options: [for (final f in widget.folders) (f, f)],
            onChanged: (v) => setState(() => _folder = v),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _uploading ? null : _upload,
            icon: _uploading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.upload_file),
            label: Text(_uploading ? 'Uploading…' : 'Upload'),
          ),
        ],
      ),
    );
  }
}