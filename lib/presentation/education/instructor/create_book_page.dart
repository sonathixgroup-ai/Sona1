// lib/presentation/education/instructor/create_book_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _C {
  static const bg = Color(0xFFF8FAFC);
  static const surface = Colors.white;
  static const primary = Color(0xFF2D6CDF);
  static const textMain = Color(0xFF1E293B);
  static const textMuted = Color(0xFF7386A8);
  static const border = Color(0xFFE2E8F0);
  static const red = Color(0xFFEF4444);
  static const green = Color(0xFF2ECC71);
}

class CreateBookPage extends ConsumerStatefulWidget {
  final String? bookId;
  const CreateBookPage({super.key, this.bookId});

  @override
  ConsumerState<CreateBookPage> createState() => _CreateBookPageState();
}

class _CreateBookPageState extends ConsumerState<CreateBookPage> {
  final _formKey = GlobalKey<FormState>();
  
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _fileUrlController = TextEditingController();
  
  String _selectedCurrency = 'FC'; // ✅ Devise par défaut
  bool _isLoading = false;
  bool _isInitLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.bookId != null) {
      _loadExistingBook();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    _fileUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingBook() async {
    setState(() => _isInitLoading = true);
    try {
      final data = await Supabase.instance.client
          .from('books')
          .select()
          .eq('id', widget.bookId!)
          .single();

      if (mounted) {
        _titleController.text = data['title']?.toString() ?? '';
        _authorController.text = data['author']?.toString() ?? '';
        _descriptionController.text = data['description']?.toString() ?? '';
        _priceController.text = data['price']?.toString() ?? '0';
        _selectedCurrency = data['currency']?.toString() ?? 'FC'; // ✅ Chargement de la devise
        _imageUrlController.text = data['image_url']?.toString() ?? '';
        _fileUrlController.text = data['file_url']?.toString() ?? '';
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement livre : $e');
    } finally {
      if (mounted) setState(() => _isInitLoading = false);
    }
  }

  Future<void> _saveBook() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('Utilisateur non connecté.');

      final payload = {
        'title': _titleController.text.trim(),
        'author': _authorController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
        'currency': _selectedCurrency, // ✅ Enregistrement de la devise choisie
        'image_url': _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
        'file_url': _fileUrlController.text.trim().isEmpty ? null : _fileUrlController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (widget.bookId == null) {
        payload['instructor_id'] = userId;
        payload['created_at'] = DateTime.now().toIso8601String();
        await Supabase.instance.client.from('books').insert(payload);
      } else {
        await Supabase.instance.client.from('books').update(payload).eq('id', widget.bookId!);
      }

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.bookId == null ? 'Livre publié avec succès !' : 'Livre mis à jour !'),
          backgroundColor: _C.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'), backgroundColor: _C.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.bookId != null;

    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier le livre' : 'Ajouter un livre', style: const TextStyle(fontWeight: FontWeight.w800, color: _C.textMain, fontSize: 18)),
        backgroundColor: _C.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _C.textMain),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isInitLoading
          ? const Center(child: CircularProgressIndicator(color: _C.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _C.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _C.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Informations générales', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _C.textMain)),
                          const SizedBox(height: 16),
                          
                          _buildTextField(
                            controller: _titleController,
                            label: 'Titre du livre',
                            icon: Icons.title_rounded,
                            validator: (v) => v!.trim().isEmpty ? 'Requis' : null,
                          ),
                          const SizedBox(height: 16),
                          
                          _buildTextField(
                            controller: _authorController,
                            label: 'Auteur',
                            icon: Icons.person_outline_rounded,
                            validator: (v) => v!.trim().isEmpty ? 'Requis' : null,
                          ),
                          const SizedBox(height: 16),
                          
                          _buildTextField(
                            controller: _descriptionController,
                            label: 'Description',
                            icon: Icons.description_outlined,
                            maxLines: 4,
                          ),
                          const SizedBox(height: 16),
                          
                          // Ligne Prix et Devise dynamique
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: _buildTextField(
                                  controller: _priceController,
                                  label: 'Prix',
                                  icon: Icons.payments_outlined,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  hintText: '0',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 1,
                                child: DropdownButtonFormField<String>(
                                  value: _selectedCurrency,
                                  dropdownColor: _C.surface,
                                  style: const TextStyle(color: _C.textMain, fontWeight: FontWeight.w600),
                                  items: const [
                                    DropdownMenuItem(value: 'FC', child: Text('FC')),
                                    DropdownMenuItem(value: 'USD', child: Text('USD')),
                                    DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                                  ],
                                  onChanged: (v) => setState(() => _selectedCurrency = v!),
                                  decoration: _inputDecoration('Devise', Icons.货币_exchange_outlined), // ou autre icône adaptée
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _C.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _C.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Médias & Fichiers', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _C.textMain)),
                          const SizedBox(height: 16),
                          
                          _buildTextField(
                            controller: _imageUrlController,
                            label: 'Lien de la couverture (URL Image)',
                            icon: Icons.image_outlined,
                          ),
                          const SizedBox(height: 16),
                          
                          _buildTextField(
                            controller: _fileUrlController,
                            label: 'Lien du fichier (URL PDF)',
                            icon: Icons.picture_as_pdf_outlined,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveBook,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _C.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isLoading
                            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(isEditing ? 'Mettre à jour' : 'Publier le livre', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    String? hintText,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: const TextStyle(color: _C.textMain, fontWeight: FontWeight.w500),
      decoration: _inputDecoration(label, icon, hintText: hintText),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, {String? hintText}) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      labelStyle: const TextStyle(color: _C.textMuted, fontWeight: FontWeight.w500),
      prefixIcon: Icon(icon, color: _C.textMuted, size: 20),
      filled: true,
      fillColor: _C.bg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.transparent)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _C.primary, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _C.red, width: 1.0)),
    );
  }
}
