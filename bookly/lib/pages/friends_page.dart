import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../pages/add_friend_page.dart';
import '../services/friends_services.dart';
import '../services/session_service.dart';
import '../widgets/app_bottom_navigation.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final TextEditingController searchController = TextEditingController();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  bool isLoading = true;
  bool isSaving = false;
  String search = '';
  String? errorMessage;

  List<Map<String, dynamic>> friends = [];

  @override
  void initState() {
    super.initState();
    loadFriends();
  }

  @override
  void dispose() {
    searchController.dispose();
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> loadFriends() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final userId = await SessionService.getCurrentUserId();

      final loadedFriends = await FriendsService.listFriends(
        userId: userId,
      );

      if (!mounted) return;

      setState(() {
        friends = loadedFriends;
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

  Future<void> openAddFriendPage() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const AddFriendPage(),
      ),
    );

    if (result == true) {
      await loadFriends();
    }
  }

  Future<void> updateFriend(String friendId) async {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('O nome do amigo é obrigatório.'),
        ),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      await FriendsService.updateFriend(
        id: friendId,
        name: nameController.text.trim(),
        email: emailController.text.trim().isEmpty
            ? null
            : emailController.text.trim(),
        phone: phoneController.text.trim().isEmpty
            ? null
            : phoneController.text.trim(),
        notes: notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
      );

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Amigo atualizado com sucesso!'),
        ),
      );

      await loadFriends();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar amigo: $error'),
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

  Future<void> deleteFriend(String friendId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir amigo'),
          content: const Text(
           'Tem certeza que deseja excluir este amigo? Se ele tiver empréstimos vinculados, o aplicativo pode impedir a exclusão.',
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
      await FriendsService.deleteFriend(friendId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Amigo excluído com sucesso!'),
        ),
      );

      await loadFriends();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao excluir amigo: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void openEditFriendSheet(Map<String, dynamic> friend) {
    final friendId = friend['id'].toString();

    nameController.text = friend['name']?.toString() ?? '';
    emailController.text = friend['email']?.toString() ?? '';
    phoneController.text = friend['phone']?.toString() ?? '';
    notesController.text = friend['notes']?.toString() ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
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
                  'Editar amigo',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: nameController,
                  decoration: decoration(
                    'Nome',
                    Icons.person_outline,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: decoration(
                    'E-mail',
                    Icons.email_outlined,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: decoration(
                    'Telefone',
                    Icons.phone_outlined,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  maxLines: 4,
                  decoration: decoration(
                    'Observações',
                    Icons.notes_outlined,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          deleteFriend(friendId);
                        },
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Excluir'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.all(15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isSaving
                            ? null
                            : () {
                                updateFriend(friendId);
                              },
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Salvar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  InputDecoration decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Colors.grey.shade300,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: AppColors.primary,
          width: 1.5,
        ),
      ),
    );
  }

  List<Map<String, dynamic>> get filteredFriends {
    if (search.trim().isEmpty) {
      return friends;
    }

    final searchLower = search.toLowerCase();

    return friends.where((friend) {
      final name = friend['name']?.toString().toLowerCase() ?? '';
      final email = friend['email']?.toString().toLowerCase() ?? '';
      final phone = friend['phone']?.toString().toLowerCase() ?? '';

      return name.contains(searchLower) ||
          email.contains(searchLower) ||
          phone.contains(searchLower);
    }).toList();
  }

  String initialsFromName(String name) {
    final parts = name.trim().split(' ');

    if (parts.isEmpty || name.trim().isEmpty) {
      return '?';
    }

    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  int activeLoansCount(Map<String, dynamic> friend) {
    final loans = friend['loans'];

    if (loans is! List) {
      return 0;
    }

    return loans.where((loan) {
      if (loan is! Map<String, dynamic>) {
        return false;
      }

      final status = loan['status']?.toString();

      return status == 'PENDING' || status == 'LATE';
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final visibleFriends = filteredFriends;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: openAddFriendPage,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Amigo'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: loadFriends,
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
                else if (visibleFriends.isEmpty)
                  const _EmptyCard(
                    icon: Icons.people_outline,
                    title: 'Nenhum amigo cadastrado',
                    description:
                        'Clique no botão “Amigo” para cadastrar uma pessoa para quem você empresta livros.',
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: visibleFriends.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final friend = visibleFriends[index];
                      final name = friend['name']?.toString() ?? 'Sem nome';
                      final email = friend['email']?.toString();
                      final phone = friend['phone']?.toString();
                      final notes = friend['notes']?.toString();
                      final activeLoans = activeLoansCount(friend);

                      return _FriendCard(
                        initials: initialsFromName(name),
                        name: name,
                        email: email,
                        phone: phone,
                        notes: notes,
                        activeLoans: activeLoans,
                        onTap: () {
                          openEditFriendSheet(friend);
                        },
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavigation(currentIndex: 1),
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
              'Amigos',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Pessoas que pegam seus livros emprestados',
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
            onPressed: loadFriends,
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
        hintText: 'Buscar amigos...',
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

  Widget buildErrorState() {
    return _EmptyCard(
      icon: Icons.error_outline,
      title: 'Erro ao carregar amigos',
      description:
    'Erro ao carregar os dados locais.\nTente fechar e abrir o aplicativo novamente.\n\n$errorMessage',
     );
  }
}

class _FriendCard extends StatelessWidget {
  final String initials;
  final String name;
  final String? email;
  final String? phone;
  final String? notes;
  final int activeLoans;
  final VoidCallback onTap;

  const _FriendCard({
    required this.initials,
    required this.name,
    required this.email,
    required this.phone,
    required this.notes,
    required this.activeLoans,
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
              radius: 26,
              backgroundColor: AppColors.secondary,
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (email != null && email!.trim().isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      email!,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
                      ),
                    ),
                  ],
                  if (phone != null && phone!.trim().isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      phone!,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
                      ),
                    ),
                  ],
                  if (notes != null && notes!.trim().isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      notes!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$activeLoans ativos',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: Colors.grey[600],
                ),
              ],
            ),
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