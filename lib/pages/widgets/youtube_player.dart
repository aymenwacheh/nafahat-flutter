// lib/src/features/landing/presentation/widgets/youtube_player.dart
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';

class YouTubePlayer extends StatefulWidget {
  final String videoId;
  final String title;

  const YouTubePlayer({super.key, required this.videoId, required this.title});

  @override
  State<YouTubePlayer> createState() => _YouTubePlayerState();
}

class _YouTubePlayerState extends State<YouTubePlayer> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _createIframe();
    }
  }

  void _createIframe() {
    final String embedUrl =
        'https://www.youtube.com/embed/${widget.videoId}'
        '?autoplay=1'
        '&rel=0'
        '&showinfo=0'
        '&controls=1'
        '&modestbranding=1'
        '&playsinline=1'
        '&fs=1'
        '&cc_load_policy=0'
        '&iv_load_policy=3';

    // ✅ Créer un conteneur div pour l'iframe
    final container =
        html.DivElement()
          ..id = 'youtube_container_${widget.videoId}'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.position = 'relative'
          ..style.backgroundColor = 'black';

    // ✅ Créer l'iframe
    final iframe =
        html.IFrameElement()
          ..src = embedUrl
          ..width = '100%'
          ..height = '100%'
          ..style.border = 'none'
          ..allowFullscreen = true
          ..style.backgroundColor = 'black';

    // ✅ Ajouter un écouteur pour le chargement
    iframe.onLoad.listen((event) {
      setState(() {
        _isLoading = false;
      });
    });

    // ✅ Ajouter l'iframe au conteneur
    container.children.add(iframe);

    // ✅ Ajouter le conteneur au body
    html.document.body?.append(container);
  }

  @override
  void dispose() {
    if (kIsWeb) {
      final container = html.document.getElementById(
        'youtube_container_${widget.videoId}',
      );
      container?.remove();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 60),
              const SizedBox(height: 16),
              Text(
                'Lecteur vidéo disponible uniquement sur Web',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: Colors.black,
      child:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xffd57653),
                  strokeWidth: 3,
                ),
              )
              : const SizedBox.expand(),
    );
  }
}
