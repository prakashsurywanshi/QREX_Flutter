import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/media_file.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../widgets/empty_state.dart';
import 'media_controller.dart';
import 'media_upload_sheet.dart';

class MediaScreen extends ConsumerStatefulWidget {
  const MediaScreen({super.key});

  @override
  ConsumerState<MediaScreen> createState() => _MediaScreenState();
}

class _MediaScreenState extends ConsumerState<MediaScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = ref.read(mediaControllerProvider.notifier);
      if (ref.read(mediaControllerProvider).files.isEmpty) c.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mediaControllerProvider);
    final controller = ref.read(mediaControllerProvider.notifier);
    final can = ref.watch(currentUserProvider)?.can;
    final canCreate = can?.canCreate('media') == true;
    final canDelete = can?.canDelete('media') == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Media Center'),
        actions: [
          IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh),
              onPressed: controller.load),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => _openUpload(context),
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              children: [
                Icon(Icons.storage,
                    size: 16, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '${state.storageUsed} MB storage used',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(width: 8),
                Text('·',
                    style: TextStyle(color: Theme.of(context).colorScheme.outline)),
                const SizedBox(width: 8),
                Text(
                  '${state.storageEntries} files total',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                for (final f in ['All', ...state.folders])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f),
                      selected: state.folderFilter == f,
                      onSelected: (_) => controller.filterFolder(f),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(child: _buildGrid(context, state, controller, canDelete)),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context, MediaState state,
      MediaController controller, bool canDelete) {
    if (state.loading && state.files.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.files.isEmpty) {
      return EmptyState(
        icon: Icons.cloud_off,
        message: state.error!,
        action: FilledButton(
            onPressed: controller.load, child: const Text('Retry')),
      );
    }
    if (state.filtered.isEmpty) {
      return const EmptyState(
        icon: Icons.photo_library_outlined,
        message: 'No files in this folder',
        hint: 'Upload files to get started.',
      );
    }

    return RefreshIndicator(
      onRefresh: controller.load,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 96),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.95,
        ),
        itemCount: state.filtered.length,
        itemBuilder: (ctx, i) {
          final f = state.filtered[i];
          return _MediaTile(
            file: f,
            canDelete: canDelete,
            onDelete: () async {
              final ok = await _confirmDelete(context, f);
              if (ok == true) controller.deleteFile(f.id);
            },
          );
        },
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, MediaFile f) async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete File?'),
        content: Text('Delete "${f.name}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _openUpload(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => MediaUploadSheet(
        folders: ref.read(mediaControllerProvider).folders,
        onUploaded: () => ref.read(mediaControllerProvider.notifier).load(),
      ),
    );
  }
}

class _MediaTile extends StatelessWidget {
  final MediaFile file;
  final bool canDelete;
  final VoidCallback onDelete;
  const _MediaTile(
      {required this.file, required this.canDelete, required this.onDelete});

  IconData get _icon {
    switch (file.type) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'video':
        return Icons.videocam;
      case 'audio':
        return Icons.audiotrack;
      case 'image':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 84,
            width: double.infinity,
            child: file.type == 'image' && file.url != null
                ? CachedNetworkImage(
                    imageUrl: file.url!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _TypeTile(icon: _icon),
                  )
                : _TypeTile(icon: _icon),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        file.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (canDelete)
                      InkWell(
                        onTap: onDelete,
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: Icon(Icons.delete_outline,
                              size: 16, color: theme.colorScheme.outline),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${file.size ?? '—'} · ${file.uploadedBy ?? '—'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    file.folder,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeTile extends StatelessWidget {
  final IconData icon;
  const _TypeTile({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: Icon(icon, size: 28, color: Theme.of(context).colorScheme.outline),
    );
  }
}