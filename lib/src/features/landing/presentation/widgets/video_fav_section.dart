// lib/src/features/landing/presentation/widgets/video_fav_section.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nafahat/models/video_model.dart';
import 'package:nafahat/services/video_service.dart';
import 'package:nafahat/src/features/landing/presentation/widgets/youtube_player.dart';
// ✅ Import du lecteur YouTube

class VideoFavSection extends StatefulWidget {
  final bool isArabic;

  const VideoFavSection({super.key, required this.isArabic});

  @override
  State<VideoFavSection> createState() => _VideoFavSectionState();
}

class _VideoFavSectionState extends State<VideoFavSection> {
  List<VideoModel> _videos = [];
  bool _isLoading = true;
  final PageController _pageController = PageController();
  int _currentPage = 0;
  int _itemsPerPage = 3;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> refreshVideos() async {
    await _loadVideos();
  }

  Future<void> _loadVideos() async {
    setState(() => _isLoading = true);
    try {
      final videos = await VideoService.getVideos();
      print('📹 Vidéos reçues: ${videos.length}');

      setState(() {
        _videos = videos.where((v) => v.isActive).toList();
        _isLoading = false;
        _currentPage = 0;
      });

      print('📹 Vidéos actives: ${_videos.length}');
    } catch (e) {
      print('❌ Erreur _loadVideos: $e');
      setState(() {
        _videos = [];
        _isLoading = false;
      });
    }
  }

  int get _totalPages =>
      _videos.isEmpty ? 0 : (_videos.length / _itemsPerPage).ceil();

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      setState(() => _currentPage++);
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      setState(() => _currentPage--);
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;

    _itemsPerPage = isMobile ? 1 : (isTablet ? 2 : 3);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.isArabic ? '⭐ فيديوهات مميزة' : '⭐ Vidéos Favorites',
                style: GoogleFonts.poppins(
                  fontSize: isMobile ? 20 : 24,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xff994a2b),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Color(0xffd57653)),
                    onPressed: refreshVideos,
                    tooltip: widget.isArabic ? 'تحديث' : 'Rafraîchir',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Contenu
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(color: Color(0xffd57653)),
              ),
            )
          else if (_videos.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(
                      Icons.video_library_outlined,
                      size: 60,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.isArabic
                          ? 'لا توجد فيديوهات حالياً'
                          : 'Aucune vidéo disponible',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[500],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.isArabic
                          ? 'أضف فيديو من لوحة الإدارة'
                          : 'Ajoutez une vidéo depuis le panneau d\'administration',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            _buildVideoCarousel(isMobile, screenWidth),
        ],
      ),
    );
  }

  Widget _buildVideoCarousel(bool isMobile, double screenWidth) {
    return Column(
      children: [
        // Carrousel
        SizedBox(
          height: isMobile ? 320 : 380,
          child:
              _totalPages > 1
                  ? PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    children: List.generate(_totalPages, (pageIndex) {
                      final start = pageIndex * _itemsPerPage;
                      final end = start + _itemsPerPage;
                      final pageItems = _videos.sublist(
                        start,
                        end > _videos.length ? _videos.length : end,
                      );

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          children:
                              pageItems.map((video) {
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: _VideoCard(
                                      video: video,
                                      isArabic: widget.isArabic,
                                      isMobile: isMobile,
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      );
                    }),
                  )
                  : Row(
                    children:
                        _videos.map((video) {
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: _VideoCard(
                                video: video,
                                isArabic: widget.isArabic,
                                isMobile: isMobile,
                              ),
                            ),
                          );
                        }).toList(),
                  ),
        ),

        // Indicateurs de pagination
        if (_totalPages > 1)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _prevPage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          _currentPage > 0
                              ? const Color(0xffd57653)
                              : Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.isArabic ? Icons.arrow_forward : Icons.arrow_back,
                      color: _currentPage > 0 ? Colors.white : Colors.grey[600],
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Row(
                  children: List.generate(_totalPages, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            _currentPage == index
                                ? const Color(0xffd57653)
                                : Colors.grey[300],
                      ),
                    );
                  }),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: _nextPage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          _currentPage < _totalPages - 1
                              ? const Color(0xffd57653)
                              : Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.isArabic ? Icons.arrow_back : Icons.arrow_forward,
                      color:
                          _currentPage < _totalPages - 1
                              ? Colors.white
                              : Colors.grey[600],
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// --- CARTE VIDÉO ---
class _VideoCard extends StatefulWidget {
  final VideoModel video;
  final bool isArabic;
  final bool isMobile;

  const _VideoCard({
    required this.video,
    required this.isArabic,
    required this.isMobile,
  });

  @override
  State<_VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<_VideoCard> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTap: () => _showVideoDialog(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          transform:
              isHovered && !widget.isMobile
                  ? Matrix4.translationValues(0.0, -8.0, 0.0)
                  : Matrix4.identity(),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHovered ? const Color(0xffd57653) : Colors.grey[200]!,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    isHovered
                        ? const Color(0xffd57653).withOpacity(0.15)
                        : Colors.black.withOpacity(0.05),
                blurRadius: isHovered ? 20 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Miniature
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Stack(
                  children: [
                    Image.network(
                      widget.video.youtubeThumbnail,
                      height: widget.isMobile ? 180 : 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: widget.isMobile ? 180 : 220,
                          width: double.infinity,
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xffd57653),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: widget.isMobile ? 180 : 220,
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
                    // ✅ Bouton play avec animation améliorée
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color:
                                isHovered
                                    ? const Color(0xffd57653).withOpacity(0.9)
                                    : Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.play_arrow_rounded,
                            color:
                                isHovered
                                    ? Colors.white
                                    : const Color(0xffd57653),
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                    // Nombre de vues
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.visibility,
                              color: Colors.white,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.video.views}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Contenu
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.video.getTitle(widget.isArabic),
                      style: GoogleFonts.poppins(
                        fontSize: widget.isMobile ? 13 : 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xff2c221e),
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.video.getDescription(widget.isArabic),
                      style: GoogleFonts.poppins(
                        fontSize: widget.isMobile ? 10 : 11,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey[600],
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Nouvelle méthode avec lecteur YouTube intégré
  void _showVideoDialog() {
    // ✅ Incrémenter les vues
    VideoService.incrementViews(widget.video.id);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.95,
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // ✅ Barre de contrôle personnalisée
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.95),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.video.getTitle(widget.isArabic),
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // ✅ Bouton ouvrir sur YouTube
                        IconButton(
                          icon: const Icon(
                            Icons.open_in_new,
                            color: Colors.white70,
                            size: 20,
                          ),
                          onPressed: () {
                            // TODO: Ouvrir sur YouTube avec url_launcher
                            // launchUrl(Uri.parse(widget.video.youtubeUrl));
                          },
                          tooltip: 'Ouvrir sur YouTube',
                        ),
                      ],
                    ),
                  ),

                  // ✅ Lecteur YouTube intégré
                  Expanded(
                    child: YouTubePlayer(
                      videoId: widget.video.videoId,
                      title: widget.video.getTitle(widget.isArabic),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
