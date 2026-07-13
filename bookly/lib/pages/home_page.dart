import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../pages/add_book_page.dart';
import '../pages/book_page.dart';
import '../services/books_service.dart';
import '../services/loans_service.dart';
import '../services/session_service.dart';
import '../widgets/app_bottom_navigation.dart';
import '../pages/new_loan_page.dart';
import '../pages/loan_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController searchController = TextEditingController();

  bool isLoading = true;
  String search = '';
  String? errorMessage;

  List<Map<String, dynamic>> books = [];
  List<Map<String, dynamic>> loans = [];

  @override
  void initState() {
    super.initState();
    loadHomeData();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadHomeData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final userId = await SessionService.getCurrentUserId();

      final loadedBooks = await BooksService.listBooks(userId: userId);
      final loadedLoans = await LoansService.listLoans(userId: userId);

      if (!mounted) return;

      setState(() {
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

  Future<void> openAddBookPage() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const AddBookPage(),
      ),
    );

    if (result == true) {
      await loadHomeData();
    }
  }

  List<Map<String, dynamic>> get filteredBooks {
    if (search.trim().isEmpty) {
      return books;
    }

    final searchLower = search.toLowerCase();

    return books.where((book) {
      final title = book['title']?.toString().toLowerCase() ?? '';
      final author = book['author']?.toString().toLowerCase() ?? '';

      return title.contains(searchLower) || author.contains(searchLower);
    }).toList();
  }

  int get pendingLoans {
    return loans.where((loan) => loan['status'] == 'PENDING').length;
  }

  int get returnedLoans {
    return loans.where((loan) => loan['status'] == 'RETURNED').length;
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

  String getBookCover(Map<String, dynamic> book) {
    final coverUrl = book['coverUrl']?.toString();

    if (coverUrl == null || coverUrl.trim().isEmpty) {
      return 'https://images.unsplash.com/photo-1544947950-fa07a98d237f?q=80&w=500';
    }

    return coverUrl;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: openAddBookPage,
        icon: const Icon(Icons.add),
        label: const Text('Livro'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: loadHomeData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildHeader(),
                const SizedBox(height: 25),
                buildSearchField(),
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
                  buildStatistics(),
                  const SizedBox(height: 30),
                  buildRecentLoans(),
                  const SizedBox(height: 30),
                  buildBooksSection(),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavigation(currentIndex: 0),
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
              'Minha Biblioteca',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Bem-vinda de volta 📚',
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
            onPressed: loadHomeData,
            icon: const Icon(Icons.refresh),
          ),
        ),
      ],
    );
  }

  Widget buildSearchField() {
    return TextField(
      controller: searchController,
      onChanged: (value) {
        setState(() {
          search = value;
        });
      },
      decoration: InputDecoration(
        hintText: 'Buscar livros...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget buildStatistics() {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Total',
            value: books.length.toString(),
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            title: 'Pendentes',
            value: pendingLoans.toString(),
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            title: 'Devolvidos',
            value: returnedLoans.toString(),
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget buildRecentLoans() {
    final recentLoans = loans.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text(
      'Empréstimos Recentes',
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    ),
    TextButton.icon(
      onPressed: () async {
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => const NewLoanPage(),
          ),
        );

        if (result == true) {
          await loadHomeData();
        }
      },
      icon: const Icon(Icons.add),
      label: const Text('Novo'),
    ),
  ],
),
const SizedBox(height: 15),
        if (recentLoans.isEmpty)
          const _EmptyCard(
            icon: Icons.assignment_outlined,
            title: 'Nenhum empréstimo cadastrado',
            description:
                'Quando você emprestar um livro, ele aparecerá nesta área.',
          )
        else
          ...recentLoans.map((loan) {
            final friend = loan['friend'] as Map<String, dynamic>?;
            final book = loan['book'] as Map<String, dynamic>?;

            final friendName = friend?['name']?.toString() ?? 'Sem amigo';
            final bookTitle = book?['title']?.toString() ?? 'Sem livro';
            final status = loan['status']?.toString() ?? 'PENDING';

            return Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: InkWell(
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
        await loadHomeData();
      }
    },
    child: _LoanCard(
      name: friendName,
      book: bookTitle,
      status: getStatusText(status),
      statusColor: getStatusColor(status),
      deadline: formatDate(loan['dueDate']?.toString()),
    ),
  ),
);
          }),
      ],
    );
  }

  Widget buildBooksSection() {
    final visibleBooks = filteredBooks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meus livros',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 15),
        if (visibleBooks.isEmpty)
          const _EmptyCard(
            icon: Icons.menu_book_outlined,
            title: 'Nenhum livro cadastrado',
            description:
                'Clique no botão “Livro” para cadastrar o primeiro livro da sua biblioteca.',
          )
        else
          SizedBox(
            height: 210,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: visibleBooks.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final book = visibleBooks[index];

                return BookCover(
  bookId: book['id'].toString(),
  image: getBookCover(book),
  title: book['title']?.toString() ?? 'Sem título',
  author: book['author']?.toString() ?? 'Autor não informado',
  year: '2026',
  category: book['category']?.toString() ?? 'Sem categoria',
  status: book['available'] == true ? 'Disponível' : 'Emprestado',
  description: book['description']?.toString() ?? 'Sem descrição.',
);
              },
            ),
          ),
      ],
    );
  }

  Widget buildErrorState() {
    return _EmptyCard(
      icon: Icons.error_outline,
      title: 'Erro ao carregar dados',
     description:
    'Erro ao carregar os dados locais.\nTente fechar e abrir o aplicativo novamente.\n\n$errorMessage',
     );
  }
}

class _LoanCard extends StatelessWidget {
  final String name;
  final String book;
  final String status;
  final Color statusColor;
  final String deadline;

  const _LoanCard({
    required this.name,
    required this.book,
    required this.status,
    required this.statusColor,
    required this.deadline,
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
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(book),
                Text(
                  'Prazo: $deadline',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 5),
          Text(title),
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

class BookCover extends StatelessWidget {
  final String image;
  final String title;
  final String author;
  final String year;
  final String category;
  final String description;
  final String status;
  final String bookId;

  const BookCover({
  super.key,
  required this.bookId,
  required this.image,
  required this.title,
  required this.author,
  required this.year,
  required this.category,
  required this.description,
  required this.status,
});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookDetailPage(
  bookId: bookId,
),
          ),
        );
      },
      child: Container(
        width: 125,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.network(
            image,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) {
              return Container(
                color: Colors.white,
                child: Icon(
                  Icons.menu_book_outlined,
                  color: AppColors.primary,
                  size: 42,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}