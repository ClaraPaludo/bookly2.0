import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';


import '../core/app_theme.dart';
import '../services/books_service.dart';
import '../services/session_service.dart';

class AddBookPage extends StatefulWidget {
  const AddBookPage({super.key});

  @override
  State<AddBookPage> createState() => _AddBookPageState();
}

class _AddBookPageState extends State<AddBookPage> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _publisherController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  Uint8List? _selectedImageBytes;

  String? _selectedCategory;

  final List<String> _categories = [
    'Romance',
    'Fantasia',
    'Ficção Científica',
    'Suspense',
    'Terror',
    'Mistério',
    'Drama',
    'Aventura',
    'Biografia',
    'História',
    'Autoajuda',
    'Educação',
    'Religião',
    'Infantil',
    'HQ / Mangá',
    'Tecnologia',
    'Negócios',
    'Outro',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _publisherController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 85,
    );

    if (image == null) {
      return;
    }

    final bytes = await image.readAsBytes();

    setState(() {
      _selectedImageBytes = bytes;

      if (!kIsWeb) {
        _selectedImage = File(image.path);
      }
    });
  }

  Future<void> _saveBook() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = await SessionService.getCurrentUserId();

      await BooksService.createBook(
        userId: userId,
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        publisher: _publisherController.text.trim().isEmpty
            ? null
            : _publisherController.text.trim(),
        category: _selectedCategory,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        coverUrl: _selectedImageBytes == null
    ? null
    : 'data:image/png;base64,${base64Encode(_selectedImageBytes!)}',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Livro cadastrado com sucesso!')),
      );

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao cadastrar livro: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF3F5CCB), width: 1.5),
      ),
    );
  }

  Widget _buildSelectedImage() {
  final title = _titleController.text.trim();

  if (_selectedImageBytes != null) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.memory(
            _selectedImageBytes!,
            height: 190,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title.isEmpty ? 'Capa do livro' : title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  if (!kIsWeb && _selectedImage != null) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(
            _selectedImage!,
            height: 190,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title.isEmpty ? 'Capa do livro' : title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: Colors.grey.shade300,
        width: 1.5,
      ),
    ),
    child: Column(
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 44,
          color: AppTheme.primary,
        ),
        const SizedBox(height: 8),
        Text(
          'Adicionar capa do livro',
          style: TextStyle(
            color: AppTheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Escolha uma imagem da galeria ou tire uma foto.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 13,
          ),
        ),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Cadastrar Livro'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
  controller: _titleController,
  onChanged: (_) {
    setState(() {});
  },
  decoration: _decoration(
    'Título do livro',
    Icons.menu_book_outlined,
  ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o título do livro.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _authorController,
                decoration: _decoration('Autor', Icons.edit_outlined),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o autor.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _publisherController,
                decoration: _decoration('Editora', Icons.apartment_outlined),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: _decoration('Categoria', Icons.category_outlined),
                items: _categories.map((categoria) {
                  return DropdownMenuItem(
                    value: categoria,
                    child: Text(categoria),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
              ),
              const SizedBox(height: 14),
              Column(
                children: [
                  _buildSelectedImage(),

                  if (_selectedImageBytes != null || _selectedImage != null)
                    const SizedBox(height: 12),

                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo),
                    label: const Text('Escolher da galeria'),
                  ),

                  const SizedBox(height: 12),

                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Tirar foto'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: _decoration('Descrição', Icons.notes_outlined),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveBook,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    _isLoading ? 'Salvando...' : 'Salvar livro',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}