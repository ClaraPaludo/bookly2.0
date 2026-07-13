import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class ExpandableFriendCard extends StatefulWidget {
  final String initials;
  final String name;
  final String email;
  final String book;
  final String dueDate;

  const ExpandableFriendCard({
    super.key,
    required this.initials,
    required this.name,
    required this.email,
    required this.book,
    required this.dueDate,
  });

  @override
  State<ExpandableFriendCard> createState() => _ExpandableFriendCardState();
}

class _ExpandableFriendCardState extends State<ExpandableFriendCard> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.card,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.secondary,
              child: Text(
                widget.initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              widget.name,
              style: TextStyle(
                color: AppTheme.title,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              widget.email,
              style: TextStyle(color: AppTheme.subtitle),
            ),
            trailing: IconButton(
              icon: Icon(
                expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              ),
              onPressed: () {
                setState(() {
                  expanded = !expanded;
                });
              },
            ),
          ),

          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),

                  Row(
                    children: [
                      Icon(Icons.menu_book, color: AppTheme.secondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.book,
                          style: TextStyle(color: AppTheme.title),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: AppTheme.secondary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.dueDate,
                        style: TextStyle(color: AppTheme.subtitle),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
