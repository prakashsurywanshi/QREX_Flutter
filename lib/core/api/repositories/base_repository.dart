import '../api_client.dart';

abstract class BaseRepository {
  BaseRepository(this.apiClient);
  final ApiClient apiClient;
}
