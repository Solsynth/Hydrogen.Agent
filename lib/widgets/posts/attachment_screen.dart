import 'package:flutter/material.dart';

class AttachmentScreen extends StatelessWidget {
  final String url;
  final String? tag;

  const AttachmentScreen({super.key, this.tag, required this.url});

  @override
  Widget build(BuildContext context) {
    final image = SizedBox(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: InteractiveViewer(
        boundaryMargin: const EdgeInsets.all(128),
        minScale: 0.1,
        maxScale: 16.0,
        child: Image.network(url, fit: BoxFit.contain),
      ),
    );

    return Scaffold(
      body: GestureDetector(
        child: Center(
          child: tag != null ? Hero(tag: tag!, child: image) : image,
        ),
        onTap: () {
          Navigator.pop(context);
        },
      ),
    );
  }
}
