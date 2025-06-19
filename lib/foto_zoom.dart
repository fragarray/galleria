import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FotoZoom extends StatelessWidget {
  const FotoZoom({super.key, required this.publicUrl});
  final String publicUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        onDoubleTap: () => Navigator.pop(context),
        child: Center(
          child: Hero(
            tag: num,
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 8.0,
              child: CachedNetworkImage(
                imageUrl: publicUrl,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                placeholder: (context, url) =>
                    const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
