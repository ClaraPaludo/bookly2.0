import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../services/books_service.dart';
import '../services/loans_service.dart';
import '../services/session_service.dart';
import '../widgets/app_bottom_navigation.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isLoading = true;
  String? errorMessage;

  Map<String, dynamic>? currentUser;
  List<Map<String, dynamic>> books = [];
  List<Map<String, dynamic>> loans = [];

  @override
  void initState() {
    super.initState();
    loadProfileData();
  }

  Future<void> loadProfileData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final user = await SessionService.getCurrentUser();
      final userId = user['id'].toString();

      final loadedBooks = await BooksService.listBooks(userId: userId);
      final loadedLoans = await LoansService.listLoans(userId: userId);

      if (!mounted) return;

      setState(() {
        currentUser = user;
        books = loadedBooks;
        loans = loadedLoans;
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

  int get totalBooks {
    return books.length;
  }

  int get totalPending {
    return loans.where((loan) => getVisualStatus(loan) == 'PENDING').length;
  }

  int get totalLate {
    return loans.where((loan) => getVisualStatus(loan) == 'LATE').length;
  }

  int get totalReturned {
    return loans.where((loan) => getVisualStatus(loan) == 'RETURNED').length;
  }

  String get userName {
    return currentUser?['name']?.toString() ?? 'Usuário Bookly';
  }

  String get userEmail {
    return currentUser?['email']?.toString() ?? 'usuario@bookly.com';
  }

  String get initials {
    final parts = userName.trim().split(' ');

    if (parts.isEmpty || userName.trim().isEmpty) {
      return '?';
    }

    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String getVisualStatus(Map<String, dynamic> loan) {
    final status = loan['status']?.toString() ?? 'PENDING';

    if (status == 'RETURNED') {
      return 'RETURNED';
    }

    final dueDate = DateTime.tryParse(loan['dueDate']?.toString() ?? '');

    if (dueDate == null) {
      return status;
    }

    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final dueOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);

    if (dueOnly.isBefore(todayOnly)) {
      return 'LATE';
    }

    return 'PENDING';
  }

  String getStatusText(String status) {
    switch (status) {
      case 'RETURNED':
        return 'Devolvido';
      case 'LATE':
        return 'Atrasado';
      case 'PENDING':
      default:
        return 'Pendente';
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'RETURNED':
        return Colors.green;
      case 'LATE':
        return Colors.red;
      case 'PENDING':
      default:
        return Colors.orange;
    }
  }

  String formatDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Sem data';
    }

    final date = DateTime.tryParse(value);

    if (date == null) {
      return 'Sem data';
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }

  List<Map<String, dynamic>> get recentLoans {
    final sortedLoans = [...loans];

    sortedLoans.sort((a, b) {
      final dateA = DateTime.tryParse(a['createdAt']?.toString() ?? '');
      final dateB = DateTime.tryParse(b['createdAt']?.toString() ?? '');

      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;

      return dateB.compareTo(dateA);
    });

    return sortedLoans.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: loadProfileData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (errorMessage != null)
                  buildErrorState()
                else ...[
                  buildProfileHeader(),
                  const SizedBox(height: 25),
                  buildStatisticsGrid(),
                  const SizedBox(height: 30),
                  buildHistorySection(),
                  const SizedBox(height: 30),
                  buildSettingsSection(),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavigation(currentIndex: 3),
    );
  }

  Widget buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 42,
            backgroundColor: Colors.white,
            child: Text(
              initials,
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 28,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            userName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            userEmail,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Text(
              'Minha Biblioteca Bookly',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildStatisticsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildSectionTitle('Resumo'),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _ProfileStatCard(
                title: 'Livros',
                value: totalBooks.toString(),
                icon: Icons.menu_book_outlined,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ProfileStatCard(
                title: 'Pendentes',
                value: totalPending.toString(),
                icon: Icons.schedule,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ProfileStatCard(
                title: 'Atrasados',
                value: totalLate.toString(),
                icon: Icons.warning_amber_rounded,
                color: Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ProfileStatCard(
                title: 'Devolvidos',
                value: totalReturned.toString(),
                icon: Icons.check_circle_outline,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildSectionTitle('Histórico recente'),
        const SizedBox(height: 14),
        if (recentLoans.isEmpty)
          const _EmptyCard(
            icon: Icons.history,
            title: 'Nenhum empréstimo ainda',
            description:
                'Quando você cadastrar empréstimos, o histórico aparecerá aqui.',
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentLoans.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final loan = recentLoans[index];

              final friend = loan['friend'] as Map<String, dynamic>?;
              final book = loan['book'] as Map<String, dynamic>?;

              final friendName = friend?['name']?.toString() ?? 'Sem amigo';
              final bookTitle = book?['title']?.toString() ?? 'Sem livro';
              final dueDate = formatDate(loan['dueDate']?.toString());
              final status = getVisualStatus(loan);

              return _HistoryCard(
                friendName: friendName,
                bookTitle: bookTitle,
                dueDate: dueDate,
                status: getStatusText(status),
                statusColor: getStatusColor(status),
              );
            },
          ),
      ],
    );
  }

  Widget buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildSectionTitle('Configurações'),
        const SizedBox(height: 14),
        _SettingsTile(
          icon: Icons.refresh,
          title: 'Atualizar dados',
          subtitle: 'Buscar informações mais recentes do banco local',
          onTap: loadProfileData,
        ),
        const SizedBox(height: 12),
        _SettingsTile(
          icon: Icons.person_outline,
          title: 'Login e cadastro',
          subtitle: 'Será implementado em uma próxima etapa',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Login e cadastro serão feitos depois.'),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
    );
  }

  Widget buildErrorState() {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: _EmptyCard(
        icon: Icons.error_outline,
        title: 'Erro ao carregar perfil',
       description:
    'Erro ao carregar os dados locais.\nTente fechar e abrir o aplicativo novamente.\n\n$errorMessage',
    ),
    );
  }
}

class _ProfileStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _ProfileStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
  height: 135,
  padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 28,
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 4),
          Text(
  title,
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
  style: TextStyle(
    color: Colors.grey[700],
    fontWeight: FontWeight.w600,
    fontSize: 13,
  ),
),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final String friendName;
  final String bookTitle;
  final String dueDate;
  final String status;
  final Color statusColor;

  const _HistoryCard({
    required this.friendName,
    required this.bookTitle,
    required this.dueDate,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.secondary,
            child: Text(
              friendName.isNotEmpty ? friendName[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friendName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(bookTitle),
                Text(
                  'Prazo: $dueDate',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: .12),
              child: Icon(
                icon,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _EmptyCard({
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
          Icon(
            icon,
            size: 44,
            color: AppColors.primary,
          ),
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
            style: TextStyle(
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}