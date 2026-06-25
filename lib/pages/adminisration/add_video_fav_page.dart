// lib/pages/adminisration/add_video_fav_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nafahat/models/video_model.dart';
import 'package:nafahat/services/video_service.dart';

class AddVideoFavPage extends StatefulWidget {
  const AddVideoFavPage({super.key});

  @override
  State<AddVideoFavPage> createState() => _AddVideoFavPageState();
}

class _AddVideoFavPageState extends State<AddVideoFavPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isArabic = false;
  bool _isActive = true;

  // Controllers
  final _titleFrController = TextEditingController();
  final _titleArController = TextEditingController();
  final _descriptionFrController = TextEditingController();
  final _descriptionArController = TextEditingController();
  final _videoIdController = TextEditingController();

  static const Color nafahatGreen = Color(0xff0D443E);

  @override
  void dispose() {
    _titleFrController.dispose();
    _titleArController.dispose();
    _descriptionFrController.dispose();
    _descriptionArController.dispose();
    _videoIdController.dispose();
    super.dispose();
  }

  Future<void> _saveVideo() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final newVideo = VideoModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        titleFr: _titleFrController.text,
        titleAr: _titleArController.text,
        descriptionFr: _descriptionFrController.text,
        descriptionAr: _descriptionArController.text,
        videoId: _videoIdController.text,
        thumbnailUrl: '', // Généré automatiquement
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: _isActive,
      );

      final success = await VideoService.createVideo(newVideo);

      setState(() => _isLoading = false);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isArabic
                    ? 'تمت إضافة الفيديو بنجاح!'
                    : 'Vidéo ajoutée avec succès!',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de l\'ajout de la vidéo'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(_isArabic ? 'إضافة فيديو' : 'Ajouter une vidéo'),
        backgroundColor: nafahatGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () => setState(() => _isArabic = !_isArabic),
            tooltip: _isArabic ? 'Français' : 'العربية',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isMobile),
              const SizedBox(height: 24),

              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 16 : 24),
                  child: Column(
                    children: [
                      // ✅ Titre Français
                      _buildTextField(
                        controller: _titleFrController,
                        label:
                            _isArabic
                                ? 'العنوان (بالفرنسية)'
                                : 'Titre (Français)',
                        hint:
                            _isArabic
                                ? 'مثال: Tutoriel Flutter'
                                : 'Ex: Tutoriel Flutter',
                        icon: Icons.title,
                        isRequired: true,
                      ),
                      const SizedBox(height: 16),

                      // ✅ Titre Arabe
                      _buildTextField(
                        controller: _titleArController,
                        label:
                            _isArabic ? 'العنوان (بالعربية)' : 'Titre (Arabe)',
                        hint: _isArabic ? 'مثال: شرح فلاتر' : 'Ex: شرح فلاتر',
                        icon: Icons.title,
                        isRequired: true,
                        isArabicText: true,
                      ),
                      const SizedBox(height: 16),

                      // ✅ Description Français
                      _buildTextField(
                        controller: _descriptionFrController,
                        label:
                            _isArabic
                                ? 'الوصف (بالفرنسية)'
                                : 'Description (Français)',
                        hint:
                            _isArabic
                                ? 'وصف مختصر للفيديو'
                                : 'Description courte de la vidéo',
                        icon: Icons.description,
                        maxLines: 3,
                        isRequired: true,
                      ),
                      const SizedBox(height: 16),

                      // ✅ Description Arabe
                      _buildTextField(
                        controller: _descriptionArController,
                        label:
                            _isArabic
                                ? 'الوصف (بالعربية)'
                                : 'Description (Arabe)',
                        hint:
                            _isArabic
                                ? 'وصف مختصر للفيديو'
                                : 'Description courte en arabe',
                        icon: Icons.description,
                        maxLines: 3,
                        isRequired: true,
                        isArabicText: true,
                      ),
                      const SizedBox(height: 16),

                      // ✅ ID YouTube
                      _buildTextField(
                        controller: _videoIdController,
                        label:
                            _isArabic ? 'معرف الفيديو (YouTube)' : 'ID YouTube',
                        hint:
                            _isArabic ? 'مثال: dQw4w9WgXcQ' : 'Ex: dQw4w9WgXcQ',
                        icon: Icons.video_library,
                        isRequired: true,
                        helperText:
                            _isArabic
                                ? 'أدخل المعرف من رابط YouTube'
                                : 'Entrez l\'ID depuis l\'URL YouTube',
                      ),
                      const SizedBox(height: 16),

                      // ✅ Aperçu
                      if (_videoIdController.text.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(),
                            Text(
                              _isArabic
                                  ? 'معاينة الفيديو'
                                  : 'Aperçu de la vidéo',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: nafahatGreen,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                'https://img.youtube.com/vi/${_videoIdController.text}/hqdefault.jpg',
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 150,
                                    width: double.infinity,
                                    color: Colors.grey[200],
                                    child: const Icon(
                                      Icons.video_library_outlined,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 16),

                      // ✅ Actif
                      SwitchListTile(
                        value: _isActive,
                        onChanged: (value) => setState(() => _isActive = value),
                        title: Text(
                          _isArabic ? 'تفعيل الفيديو' : 'Activer la vidéo',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        activeColor: nafahatGreen,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ✅ Boutons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(_isArabic ? 'إلغاء' : 'Annuler'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveVideo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: nafahatGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child:
                          _isLoading
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : Text(_isArabic ? 'إضافة' : 'Ajouter'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            nafahatGreen.withOpacity(0.05),
            const Color(0xffd57653).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: nafahatGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.video_library, color: nafahatGreen, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isArabic ? 'فيديو جديد' : 'Nouvelle vidéo',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: nafahatGreen,
                  ),
                ),
                Text(
                  _isArabic
                      ? 'أضف فيديو جديد إلى قائمة المفضلة'
                      : 'Ajoutez une nouvelle vidéo à la liste favorite',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    bool isRequired = false,
    bool isArabicText = false,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: nafahatGreen),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: nafahatGreen,
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          textDirection: isArabicText ? TextDirection.rtl : TextDirection.ltr,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
            helperText: helperText,
            helperStyle: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.grey[500],
            ),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: nafahatGreen, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          validator: (value) {
            if (isRequired && (value == null || value.isEmpty)) {
              return _isArabic ? 'حقل مطلوب' : 'Champ requis';
            }
            if (controller == _videoIdController &&
                value != null &&
                value.isNotEmpty &&
                value.contains('/')) {
              return _isArabic
                  ? 'يرجى إدخال المعرف فقط، وليس الرابط الكامل'
                  : 'Veuillez entrer uniquement l\'ID, pas l\'URL complète';
            }
            return null;
          },
        ),
      ],
    );
  }
}
