// lib/pages/videos/video_detail_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nafahat/models/video_model.dart';
import 'package:nafahat/services/video_service.dart';

class VideoDetailPage extends StatefulWidget {
  final String videoId;

  const VideoDetailPage({super.key, required this.videoId});

  @override
  State<VideoDetailPage> createState() => _VideoDetailPageState();
}

class _VideoDetailPageState extends State<VideoDetailPage> {
  VideoModel? _video;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  Future<void> _loadVideo() async {
    try {
      final videos = await VideoService.getVideos();
      final found = videos.firstWhere(
        (v) => v.id.toString() == widget.videoId,
        orElse: () => throw Exception('Vidéo non trouvée'),
      );
      setState(() {
        _video = found;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_video?.titleFr ?? 'Détail vidéo'),
        backgroundColor: const Color(0xffd57653),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _video == null
              ? const Center(child: Text('Vidéo non trouvée'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Afficher la vidéo ici
                      Text(
                        _video!.titleFr,
                        style: GoogleFonts.cairo(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _video!.descriptionFr ?? '',
                        style: GoogleFonts.cairo(fontSize: 16),
                      ),
                    ],
                  ),
                ),
    );
  }
}