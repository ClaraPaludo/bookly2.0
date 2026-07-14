import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../services/notification_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool isLoading = true;
  String? errorMessage;

  List<Map<String, dynamic>> reminders = [];

  @override
  void initState() {
    super.initState();
    loadReminders();
  }

  Future<void> loadReminders() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final loadedReminders = await NotificationService.listReminders();

      if (!mounted) return;

      setState(() {
        reminders = loadedReminders;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString();
        isLoading = false;
      });
    }
  }

  Color getReminderColor(String? type) {
    switch (type) {
      case 'LATE':
        return Colors.red;
      case 'TODAY':
        return Colors.orange;
      case 'SOON':
        return Colors.blue;
      case 'AVAILABLE':
        return Colors.green;
      default:
        return AppColors.primary;
    }
  }

  IconData getReminderIcon(String? type) {
    switch (type) {
      case 'LATE':
        return Icons.warning_amber_rounded;
      case 'TODAY':
        return Icons.today_outlined;
      case 'SOON':
        return Icons.schedule;
      case 'AVAILABLE':
        return Icons.check_circle_outline;
      default:
        return Icons.notifications_none_outlined;
    }
  }

  String formatDate(String? value) {
    final date = DateTime.tryParse(value ?? '');

    if (date == null) return '';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Lembretes'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: loadReminders,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: isLoading
              ? const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(child: CircularProgressIndicator()),
                )
              : errorMessage != null
                  ? buildErrorState()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildHeader(),
                        const SizedBox(height: 18),
                        if (reminders.isEmpty)
                          const _EmptyReminderCard()
                        else
                          buildReminderList(),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Icon(
              Icons.notifications_none_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              reminders.length == 1
                  ? 'Você tem 1 lembrete importante.'
                  : 'Você tem ${reminders.length} lembretes importantes.',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildReminderList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: reminders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final reminder = reminders[index];

        final type = reminder['type']?.toString();
        final title = reminder['title']?.toString() ?? 'Lembrete';
        final message = reminder['message']?.toString() ?? '';
        final createdAt = formatDate(reminder['createdAt']?.toString());

        final color = getReminderColor(type);

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.20)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.14),
                child: Icon(
                  getReminderIcon(type),
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: TextStyle(
                        color: Colors.grey[800],
                        height: 1.3,
                      ),
                    ),
                    if (createdAt.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        createdAt,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildErrorState() {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: _InfoCard(
        icon: Icons.error_outline,
        title: 'Erro ao carregar lembretes',
        description:
            'Não foi possível carregar os lembretes locais.\n\n$errorMessage',
      ),
    );
  }
}

class _EmptyReminderCard extends StatelessWidget {
  const _EmptyReminderCard();

  @override
  Widget build(BuildContext context) {
    return const _InfoCard(
      icon: Icons.notifications_none_outlined,
      title: 'Nenhum lembrete no momento',
      description:
          'Quando um livro estiver próximo do prazo, atrasado ou disponível novamente, o aviso aparecerá aqui.',
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, size: 44, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}