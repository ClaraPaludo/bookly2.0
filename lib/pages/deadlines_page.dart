import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../services/loans_service.dart';
import '../services/session_service.dart';
import '../widgets/app_bottom_navigation.dart';
import '../pages/loan_detail_page.dart';

class DeadlinesPage extends StatefulWidget {
  const DeadlinesPage({super.key});

  @override
  State<DeadlinesPage> createState() => _DeadlinesPageState();
}

class _DeadlinesPageState extends State<DeadlinesPage> {
  bool isLoading = true;
  bool isUpdating = false;
  String? errorMessage;

  String selectedFilter = 'ALL';

  List<Map<String, dynamic>> loans = [];

  @override
  void initState() {
    super.initState();
    loadLoans();
  }

  Future<void> loadLoans() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final userId = await SessionService.getCurrentUserId();

      final loadedLoans = await LoansService.listLoans(
        userId: userId,
      );

      if (!mounted) return;

      setState(() {
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

  Future<void> markAsReturned(String loanId) async {
    setState(() {
      isUpdating = true;
    });

    try {
      await LoansService.markLoanAsReturned(loanId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Empréstimo marcado como devolvido!'),
        ),
      );

      await loadLoans();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao marcar como devolvido: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isUpdating = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get filteredLoans {
    final sortedLoans = [...loans];

    sortedLoans.sort((a, b) {
      final dateA = DateTime.tryParse(a['dueDate']?.toString() ?? '');
      final dateB = DateTime.tryParse(b['dueDate']?.toString() ?? '');

      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;

      return dateA.compareTo(dateB);
    });

    if (selectedFilter == 'ALL') {
      return sortedLoans;
    }

    return sortedLoans.where((loan) {
      final visualStatus = getVisualStatus(loan);
      return visualStatus == selectedFilter;
    }).toList();
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
      return 'Sem prazo';
    }

    final date = DateTime.tryParse(value);

    if (date == null) {
      return 'Sem prazo';
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }

  int daysUntilDue(String? value) {
    final date = DateTime.tryParse(value ?? '');

    if (date == null) {
      return 0;
    }

    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final dueOnly = DateTime(date.year, date.month, date.day);

    return dueOnly.difference(todayOnly).inDays;
  }

  String getDeadlineMessage(Map<String, dynamic> loan) {
    final status = getVisualStatus(loan);

    if (status == 'RETURNED') {
      return 'Livro já devolvido';
    }

    final days = daysUntilDue(loan['dueDate']?.toString());

    if (days < 0) {
      return 'Atrasado há ${days.abs()} dia(s)';
    }

    if (days == 0) {
      return 'Devolve hoje';
    }

    if (days == 1) {
      return 'Falta 1 dia';
    }

    return 'Faltam $days dias';
  }

  @override
  Widget build(BuildContext context) {
    final visibleLoans = filteredLoans;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: loadLoans,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildHeader(),
                const SizedBox(height: 25),
                if (isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 50),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (errorMessage != null)
                  buildErrorState()
                else ...[
                  buildSummaryCards(),
                  const SizedBox(height: 25),
                  buildFilters(),
                  const SizedBox(height: 25),
                  buildLoansList(visibleLoans),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavigation(currentIndex: 2),
    );
  }

  Widget buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Prazos',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Acompanhe devoluções e atrasos',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 15,
              ),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: IconButton(
            onPressed: loadLoans,
            icon: const Icon(Icons.refresh),
          ),
        ),
      ],
    );
  }

  Widget buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: 'Pendentes',
            value: totalPending.toString(),
            color: Colors.orange,
            icon: Icons.schedule,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            title: 'Atrasados',
            value: totalLate.toString(),
            color: Colors.red,
            icon: Icons.warning_amber_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            title: 'Devolvidos',
            value: totalReturned.toString(),
            color: Colors.green,
            icon: Icons.check_circle_outline,
          ),
        ),
      ],
    );
  }

  Widget buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChipButton(
            label: 'Todos',
            isSelected: selectedFilter == 'ALL',
            onTap: () {
              setState(() {
                selectedFilter = 'ALL';
              });
            },
          ),
          const SizedBox(width: 8),
          _FilterChipButton(
            label: 'Pendentes',
            isSelected: selectedFilter == 'PENDING',
            onTap: () {
              setState(() {
                selectedFilter = 'PENDING';
              });
            },
          ),
          const SizedBox(width: 8),
          _FilterChipButton(
            label: 'Atrasados',
            isSelected: selectedFilter == 'LATE',
            onTap: () {
              setState(() {
                selectedFilter = 'LATE';
              });
            },
          ),
          const SizedBox(width: 8),
          _FilterChipButton(
            label: 'Devolvidos',
            isSelected: selectedFilter == 'RETURNED',
            onTap: () {
              setState(() {
                selectedFilter = 'RETURNED';
              });
            },
          ),
        ],
      ),
    );
  }

  Widget buildLoansList(List<Map<String, dynamic>> visibleLoans) {
    if (visibleLoans.isEmpty) {
      return const _EmptyCard(
        icon: Icons.event_available_outlined,
        title: 'Nenhum prazo encontrado',
        description:
            'Quando você cadastrar empréstimos, os prazos aparecerão aqui.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lista de devoluções',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 15),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: visibleLoans.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final loan = visibleLoans[index];

            final friend = loan['friend'] as Map<String, dynamic>?;
            final book = loan['book'] as Map<String, dynamic>?;

            final friendName = friend?['name']?.toString() ?? 'Sem amigo';
            final bookTitle = book?['title']?.toString() ?? 'Sem livro';
            final dueDate = formatDate(loan['dueDate']?.toString());
            final status = getVisualStatus(loan);

            return InkWell(
  borderRadius: BorderRadius.circular(18),
  onTap: () async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => LoanDetailPage(
          loanId: loan['id'].toString(),
        ),
      ),
    );

    if (result == true) {
      await loadLoans();
    }
  },
  child: _DeadlineCard(
    friendName: friendName,
    bookTitle: bookTitle,
    dueDate: dueDate,
    deadlineMessage: getDeadlineMessage(loan),
    status: getStatusText(status),
    statusColor: getStatusColor(status),
    canMarkReturned: status != 'RETURNED',
    isUpdating: isUpdating,
    onMarkReturned: () {
      markAsReturned(loan['id'].toString());
    },
  ),
);
          },
        ),
      ],
    );
  }

  Widget buildErrorState() {
    return _EmptyCard(
      icon: Icons.error_outline,
      title: 'Erro ao carregar prazos',
      description:
    'Erro ao carregar os dados locais.\nTente fechar e abrir o aplicativo novamente.\n\n$errorMessage',
     );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 26,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChipButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _DeadlineCard extends StatelessWidget {
  final String friendName;
  final String bookTitle;
  final String dueDate;
  final String deadlineMessage;
  final String status;
  final Color statusColor;
  final bool canMarkReturned;
  final bool isUpdating;
  final VoidCallback onMarkReturned;

  const _DeadlineCard({
    required this.friendName,
    required this.bookTitle,
    required this.dueDate,
    required this.deadlineMessage,
    required this.status,
    required this.statusColor,
    required this.canMarkReturned,
    required this.isUpdating,
    required this.onMarkReturned,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
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
                    const SizedBox(height: 3),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 18,
                color: statusColor,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  deadlineMessage,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (canMarkReturned)
                TextButton.icon(
                  onPressed: isUpdating ? null : onMarkReturned,
                  icon: const Icon(Icons.check),
                  label: const Text('Devolver'),
                ),
            ],
          ),
        ],
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