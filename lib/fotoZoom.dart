import 'package:flutter/material.dart';

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
              child: Image.network(
                publicUrl,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
