import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

class ImageViewerScreen extends StatelessWidget {
  final List<Map<String, dynamic>> imageDetailsList;
  final int initialIndex;

  ImageViewerScreen({required this.imageDetailsList, this.initialIndex = 0});

  @override
  Widget build(BuildContext context) {
    PageController pageController = PageController(initialPage: initialIndex);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.black,
        title: Text("Image Viewer",style: TextStyle(color: Colors.white),),
      ),
      body: PageView.builder(
        controller: pageController,
        itemCount: imageDetailsList.length,
        itemBuilder: (context, index) {
          final image = imageDetailsList[index];
          Map<String, dynamic> fileDetails = jsonDecode(image['content']);
          String filePath = fileDetails['path'];

          return AnimatedBuilder(
            animation: pageController,
            builder: (context, child) {
              double scale = 1.0;
              if (pageController.position.haveDimensions) {
                scale = pageController.page == index
                    ? 1.0
                    : (1 - (pageController.page! - index).abs() * 0.2)
                    .clamp(0.8, 1.0);
              }
              return Transform.scale(
                scale: scale,
                child: InteractiveViewer(
                  child: filePath.isNotEmpty
                      ? Image.file(
                    File(filePath),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Text('Failed to load image'),
                    ),
                  )
                      : Center(child: Text('Invalid file path')),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
