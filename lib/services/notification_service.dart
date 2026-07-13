import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'loan_reminders',
      'Lembretes de empréstimos',
      channelDescription: 'Avisos sobre devolução de livros',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  static Future<void> initialize() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await _plugin.initialize(settings: settings);

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  static Future<void> scheduleLoanReminders({
    required int loanId,
    required String bookTitle,
    required DateTime dueDate,
  }) async {
    final dueAt = tz.TZDateTime(
      tz.local,
      dueDate.year,
      dueDate.month,
      dueDate.day,
      9,
    );

    final oneDayBefore = dueAt.subtract(const Duration(days: 1));

    if (oneDayBefore.isAfter(tz.TZDateTime.now(tz.local))) {
      await _schedule(
        id: loanId * 10,
        scheduledAt: oneDayBefore,
        title: 'Devolução amanhã',
        body: 'O livro “$bookTitle” deve ser devolvido amanhã.',
      );
    }

    if (dueAt.isAfter(tz.TZDateTime.now(tz.local))) {
      await _schedule(
        id: loanId * 10 + 1,
        scheduledAt: dueAt,
        title: 'Prazo de devolução',
        body: 'Hoje é o prazo para devolver “$bookTitle”.',
      );
    }
  }

  static Future<void> _schedule({
    required int id,
    required tz.TZDateTime scheduledAt,
    required String title,
    required String body,
  }) {
    return _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledAt,
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  static Future<void> cancelLoanReminders(int loanId) async {
    await _plugin.cancel(id: loanId * 10);
    await _plugin.cancel(id: loanId * 10 + 1);
  }
}
