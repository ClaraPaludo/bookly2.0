import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../services/loans_service.dart';

class LoanDetailPage extends StatefulWidget {
  final String loanId;

  const LoanDetailPage({
    super.key,
    required this.loanId,
  });

  @override
  State<LoanDetailPage> createState() => _LoanDetailPageState();
}

class _LoanDetailPageState extends State<LoanDetailPage> {
  bool isLoading = true;
  bool isUpdating = false;
  String? errorMessage;

  Map<String, dynamic>? loan;

  @override
  void initState() {
    super.initState();
    loadLoan();
  }

  Future<void> loadLoan() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final loadedLoan = await LoansService.getLoanById(widget.loanId);

      if (!mounted) return;

      setState(() {
        loan = loadedLoan;
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

  Future<void> markAsReturned() async {
    setState(() {
      isUpdating = true;
    });

    try {
      await LoansService.markLoanAsReturned(widget.loanId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Empréstimo marcado como devolvido!'),
        ),
      );

      await loadLoan();

      if (!mounted) return;

      Navigator.pop(context, true);
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

  String getVisualStatus(Map<String, dynamic> loanData) {
    final status = loanData['status']?.toString() ?? 'PENDING';

    if (status == 'RETURNED') {
      return 'RETURNED';
    }

    final dueDate = DateTime.tryParse(loanData['dueDate']?.toString() ?? '');

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
      return 'Não informado';
    }

    final date = DateTime.tryParse(value);

    if (date == null) {
      return 'Não informado';
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }

  String getDeadlineMessage(Map<String, dynamic> loanData) {
    final status = getVisualStatus(loanData);

    if (status == 'RETURNED') {
      return 'Este livro já foi devolvido.';
    }

    final dueDate = DateTime.tryParse(loanData['dueDate']?.toString() ?? '');

    if (dueDate == null) {
      return 'Prazo não informado.';
    }

    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final dueOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);

    final days = dueOnly.difference(todayOnly).inDays;

    if (days < 0) {
      return 'Atrasado há ${days.abs()} dia(s).';
    }

    if (days == 0) {
      return 'A devolução é hoje.';
    }

    if (days == 1) {
      return 'Falta 1 dia para a devolução.';
    }

    return 'Faltam $days dias para a devolução.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detalhe do Empréstimo'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : errorMessage != null
                ? buildErrorState()
                : loan == null
                    ? const Center(
                        child: Text('Empréstimo não encontrado.'),
                      )
                    : buildContent(),
      ),
    );
  }

  Widget buildContent() {
    final loanData = loan!;

    final friend = loanData['friend'] as Map<String, dynamic>?;
    final book = loanData['book'] as Map<String, dynamic>?;

    final friendName = friend?['name']?.toString() ?? 'Sem amigo';
    final friendEmail = friend?['email']?.toString();
    final friendPhone = friend?['phone']?.toString();

    final bookTitle = book?['title']?.toString() ?? 'Sem livro';
    final bookAuthor = book?['author']?.toString() ?? 'Autor não informado';
    final bookCategory = book?['category']?.toString();

    final status = getVisualStatus(loanData);
    final statusText = getStatusText(status);
    final statusColor = getStatusColor(status);

    final canReturn = status != 'RETURNED';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          buildStatusCard(statusText, statusColor, loanData),
          const SizedBox(height: 18),
          buildBookCard(bookTitle, bookAuthor, bookCategory),
          const SizedBox(height: 18),
          buildFriendCard(friendName, friendEmail, friendPhone),
          const SizedBox(height: 18),
          buildDatesCard(loanData),
          const SizedBox(height: 26),
          if (canReturn)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: isUpdating ? null : markAsReturned,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: isUpdating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(
                  isUpdating ? 'Atualizando...' : 'Marcar como devolvido',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildStatusCard(
    String statusText,
    Color statusColor,
    Map<String, dynamic> loanData,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: statusColor.withValues(alpha: .35),
        ),
      ),
      child: Column(
        children: [
          Icon(
            statusText == 'Devolvido'
                ? Icons.check_circle_outline
                : statusText == 'Atrasado'
                    ? Icons.warning_amber_rounded
                    : Icons.schedule,
            color: statusColor,
            size: 44,
          ),
          const SizedBox(height: 12),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            getDeadlineMessage(loanData),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildBookCard(String title, String author, String? category) {
    return _InfoCard(
      title: 'Livro',
      icon: Icons.menu_book_outlined,
      children: [
        _InfoLine(label: 'Título', value: title),
        _InfoLine(label: 'Autor', value: author),
        if (category != null && category.trim().isNotEmpty)
          _InfoLine(label: 'Categoria', value: category),
      ],
    );
  }

  Widget buildFriendCard(String name, String? email, String? phone) {
    return _InfoCard(
      title: 'Amigo',
      icon: Icons.person_outline,
      children: [
        _InfoLine(label: 'Nome', value: name),
        if (email != null && email.trim().isNotEmpty)
          _InfoLine(label: 'E-mail', value: email),
        if (phone != null && phone.trim().isNotEmpty)
          _InfoLine(label: 'Telefone', value: phone),
      ],
    );
  }

  Widget buildDatesCard(Map<String, dynamic> loanData) {
    return _InfoCard(
      title: 'Datas',
      icon: Icons.calendar_month_outlined,
      children: [
        _InfoLine(
          label: 'Data do empréstimo',
          value: formatDate(loanData['loanDate']?.toString()),
        ),
        _InfoLine(
          label: 'Prazo de devolução',
          value: formatDate(loanData['dueDate']?.toString()),
        ),
        if (loanData['returnedDate'] != null)
          _InfoLine(
            label: 'Data de devolução',
            value: formatDate(loanData['returnedDate']?.toString()),
          ),
      ],
    );
  }

  Widget buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: _InfoCard(
          title: 'Erro ao carregar empréstimo',
          icon: Icons.error_outline,
          children: [
            Text(
              'Erro ao carregar os dados locais.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: .12),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLine({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 135,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}