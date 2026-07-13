import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../services/books_service.dart';
import '../services/friends_services.dart';
import '../services/loans_service.dart';
import '../services/session_service.dart';

class NewLoanPage extends StatefulWidget {
  const NewLoanPage({super.key});

  @override
  State<NewLoanPage> createState() => _NewLoanPageState();
}

class _NewLoanPageState extends State<NewLoanPage> {
  bool isLoading = true;
  bool isSaving = false;
  String? errorMessage;

  List<Map<String, dynamic>> friends = [];
  List<Map<String, dynamic>> books = [];

  Map<String, dynamic>? selectedFriend;
  Map<String, dynamic>? selectedBook;
  DateTime? selectedDueDate;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final userId = await SessionService.getCurrentUserId();

      final loadedFriends = await FriendsService.listFriends(userId: userId);
      final loadedBooks = await BooksService.listBooks(
        userId: userId,
        available: true,
      );

      if (!mounted) return;

      setState(() {
        friends = loadedFriends;
        books = loadedBooks;
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

  Future<void> pickDueDate() async {
    final today = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: today.add(const Duration(days: 7)),
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );

    if (pickedDate == null) return;

    setState(() {
      selectedDueDate = pickedDate;
    });
  }

  Future<void> saveLoan() async {
    if (selectedFriend == null) {
      showMessage('Selecione um amigo.');
      return;
    }

    if (selectedBook == null) {
      showMessage('Selecione um livro.');
      return;
    }

    if (selectedDueDate == null) {
      showMessage('Selecione o prazo de devolução.');
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final userId = await SessionService.getCurrentUserId();

      await LoansService.createLoan(
        userId: userId,
        friendId: selectedFriend!['id'].toString(),
        bookId: selectedBook!['id'].toString(),
        dueDate: selectedDueDate!,
        loanDate: DateTime.now(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Empréstimo cadastrado com sucesso!'),
        ),
      );

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao cadastrar empréstimo: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  String formatDate(DateTime? date) {
    if (date == null) {
      return 'Selecionar prazo';
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Novo Empréstimo'),
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
                : buildContent(),
      ),
    );
  }

  Widget buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('1. Escolha o amigo'),
          const SizedBox(height: 12),
          buildFriendsList(),
          const SizedBox(height: 28),
          buildSectionTitle('2. Escolha o livro'),
          const SizedBox(height: 12),
          buildBooksList(),
          const SizedBox(height: 28),
          buildSectionTitle('3. Defina o prazo'),
          const SizedBox(height: 12),
          buildDateCard(),
          const SizedBox(height: 30),
          buildSaveButton(),
        ],
      ),
    );
  }

  Widget buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: AppColors.primary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget buildFriendsList() {
    if (friends.isEmpty) {
      return const _EmptyCard(
        icon: Icons.people_outline,
        title: 'Nenhum amigo cadastrado',
        description:
            'Cadastre um amigo antes de criar um empréstimo.',
      );
    }

    return Column(
      children: friends.map((friend) {
        final name = friend['name']?.toString() ?? 'Sem nome';
        final email = friend['email']?.toString();
        final isSelected = selectedFriend?['id'] == friend['id'];

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              setState(() {
                selectedFriend = friend;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.secondary,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (email != null && email.trim().isNotEmpty)
                          Text(
                            email,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: AppColors.primary,
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget buildBooksList() {
    if (books.isEmpty) {
      return const _EmptyCard(
        icon: Icons.menu_book_outlined,
        title: 'Nenhum livro disponível',
        description:
            'Cadastre um livro ou aguarde a devolução de algum livro emprestado.',
      );
    }

    return Column(
      children: books.map((book) {
        final title = book['title']?.toString() ?? 'Sem título';
        final author = book['author']?.toString() ?? 'Autor não informado';
        final category = book['category']?.toString();
        final isSelected = selectedBook?['id'] == book['id'];

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              setState(() {
                selectedBook = book;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.menu_book_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
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
                        Text(
                          author,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 13,
                          ),
                        ),
                        if (category != null && category.trim().isNotEmpty)
                          Text(
                            category,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: AppColors.primary,
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget buildDateCard() {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: pickDueDate,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selectedDueDate == null
                ? Colors.transparent
                : AppColors.primary,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_month_outlined,
              color: AppColors.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                formatDate(selectedDueDate),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  Widget buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: isSaving ? null : saveLoan,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.check),
        label: Text(
          isSaving ? 'Salvando...' : 'Confirmar empréstimo',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: _EmptyCard(
          icon: Icons.error_outline,
          title: 'Erro ao carregar dados',
         description:
    'Erro ao carregar os dados locais.\nTente fechar e abrir o aplicativo novamente.\n\n$errorMessage',
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