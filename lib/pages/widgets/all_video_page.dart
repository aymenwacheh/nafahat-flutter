// lib/pages/landing/widgets/all_video_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:nafahat/providers/language_provider.dart';
import 'package:nafahat/pages/widgets/video_fav_section.dart';

class AllVideoPage extends StatefulWidget {
  const AllVideoPage({super.key});

  @override
  State<AllVideoPage> createState() => _AllVideoPageState();
}

class _AllVideoPageState extends State<AllVideoPage> {
  @override
  Widget build(BuildContext context) {
    final isArabic = Provider.of<LanguageProvider>(context).isArabic;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isArabic ? 'جميع الفيديوهات المميزة' : 'Toutes les vidéos favorites',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 18 : 22,
          ),
        ),
        backgroundColor: const Color(0xff0D443E),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {});
            },
            tooltip: isArabic ? 'تحديث' : 'Rafraîchir',
          ),
        ],
      ),
      body: Container(
        color: Colors.grey.shade50,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 12.0 : 24.0),
            child: _buildVideoGrid(isArabic, isMobile),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoGrid(bool isArabic, bool isMobile) {
    // Utiliser le même contenu que VideoFavSection mais en grille complète
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête avec le nombre de vidéos
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isArabic ? '📹 فيديوهات مميزة' : '📹 Vidéos favorites',
                style: GoogleFonts.cairo(
                  fontSize: isMobile ? 16 : 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xff0D443E),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xffC4A46C).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_getMockVideos().length} ${isArabic ? 'فيديو' : 'vidéos'}',
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 12 : 14,
                    color: const Color(0xff0D443E),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Grille de vidéos
        Expanded(
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isMobile ? 2 : (isMobile ? 2 : 4),
              crossAxisSpacing: isMobile ? 8 : 16,
              mainAxisSpacing: isMobile ? 8 : 16,
              childAspectRatio: 0.8,
            ),
            itemCount: _getMockVideos().length,
            itemBuilder: (context, index) {
              final video = _getMockVideos()[index];
              return _buildVideoCard(context, video, isArabic, isMobile);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVideoCard(
    BuildContext context,
    Map<String, dynamic> video,
    bool isArabic,
    bool isMobile,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Miniature de la vidéo
          Expanded(
            flex: 7,
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(isMobile ? 12 : 16),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    video['thumbnail'],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xff0D443E).withOpacity(0.1),
                        child: Icon(
                          Icons.video_library,
                          size: isMobile ? 30 : 50,
                          color: const Color(0xff0D443E).withOpacity(0.3),
                        ),
                      );
                    },
                  ),
                  // Overlay de lecture
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),
                  // Bouton play
                  Center(
                    child: Container(
                      width: isMobile ? 40 : 56,
                      height: isMobile ? 40 : 56,
                      decoration: BoxDecoration(
                        color: const Color(0xffC4A46C).withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: isMobile ? 24 : 32,
                      ),
                    ),
                  ),
                  // Badge durée
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        video['duration'] ?? '0:00',
                        style: GoogleFonts.cairo(
                          fontSize: isMobile ? 10 : 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Informations
          Expanded(
            flex: 3,
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 8.0 : 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isArabic ? video['titleAr'] : video['titleFr'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: isMobile ? 12 : 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xff2c221e),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          isArabic
                              ? video['channelAr'] ?? 'قناة'
                              : video['channelFr'] ?? 'Chaîne',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(
                            fontSize: isMobile ? 10 : 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xffd57653).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.visibility_outlined,
                          size: isMobile ? 12 : 14,
                          color: const Color(0xffd57653),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getMockVideos() {
    return [
      {
        'thumbnail': 'https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg',
        'titleFr': 'Introduction à la programmation Flutter',
        'titleAr': 'مقدمة في برمجة فلاتر',
        'duration': '12:30',
        'channelFr': 'Nafahat Academy',
        'channelAr': 'أكاديمية نفحات',
      },
      {
        'thumbnail': 'https://img.youtube.com/vi/5Y8Ak1uyveM/hqdefault.jpg',
        'titleFr': 'Développement mobile avancé',
        'titleAr': 'تطوير التطبيقات المتقدم',
        'duration': '18:45',
        'channelFr': 'Nafahat Academy',
        'channelAr': 'أكاديمية نفحات',
      },
      {
        'thumbnail': 'https://img.youtube.com/vi/7v8eu2m0KJg/hqdefault.jpg',
        'titleFr': 'UI/UX Design pour débutants',
        'titleAr': 'تصميم واجهات للمبتدئين',
        'duration': '22:15',
        'channelFr': 'Design Academy',
        'channelAr': 'أكاديمية التصميم',
      },
      {
        'thumbnail': 'https://img.youtube.com/vi/8Z2cMbVpPyo/hqdefault.jpg',
        'titleFr': 'Firebase pour Flutter',
        'titleAr': 'فايربيز مع فلاتر',
        'duration': '15:20',
        'channelFr': 'Nafahat Academy',
        'channelAr': 'أكاديمية نفحات',
      },
      {
        'thumbnail': 'https://img.youtube.com/vi/6Yd9lz3l8p4/hqdefault.jpg',
        'titleFr': 'Gestion d\'état avec Provider',
        'titleAr': 'إدارة الحالة مع Provider',
        'duration': '20:00',
        'channelFr': 'Nafahat Academy',
        'channelAr': 'أكاديمية نفحات',
      },
      {
        'thumbnail': 'https://img.youtube.com/vi/9Yd9lz3l8p4/hqdefault.jpg',
        'titleFr': 'Animation avancée dans Flutter',
        'titleAr': 'الأنيميشن المتقدم في فلاتر',
        'duration': '25:10',
        'channelFr': 'Flutter Masters',
        'channelAr': 'خبراء فلاتر',
      },
      {
        'thumbnail': 'https://img.youtube.com/vi/4Yd9lz3l8p4/hqdefault.jpg',
        'titleFr': 'REST API et HTTP',
        'titleAr': 'REST API و HTTP',
        'duration': '16:40',
        'channelFr': 'Nafahat Academy',
        'channelAr': 'أكاديمية نفحات',
      },
      {
        'thumbnail': 'https://img.youtube.com/vi/2Yd9lz3l8p4/hqdefault.jpg',
        'titleFr': 'Base de données SQLite',
        'titleAr': 'قاعدة البيانات SQLite',
        'duration': '14:55',
        'channelFr': 'Nafahat Academy',
        'channelAr': 'أكاديمية نفحات',
      },
    ];
  }
}
