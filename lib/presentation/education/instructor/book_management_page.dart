// lib/presentation/education/instructor/book_management_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BookManagementPage extends StatefulWidget {
  const BookManagementPage({super.key});

  @override
  State<BookManagementPage> createState() => _BookManagementPageState();
}

class _BookManagementPageState extends State<BookManagementPage> {
  List<Map<String, dynamic>> _books = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    // TODO: charger les livres depuis Supabase (table books)
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _books = []; // remplacer par les données réelles
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Mes livres'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.push('/instructor/books/create'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _books.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.library_books_rounded, size: 64, color: Color(0xFFD1D5DB)),
                      SizedBox(height: 16),
                      Text(
                        'Aucun livre',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Ajoutez votre premier livre',
                        style: TextStyle(color: Color(0xFF7386A8)),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _books.length,
                  itemBuilder: (context, index) {
                    final book = _books[index];
                    return Card(
                      child: ListTile(
                        title: Text(book['title'] ?? 'Sans titre'),
                        subtitle: Text(book['author'] ?? 'Auteur inconnu'),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit_rounded),
                          onPressed: () => context.push('/instructor/books/edit/${book['id']}'),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
