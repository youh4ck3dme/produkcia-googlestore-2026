import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:bizagent/features/notifications/services/notification_service.dart';
import 'notification_service_test.mocks.dart';

@GenerateMocks([FlutterLocalNotificationsPlugin])
void main() {
  late NotificationService service;
  late MockFlutterLocalNotificationsPlugin mockPlugin;

  setUp(() {
    mockPlugin = MockFlutterLocalNotificationsPlugin();
    service = NotificationService(plugin: mockPlugin);

    // Mock initialize
    when(mockPlugin.initialize(
      any,
      onDidReceiveNotificationResponse:
          anyNamed('onDidReceiveNotificationResponse'),
    )).thenAnswer((_) async => true);
  });

  test('init should initialize the plugin and timezones', () async {
    await service.init();

    verify(mockPlugin.initialize(
      any,
      onDidReceiveNotificationResponse:
          anyNamed('onDidReceiveNotificationResponse'),
    )).called(1);
  });

  test('showNotification should call plugin show', () async {
    when(mockPlugin.show(
      any,
      any,
      any,
      any,
      payload: anyNamed('payload'),
    )).thenAnswer((_) async => {});

    await service.showNotification(
      id: 1,
      title: 'Test',
      body: 'Body',
      payload: 'payload',
    );

    verify(mockPlugin.show(
      1,
      'Test',
      'Body',
      any,
      payload: 'payload',
    )).called(1);
  });
}
