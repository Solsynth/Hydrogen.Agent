import 'package:flutter/material.dart';

class AttachmentScreen extends StatelessWidget {
  final String tag;
  final String url;

  const AttachmentScreen({super.key, required this.tag, required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        child: Center(
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: InteractiveViewer(
              boundaryMargin: const EdgeInsets.all(128),
              minScale: 0.1,
              maxScale: 16.0,
              child: Hero(
                tag: tag,
                child: Image.network(url, fit: BoxFit.contain),
              ),
            ),
          ),
        ),
        onTap: () {
          Navigator.pop(context);
        },
      ),
    );
  }
}
