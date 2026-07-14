import 'loans_service.dart';
import 'session_service.dart';

class NotificationService {
  static Future<List<Map<String, dynamic>>> listReminders() async {
    final userId = await SessionService.getCurrentUserId();

    // Busca todos os empréstimos do usuário local.
    final loans = await LoansService.listLoans(userId: userId);

    final reminders = <Map<String, dynamic>>[];

    for (final loan in loans) {
      final book = loan['book'] as Map<String, dynamic>?;
      final friend = loan['friend'] as Map<String, dynamic>?;

      final bookTitle = book?['title']?.toString() ?? 'Livro sem título';
      final friendName = friend?['name']?.toString() ?? 'amigo não informado';
      final status = loan['status']?.toString() ?? 'PENDING';
      final dueDate = DateTime.tryParse(loan['dueDate']?.toString() ?? '');

      if (status == 'RETURNED') {
        reminders.add({
          'type': 'AVAILABLE',
          'title': 'Livro disponível novamente',
          'message': 'O livro “$bookTitle” já foi devolvido e pode ser emprestado novamente.',
          'icon': 'available',
          'createdAt': loan['returnedDate'] ?? loan['updatedAt'] ?? loan['createdAt'],
        });

        continue;
      }

      if (dueDate == null) {
        continue;
      }

      final today = DateTime.now();
      final todayOnly = DateTime(today.year, today.month, today.day);
      final dueOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);
      final days = dueOnly.difference(todayOnly).inDays;

      if (days < 0) {
        reminders.add({
          'type': 'LATE',
          'title': 'Prazo vencido',
          'message': 'O livro “$bookTitle”, emprestado para $friendName, está atrasado há ${days.abs()} dia(s).',
          'icon': 'late',
          'createdAt': loan['dueDate'],
        });
      } else if (days == 0) {
        reminders.add({
          'type': 'TODAY',
          'title': 'Devolução hoje',
          'message': 'O livro “$bookTitle”, emprestado para $friendName, vence hoje.',
          'icon': 'today',
          'createdAt': loan['dueDate'],
        });
      } else if (days <= 2) {
        reminders.add({
          'type': 'SOON',
          'title': 'Prazo próximo',
          'message': 'O livro “$bookTitle”, emprestado para $friendName, vence em $days dia(s).',
          'icon': 'soon',
          'createdAt': loan['dueDate'],
        });
      }
    }

    // Ordena deixando atrasados e vencimentos próximos mais acima.
    reminders.sort((a, b) {
      final priorityA = getPriority(a['type']?.toString());
      final priorityB = getPriority(b['type']?.toString());

      if (priorityA != priorityB) {
        return priorityA.compareTo(priorityB);
      }

      final dateA = DateTime.tryParse(a['createdAt']?.toString() ?? '');
      final dateB = DateTime.tryParse(b['createdAt']?.toString() ?? '');

      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;

      return dateB.compareTo(dateA);
    });

    return reminders;
  }

  static int getPriority(String? type) {
    switch (type) {
      case 'LATE':
        return 0;
      case 'TODAY':
        return 1;
      case 'SOON':
        return 2;
      case 'AVAILABLE':
        return 3;
      default:
        return 4;
    }
  }

  static int getUnreadCount(List<Map<String, dynamic>> reminders) {
    return reminders.length;
  }
}