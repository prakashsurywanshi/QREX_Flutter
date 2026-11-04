import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';

class AuditRepository {
  AuditRepository(this.apiClient);
  final ApiClient apiClient;

  Future<List<dynamic>> getLogs() async {
    final res = await apiClient.get(ApiEndpoints.auditLogs);
    return res.data['data'] ?? [];
  }
}
