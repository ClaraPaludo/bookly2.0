import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../services/books_service.dart';

class BookDetailPage extends StatefulWidget {
  final String bookId;

  const BookDetailPage({
    super.key,
    required this.bookId,
  });

  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  bool isLoading = true;
  bool isSaving = false;
  String? errorMessage;

  Map<String, dynamic>? book;

  final titleController = TextEditingController();
  final authorController = TextEditingController();
  final publisherController = TextEditingController();
  final categoryController = TextEditingController();
  final descriptionController = TextEditingController();
  final coverUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadBook();
  }

  @override
  void dispose() {
    titleController.dispose();
    authorController.dispose();
    publisherController.dispose();
    categoryController.dispose();
    descriptionController.dispose();
    coverUrlController.dispose();
    super.dispose();
  }

  Future<void> loadBook() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final loadedBook = await BooksService.getBookById(widget.bookId);

      if (!mounted) return;

      setState(() {
        book = loadedBook;
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

  Future<void> updateBook() async {
    if (titleController.text.trim().isEmpty ||
        authorController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Título e autor são obrigatórios.'),
        ),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      await BooksService.updateBook(
        id: widget.bookId,
        title: titleController.text.trim(),
        author: authorController.text.trim(),
        publisher: publisherController.text.trim().isEmpty
            ? null
            : publisherController.text.trim(),
        category: categoryController.text.trim().isEmpty
            ? null
            : categoryController.text.trim(),
        description: descriptionController.text.trim().isEmpty
            ? null
            : descriptionController.text.trim(),
        coverUrl: coverUrlController.text.trim().isEmpty
            ? null
            : coverUrlController.text.trim(),
      );

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Livro atualizado com sucesso!'),
        ),
      );

      await loadBook();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar livro: $error'),
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

  Future<void> deleteBook() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir livro'),
          content: const Text(
            'Tem certeza que deseja excluir este livro? Essa ação não poderá ser desfeita.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await BooksService.deleteBook(widget.bookId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Livro excluído com sucesso!'),
        ),
      );

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao excluir livro: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void openEditSheet() {
    final currentBook = book;

    if (currentBook == null) return;

    titleController.text = currentBook['title']?.toString() ?? '';
    authorController.text = currentBook['author']?.toString() ?? '';
    publisherController.text = currentBook['publisher']?.toString() ?? '';
    categoryController.text = currentBook['category']?.toString() ?? '';
    descriptionController.text = currentBook['description']?.toString() ?? '';
    coverUrlController.text = currentBook['coverUrl']?.toString() ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 18,
            right: 18,
            top: 18,
            bottom: MediaQuery.of(context).viewInsets.bottom + 18,
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Editar livro',
                  style: TextStyle(
                    color: AppTheme.title,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: titleController,
                  decoration: inputDecoration('Título'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: authorController,
                  decoration: inputDecoration('Autor'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: publisherController,
                  decoration: inputDecoration('Editora'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: categoryController,
                  decoration: inputDecoration('Categoria'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: coverUrlController,
                  decoration: inputDecoration('URL da capa'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  maxLines: 4,
                  decoration: inputDecoration('Descrição'),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: isSaving ? null : updateBook,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.save_outlined),
                    label: const Text(
                      'Salvar alterações',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  InputDecoration inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppTheme.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: AppTheme.primary,
          width: 1.5,
        ),
      ),
    );
  }

  String safeCoverUrl(Map<String, dynamic> bookData) {
    final coverUrl = bookData['coverUrl']?.toString();

    if (coverUrl == null || coverUrl.trim().isEmpty) {
      return 'https://images.unsplash.com/photo-1544947950-fa07a98d237f?q=80&w=500';
    }

    return coverUrl;
  }

  String getStatusText(Map<String, dynamic> bookData) {
    final available = bookData['available'] == true;

    return available ? 'Disponível' : 'Emprestado';
  }

  Color getStatusColor(Map<String, dynamic> bookData) {
    final available = bookData['available'] == true;

    return available ? Colors.green : Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Detalhes do Livro'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          if (book != null)
            IconButton(
              onPressed: openEditSheet,
              icon: const Icon(Icons.edit_outlined),
            ),
          if (book != null)
            IconButton(
              onPressed: deleteBook,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : errorMessage != null
              ? buildErrorState()
              : book == null
                  ? const Center(
                      child: Text('Livro não encontrado.'),
                    )
                  : buildContent(),
    );
  }

  Widget buildContent() {
    final bookData = book!;

    final title = bookData['title']?.toString() ?? 'Sem título';
    final author = bookData['author']?.toString() ?? 'Autor não informado';
    final publisher = bookData['publisher']?.toString();
    final category = bookData['category']?.toString();
    final description = bookData['description']?.toString();

    final statusText = getStatusText(bookData);
    final statusColor = getStatusColor(bookData);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            height: 280,
            width: 190,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                safeCoverUrl(bookData),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Container(
                    color: AppTheme.card,
                    child: Icon(
                      Icons.menu_book_outlined,
                      color: AppTheme.primary,
                      size: 58,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 25),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.title,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            author,
            style: TextStyle(
              color: AppTheme.subtitle,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 25),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Informações',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.title,
                  ),
                ),
                const SizedBox(height: 15),
                _InfoLine(label: 'Autor', value: author),
                if (publisher != null && publisher.trim().isNotEmpty)
                  _InfoLine(label: 'Editora', value: publisher),
                if (category != null && category.trim().isNotEmpty)
                  _InfoLine(label: 'Categoria', value: category),
                if (description != null && description.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Descrição',
                    style: TextStyle(
                      color: AppTheme.title,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(color: AppTheme.subtitle),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'Erro ao carregar livro:\n$errorMessage',
          textAlign: TextAlign.center,
        ),
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
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: AppTheme.subtitle,
        ),
      ),
    );
  }
}