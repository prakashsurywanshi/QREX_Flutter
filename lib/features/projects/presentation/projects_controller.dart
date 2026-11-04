import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/project.dart';
import '../../../core/providers/auth_providers.dart';
import '../data/projects_repository.dart';

final projectsRepositoryProvider = Provider((ref) => ProjectsRepository(ref.watch(apiClientProvider)));
final projectsListProvider = FutureProvider.autoDispose<List<Project>>((ref) async {
  return ref.watch(projectsRepositoryProvider).list();
});
