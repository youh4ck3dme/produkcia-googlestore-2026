import 'package:bizagent/features/notifications/services/notification_service.dart';

class FakeNotificationService implements NotificationService {
  @override
  Future<void> init() async {}

  @override
  Future<bool?> requestPermissions() async => false;

  @override
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {}

  @override
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {}
}
