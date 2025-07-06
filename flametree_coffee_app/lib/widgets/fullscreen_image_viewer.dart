import 'package:flutter/material.dart';

class FullscreenImageViewer extends StatelessWidget {
  final String imagePath;
  final String heroTag;

  const FullscreenImageViewer({
    super.key,
    required this.imagePath,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          '手绘菜单',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: Hero(
          tag: heroTag,
          child: InteractiveViewer(
            panEnabled: true,
            boundaryMargin: const EdgeInsets.all(20),
            minScale: 0.5,
            maxScale: 4.0,
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).pop(),
        backgroundColor: const Color(0xFFFF8C42),
        child: const Icon(Icons.close, color: Colors.white),
      ),
    );
  }
}