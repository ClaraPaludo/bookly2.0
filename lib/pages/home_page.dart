import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'notifications_page.dart';
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

  String search = '';
  bool isLoading = true;
  String? errorMessage;

  List<Map<String, dynamic>> books = [];
  List<Map<String, dynamic>> loans = [];

  // Lista filtrada conforme o texto digitado no campo de busca.
  List<Map<String, dynamic>> get filteredBooks {
    final query = search.trim().toLowerCase();

    if (query.isEmpty) return books;

    return books.where((book) {
      final title = book['title']?.toString().toLowerCase() ?? '';
      final author = book['author']?.toString().toLowerCase() ?? '';
      final category = book['category']?.toString().toLowerCase() ?? '';

      return title.contains(query) ||
          author.contains(query) ||
          category.contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();

    // Carrega os dados da tela assim que a Home abre.
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

      // Busca os dados direto do SQLite através dos services.
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
      MaterialPageRoute(builder: (_) => const AddBookPage()),
    );

    // Se cadastrou livro novo, recarrega a Home.
    if (result == true) {
      await loadHomeData();
    }
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

  // Pega a capa salva no banco.
  // Se não tiver capa, retorna null.
  // Isso evita aquela imagem preta/padrão aparecendo quando o usuário não cadastrou foto.
  String? getBookCover(Map<String, dynamic> book) {
    final coverUrl = book['coverUrl']?.toString();

    if (coverUrl == null || coverUrl.trim().isEmpty) {
      return null;
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
                  buildBooksSection(),
                  const SizedBox(height: 30),
                  buildStatistics(),
                  const SizedBox(height: 30),
                  buildRecentLoans(),
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
              'A melhor forma de organizar seus livros',
              style: TextStyle(color: Colors.grey[700], fontSize: 15),
            ),
          ],
        ),
        Container(
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
  ),
  child: IconButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NotificationsPage(),
      ),
    );
  },
  icon: const Icon(Icons.notifications_none_outlined),
  tooltip: 'Lembretes',
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
        hintText: 'Buscar meus livros...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: search.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  searchController.clear();
                  setState(() {
                    search = '';
                  });
                },
              )
            : null,
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
                  MaterialPageRoute(builder: (_) => const NewLoanPage()),
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
                      builder: (_) =>
                          LoanDetailPage(loanId: loan['id'].toString()),
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
    // Aqui pegamos a lista já filtrada pela busca da Home.
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

        // Se não tiver nenhum livro cadastrado ou nenhum resultado na busca,
        // mostramos um card vazio explicando o que fazer.
        if (visibleBooks.isEmpty)
          _EmptyCard(
            icon: Icons.search_off,
            title: search.isEmpty
                ? 'Nenhum livro cadastrado'
                : 'Nenhum resultado encontrado',
            description: search.isEmpty
                ? 'Clique no botão “Livro” para cadastrar o primeiro livro.'
                : 'Não encontramos livros para “$search”.',
          )
        else
          SizedBox(
            // Aumentei a altura porque agora o nome do livro aparece embaixo da capa.
            height: 230,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: visibleBooks.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),

              // Cada item da lista horizontal vira um BookCover.
              itemBuilder: (context, index) {
                final book = visibleBooks[index];

                return BookCover(
                  bookId: book['id'].toString(),

                  // Se tiver imagem salva no banco, usa a imagem.
                  // Se não tiver, o BookCover mostra um ícone de adicionar capa.
                  image: getBookCover(book),

                  title: book['title']?.toString() ?? 'Sem título',
                  author: book['author']?.toString() ?? 'Autor não informado',
                  year: '2026',
                  category: book['category']?.toString() ?? 'Sem categoria',
                  status:
                      book['available'] == true ? 'Disponível' : 'Emprestado',
                  description:
                      book['description']?.toString() ?? 'Sem descrição.',

                  // Quando editar/excluir algo nos detalhes do livro,
                  // a Home recarrega automaticamente.
                  onBookChanged: loadHomeData,
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
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(book),
                Text(
                  'Prazo: $deadline',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
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

class BookCover extends StatelessWidget {
  // Agora image pode ser null.
  // Isso permite mostrar um visual mais bonito quando o livro não tem capa.
  final String? image;

  final String title;
  final String author;
  final String year;
  final String category;
  final String description;
  final String status;
  final String bookId;
  final Future<void> Function()? onBookChanged;

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
    this.onBookChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = image != null && image!.trim().isNotEmpty;

    return GestureDetector(
      onTap: () async {
        // Quando clicar no livro, abre a página de detalhes.
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => BookDetailPage(bookId: bookId)),
        );

        // Se a página de detalhes alterou algo, recarrega a Home.
        if (result == true) {
          await onBookChanged?.call();
        }
      },
      child: SizedBox(
        width: 135,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Parte visual da capa.
            // Se tiver imagem, mostra a imagem.
            // Se não tiver imagem, mostra um card com ícone e texto.
            Container(
              height: 165,
              width: 135,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey.shade200, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: hasImage
                    ? _BookCoverImage(image: image!)
                    : const _BookCoverPlaceholder(),
              ),
            ),
            const SizedBox(height: 8),

            // Nome do livro embaixo da capa.
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),

            // Autor embaixo do nome.
            Text(
              author,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookCoverImage extends StatelessWidget {
  final String image;

  const _BookCoverImage({
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    // Quando a imagem foi salva pelo image_picker, ela fica no banco como:
    // data:image/png;base64,....
    // Então aqui precisamos transformar esse texto em bytes para mostrar com Image.memory.
    if (image.startsWith('data:image')) {
      final bytes = _decodeBase64Image(image);

      if (bytes == null) {
        return const _BookCoverPlaceholder();
      }

      return Image.memory(
        bytes,
        fit: BoxFit.cover,
      );
    }

    // Se algum dia o app usar uma imagem por URL normal, continua funcionando.
    return Image.network(
      image,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return const _BookCoverPlaceholder();
      },
    );
  }

  Uint8List? _decodeBase64Image(String value) {
    try {
      // Remove o começo "data:image/png;base64,"
      // e deixa somente o conteúdo base64 da imagem.
      final base64Text = value.contains(',') ? value.split(',').last : value;

      return base64Decode(base64Text);
    } catch (_) {
      return null;
    }
  }
}

// Widget separado só para o caso de o livro não ter capa.
// Assim evitamos aquele livro preto e deixamos claro que pode adicionar uma imagem.
class _BookCoverPlaceholder extends StatelessWidget {
  const _BookCoverPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            color: AppColors.primary,
            size: 38,
          ),
          const SizedBox(height: 8),
          Text(
            'Adicionar\ncapa',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}