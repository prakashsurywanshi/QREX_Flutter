import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'projects_controller.dart';

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(projectsListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Projects & Inventory')),
      body: async.when(
        data: (projects) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: projects.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final p = projects[i];
            return Card(
              child: ListTile(
                title: Text(p.name ?? 'Project'),
                subtitle: Text(p.location ?? '-'),
                trailing: Text('${p.unitsCount ?? 0} units'),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}
