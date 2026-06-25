import 'package:flutter/material.dart';
import 'package:nafahat/src/features/landing/presentation/landing_page.dart' show AppColors;

class EditProfilePage extends StatefulWidget {
  final bool isArabic;
  const EditProfilePage({super.key, required this.isArabic});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  
  // Remplissage initial avec les fausses données courantes de l'utilisateur
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: "Amine Ben Ali");
    _phoneController = TextEditingController(text: "+216 55 123 456");
    _emailController = TextEditingController(text: "amine.ba@ertiqa.com");
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      // Logique de mise à jour (bientôt via l'API)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isArabic ? "تم تحديث الحساب بنجاح" : "Profil mis à jour avec succès !"),
          backgroundColor: AppColors.primaryDark,
        ),
      );
      Navigator.pop(context); // Retour au Dashboard
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          title: Text(
            widget.isArabic ? "تعديل الحساب" : "Modifier le profil",
            style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textDark),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.primary.withOpacity(0.08)),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Avatar modifiable (Visuel)
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            child: const Icon(Icons.person_rounded, size: 55, color: AppColors.primary),
                          ),
                          Positioned(
                            bottom: 0,
                            right: widget.isArabic ? null : 0,
                            left: widget.isArabic ? 0 : null,
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.primary,
                              child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 35),

                    // Champ Nom
                    _buildEditField(
                      controller: _nameController,
                      labelFr: "Nom et Prénom",
                      labelAr: "الاسم واللقب",
                      icon: Icons.person_outline_rounded,
                      validator: (v) => v!.isEmpty ? "Champ requis" : null,
                    ),
                    const SizedBox(height: 20),

                    // Champ Téléphone
                    _buildEditField(
                      controller: _phoneController,
                      labelFr: "Numéro de téléphone",
                      labelAr: "رقم الهاتف",
                      icon: Icons.phone_android_rounded,
                      keyboardType: TextInputType.phone,
                      validator: (v) => v!.isEmpty ? "Champ requis" : null,
                    ),
                    const SizedBox(height: 20),

                    // Champ Email
                    _buildEditField(
                      controller: _emailController,
                      labelFr: "Adresse E-mail",
                      labelAr: "البريد الإلكتروني",
                      icon: Icons.alternate_email_rounded,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => !v!.contains('@') ? "E-mail invalide" : null,
                    ),
                    const SizedBox(height: 20),

                    // Champ Mot de passe (Optionnel pour modification)
                    _buildEditField(
                      controller: _passwordController,
                      labelFr: "Nouveau mot de passe (optionnel)",
                      labelAr: "كلمة مرور جديدة (اختياري)",
                      icon: Icons.lock_outline_rounded,
                      isPassword: true,
                      validator: (v) => (v!.isNotEmpty && v.length < 6) ? "6 caractères minimum" : null,
                    ),
                    const SizedBox(height: 40),

                    // Bouton Enregistrer
                    ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Text(
                        widget.isArabic ? "حفظ التغييرات" : "Enregistrer les modifications",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditField({
    required TextEditingController controller,
    required String labelFr,
    required String labelAr,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    required String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: AppColors.textDark, fontSize: 15),
      decoration: InputDecoration(
        labelText: widget.isArabic ? labelAr : labelFr,
        labelStyle: const TextStyle(color: AppColors.textMuted),
        prefixIcon: Icon(icon, color: AppColors.primary.withOpacity(0.6), size: 20),
        filled: true,
        fillColor: AppColors.primary.withOpacity(0.01),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.primary.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}