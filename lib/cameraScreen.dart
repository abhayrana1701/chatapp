import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CameraWithSwitcher extends StatefulWidget {
  @override
  _CameraWithSwitcherState createState() => _CameraWithSwitcherState();
}

class _CameraWithSwitcherState extends State<CameraWithSwitcher> {
  final ImagePicker _picker = ImagePicker();
  bool isVideoMode = false; // To track the current mode

  // Method to pick image or video based on the current mode
  Future<void> _pickMedia() async {
    final pickedFile = isVideoMode
        ? await _picker.pickVideo(source: ImageSource.camera)
        : await _picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      // Handle the selected image or video
      print('Selected file: ${pickedFile.path}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Camera preview background
          Center(
            child: Text('Camera preview here'), // Placeholder for camera preview
          ),
          // Bottom buttons to switch modes
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isVideoMode = false; // Switch to image mode
                    });
                    _pickMedia(); // Trigger the media picker
                  },
                  child: Text('Image'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isVideoMode ? Colors.grey : Colors.blue,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isVideoMode = true; // Switch to video mode
                    });
                    _pickMedia(); // Trigger the media picker
                  },
                  child: Text('Video'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isVideoMode ? Colors.blue : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

