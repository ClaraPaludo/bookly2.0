import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/app_colors.dart';
import '../services/books_service.dart';
import '../services/loans_service.dart';
import '../services/session_service.dart';
import '../services/users_service.dart';
import '../widgets/app_bottom_navigation.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isLoading = true;
  bool isSaving = false;
  String? errorMessage;

  Map<String, dynamic>? currentUser;
  List<Map<String, dynamic>> books = [];
  List<Map<String, dynamic>> loans = [];

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final ImagePicker picker = ImagePicker();

  Uint8List? selectedProfileImageBytes;

  @override
  void initState() {
    super.initState();
    loadProfileData();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    super.dispose();
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
        selectedProfileImageBytes = null;
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

  String get userName {
    final name = currentUser?['name']?.toString().trim();

    if (name == null || name.isEmpty || name == 'Usuário Bookly') {
      return 'User123';
    }

    return name;
  }

  String get userEmail {
    final email = currentUser?['email']?.toString().trim();

    if (email == null || email.isEmpty) {
      return 'usuario@bookly.com';
    }

    return email;
  }

  String get initials {
    final name = userName.trim();

    if (name.isEmpty) return '?';

    final parts = name.split(' ');

    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  int get totalBooks => books.length;

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

    if (status == 'RETURNED') return 'RETURNED';

    final dueDate = DateTime.tryParse(loan['dueDate']?.toString() ?? '');

    if (dueDate == null) return status;

    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final dueOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);

    return dueOnly.isBefore(todayOnly) ? 'LATE' : 'PENDING';
  }

  Uint8List? decodeBase64Image(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    try {
      final base64Text = value.contains(',') ? value.split(',').last : value;
      return base64Decode(base64Text);
    } catch (_) {
      return null;
    }
  }

  String? imageToBase64(Uint8List? bytes) {
    if (bytes == null) return null;

    return 'data:image/png;base64,${base64Encode(bytes)}';
  }

  Uint8List? get profileImageBytes {
    return selectedProfileImageBytes ??
        decodeBase64Image(currentUser?['profilePhotoUrl']?.toString());
  }

  Future<void> pickProfileImage({StateSetter? modalSetState}) async {
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (image == null) return;

    final bytes = await image.readAsBytes();

    setState(() {
      selectedProfileImageBytes = bytes;
    });

    modalSetState?.call(() {});
  }

  void openEditProfileSheet() {
    nameController.text = userName == 'User123' ? '' : userName;
    emailController.text = userEmail == 'usuario@bookly.com' ? '' : userEmail;
    selectedProfileImageBytes = null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            final imageBytes = selectedProfileImageBytes ??
                decodeBase64Image(currentUser?['profilePhotoUrl']?.toString());

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 14,
                bottom: MediaQuery.of(context).viewInsets.bottom + 14,
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
                    const SizedBox(height: 14),
                    Text(
                      'Editar perfil',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () {
                        pickProfileImage(modalSetState: modalSetState);
                      },
                      child: CircleAvatar(
                        radius: 48,
                        backgroundColor: AppColors.primary,
                        backgroundImage:
                            imageBytes == null ? null : MemoryImage(imageBytes),
                        child: imageBytes == null
                            ? Text(
                                initials,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 28,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        pickProfileImage(modalSetState: modalSetState);
                      },
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Escolher foto de perfil'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      decoration: inputDecoration('Nome de usuário'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: inputDecoration('E-mail opcional'),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: isSaving
                            ? null
                            : () {
                                saveProfile(modalContext);
                              },
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
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(
                          isSaving ? 'Salvando...' : 'Salvar perfil',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
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
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  Future<void> saveProfile(BuildContext modalContext) async {
    final user = currentUser;

    if (user == null) return;

    final name = nameController.text.trim().isEmpty
        ? 'User123'
        : nameController.text.trim();

    final email = emailController.text.trim().isEmpty
        ? 'usuario@bookly.com'
        : emailController.text.trim();

    setState(() {
      isSaving = true;
    });

    try {
      await UsersService.updateUser(
        id: user['id'].toString(),
        name: name,
        email: email,
        profilePhotoUrl: imageToBase64(selectedProfileImageBytes),
      );

      if (!mounted) return;

      Navigator.pop(modalContext);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil atualizado com sucesso!')),
      );

      await loadProfileData();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar perfil: $error'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: loadProfileData,
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
                        children: [
                          buildProfileHeader(),
                          const SizedBox(height: 20),
                          buildStatisticsGrid(),
                          const SizedBox(height: 24),
                          buildSettingsSection(),
                        ],
                      ),
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavigation(currentIndex: 3),
    );
  }

  Widget buildProfileHeader() {
    final imageBytes = profileImageBytes;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: Colors.white,
            backgroundImage: imageBytes == null ? null : MemoryImage(imageBytes),
            child: imageBytes == null
                ? Text(
                    initials,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 12),
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
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: openEditProfileSheet,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white70),
            ),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Editar perfil'),
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
        const SizedBox(height: 12),
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
            const SizedBox(width: 10),
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
        const SizedBox(height: 10),
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
            const SizedBox(width: 10),
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

  Widget buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildSectionTitle('Configurações locais'),
        const SizedBox(height: 12),
        _SettingsTile(
          icon: Icons.refresh,
          title: 'Atualizar dados',
          subtitle: 'Recarregar as informações salvas no dispositivo',
          onTap: loadProfileData,
        ),
        const SizedBox(height: 10),
        _SettingsTile(
          icon: Icons.person_outline,
          title: 'Editar perfil local',
          subtitle: 'Alterar foto, nome e e-mail do usuário',
          onTap: openEditProfileSheet,
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
      height: 125,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 26),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 27,
            ),
          ),
          const SizedBox(height: 3),
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
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
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