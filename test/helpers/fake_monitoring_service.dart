import 'package:bizagent/features/tools/services/monitoring_service.dart';

class FakeMonitoringService implements MonitoringService {
  @override
  void startListening(String uid) {}

  @override
  void stopListening() {}

  @override
  Stream<List<Map<String, dynamic>>> notifications() => Stream.value([]);

  @override
  Future<void> markAsRead(String id) async {}

  @override
  Future<void> markAllAsRead() async {}
}
