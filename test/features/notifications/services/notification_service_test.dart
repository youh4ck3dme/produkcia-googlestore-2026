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

    when(mockPlugin.initialize(
      settings: anyNamed('settings'),
      onDidReceiveNotificationResponse:
          anyNamed('onDidReceiveNotificationResponse'),
    )).thenAnswer((_) async => true);
  });

  test('init should initialize the plugin and timezones', () async {
    await service.init();

    verify(mockPlugin.initialize(
      settings: anyNamed('settings'),
      onDidReceiveNotificationResponse:
          anyNamed('onDidReceiveNotificationResponse'),
    )).called(1);
  });

  test('showNotification should call plugin show', () async {
    when(mockPlugin.show(
      id: anyNamed('id'),
      title: anyNamed('title'),
      body: anyNamed('body'),
      notificationDetails: anyNamed('notificationDetails'),
      payload: anyNamed('payload'),
    )).thenAnswer((_) async => {});

    await service.showNotification(
      id: 1,
      title: 'Test',
      body: 'Body',
      payload: 'payload',
    );

    verify(mockPlugin.show(
      id: 1,
      title: 'Test',
      body: 'Body',
      notificationDetails: anyNamed('notificationDetails'),
      payload: 'payload',
    )).called(1);
  });
}
