import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/app_colors.dart';
import '../services/loans_service.dart';

class LoanDetailPage extends StatefulWidget {
  final String loanId;

  const LoanDetailPage({super.key, required this.loanId});

  @override
  State<LoanDetailPage> createState() => _LoanDetailPageState();
}

class _LoanDetailPageState extends State<LoanDetailPage> {
  bool isLoading = true;
  bool isUpdating = false;
  String? errorMessage;

  Map<String, dynamic>? loan;

  final ImagePicker picker = ImagePicker();

  // Guardam imagens novas escolhidas pelo usuário.
  // Se ficarem nulas, usamos as imagens que já estão no banco.
  Uint8List? beforeImageBytes;
  Uint8List? afterImageBytes;

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
        beforeImageBytes = null;
        afterImageBytes = null;
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

  Future<void> pickPhoto({required bool isBefore}) async {
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image == null) return;

    final bytes = await image.readAsBytes();

    setState(() {
      if (isBefore) {
        beforeImageBytes = bytes;
      } else {
        afterImageBytes = bytes;
      }
    });
  }

  String? imageToBase64(Uint8List? bytes) {
    if (bytes == null) return null;
    return 'data:image/png;base64,${base64Encode(bytes)}';
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

  Future<void> savePhotosOnly() async {
    final hasNewBefore = beforeImageBytes != null;
    final hasNewAfter = afterImageBytes != null;

    if (!hasNewBefore && !hasNewAfter) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhuma foto nova foi selecionada.')),
      );
      return;
    }

    setState(() {
      isUpdating = true;
    });

    try {
      await LoansService.updateLoanPhotos(
        id: widget.loanId,
        beforePhotoUrl: imageToBase64(beforeImageBytes),
        afterPhotoUrl: imageToBase64(afterImageBytes),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fotos atualizadas com sucesso!')),
      );

      await loadLoan();

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      showError('Erro ao salvar fotos: $error');
    } finally {
      if (mounted) {
        setState(() {
          isUpdating = false;
        });
      }
    }
  }

  Future<void> askBeforeReturn() async {
    final option = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Devolver livro'),
          content: const Text(
            'Deseja adicionar uma foto de como o livro voltou antes de marcar como devolvido?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'cancel'),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'without_photo'),
              child: const Text('Marcar sem foto'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, 'with_photo'),
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text('Adicionar foto'),
            ),
          ],
        );
      },
    );

    if (option == 'cancel' || option == null) return;

    if (option == 'with_photo') {
      await pickPhoto(isBefore: false);

      // Se a pessoa cancelou a escolha da imagem, não marca como devolvido.
      if (afterImageBytes == null) return;
    }

    await markAsReturned();
  }

  Future<void> markAsReturned() async {
    setState(() {
      isUpdating = true;
    });

    try {
      // Se escolheu foto depois, ela é salva junto com a devolução.
      await LoansService.markLoanAsReturned(
        widget.loanId,
        afterPhotoUrl: imageToBase64(afterImageBytes),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Empréstimo marcado como devolvido!')),
      );

      await loadLoan();

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      showError('Erro ao marcar como devolvido: $error');
    } finally {
      if (mounted) {
        setState(() {
          isUpdating = false;
        });
      }
    }
  }

  void showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  String getVisualStatus(Map<String, dynamic> loanData) {
    final status = loanData['status']?.toString() ?? 'PENDING';

    if (status == 'RETURNED') return 'RETURNED';

    final dueDate = DateTime.tryParse(loanData['dueDate']?.toString() ?? '');
    if (dueDate == null) return status;

    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final dueOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);

    return dueOnly.isBefore(todayOnly) ? 'LATE' : 'PENDING';
  }

  String getStatusText(String status) {
    switch (status) {
      case 'RETURNED':
        return 'Devolvido';
      case 'LATE':
        return 'Atrasado';
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
      default:
        return Colors.orange;
    }
  }

  String formatDate(String? value) {
    final date = DateTime.tryParse(value ?? '');
    if (date == null) return 'Não informado';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String getDeadlineMessage(Map<String, dynamic> loanData) {
    final status = getVisualStatus(loanData);

    if (status == 'RETURNED') return 'Este livro já foi devolvido.';

    final dueDate = DateTime.tryParse(loanData['dueDate']?.toString() ?? '');
    if (dueDate == null) return 'Prazo não informado.';

    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final dueOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final days = dueOnly.difference(todayOnly).inDays;

    if (days < 0) return 'Atrasado há ${days.abs()} dia(s).';
    if (days == 0) return 'A devolução é hoje.';
    if (days == 1) return 'Falta 1 dia para a devolução.';

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
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
                ? buildErrorState()
                : loan == null
                    ? const Center(child: Text('Empréstimo não encontrado.'))
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
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          buildStatusCard(statusText, statusColor, loanData),
          const SizedBox(height: 14),
          buildBookCard(bookTitle, bookAuthor, bookCategory),
          const SizedBox(height: 14),
          buildFriendCard(friendName, friendEmail, friendPhone),
          const SizedBox(height: 14),
          buildDatesCard(loanData),
          const SizedBox(height: 14),
          buildPhotosCard(loanData),
          const SizedBox(height: 18),

          // Este botão permite editar fotos mesmo após a devolução.
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: isUpdating ? null : savePhotosOnly,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Salvar edição das fotos'),
            ),
          ),

          if (canReturn) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: isUpdating ? null : askBeforeReturn,
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
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget buildStatusCard(
    String statusText,
    Color statusColor,
    Map<String, dynamic> loanData,
  ) {
    final icon = statusText == 'Devolvido'
        ? Icons.check_circle_outline
        : statusText == 'Atrasado'
            ? Icons.warning_amber_rounded
            : Icons.schedule;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Icon(icon, color: statusColor, size: 40),
          const SizedBox(height: 8),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            getDeadlineMessage(loanData),
            textAlign: TextAlign.center,
            style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
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

  Widget buildPhotosCard(Map<String, dynamic> loanData) {
    final savedBefore =
        decodeBase64Image(loanData['beforePhotoUrl']?.toString());
    final savedAfter = decodeBase64Image(loanData['afterPhotoUrl']?.toString());

    final beforeToShow = beforeImageBytes ?? savedBefore;
    final afterToShow = afterImageBytes ?? savedAfter;

    return _InfoCard(
      title: 'Fotos do livro',
      icon: Icons.photo_camera_outlined,
      children: [
        Text(
          'As fotos podem ser editadas mesmo depois da devolução.',
          style: TextStyle(color: Colors.grey[700], fontSize: 13),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _LoanPhotoBox(
                title: 'Antes',
                imageBytes: beforeToShow,
                emptyText: 'Sem foto antes',
                icon: Icons.photo_outlined,
                onTap: () => pickPhoto(isBefore: true),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _LoanPhotoBox(
                title: 'Depois',
                imageBytes: afterToShow,
                emptyText: 'Sem foto depois',
                icon: Icons.assignment_turned_in_outlined,
                onTap: () => pickPhoto(isBefore: false),
              ),
            ),
          ],
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
              'Erro ao carregar os dados locais.\n\n$errorMessage',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _LoanPhotoBox extends StatelessWidget {
  final String title;
  final Uint8List? imageBytes;
  final String emptyText;
  final IconData icon;
  final VoidCallback onTap;

  const _LoanPhotoBox({
    required this.title,
    required this.imageBytes,
    required this.emptyText,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 7),
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            height: 130,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            clipBehavior: Clip.antiAlias,
            child: imageBytes == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: AppColors.primary, size: 32),
                      const SizedBox(height: 7),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          emptyText,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Toque para editar',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.memory(imageBytes!, fit: BoxFit.cover),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: double.infinity,
                          color: Colors.black.withValues(alpha: 0.45),
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: const Text(
                            'Toque para trocar',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
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
      padding: const EdgeInsets.all(16),
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
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 19,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
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
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}