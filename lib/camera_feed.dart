import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    // Get the list of available cameras
    availableCameras().then((cameras) {
      // Select the front camera
      _controller = CameraController(cameras[0], ResolutionPreset.medium);
      // Initialize the camera controller
      _initializeControllerFuture = _controller.initialize();
      // Start streaming the camera feed
      _initializeControllerFuture.then((_) {
        if (!mounted) {
          return;
        }
        setState(() {});
      });
    });
  }

  @override
  void dispose() {
    // Dispose of the camera controller when the widget is disposed
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return Container();
    }
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: ClipRRect(
            borderRadius:
                BorderRadius.circular(16.0), // Set the border radius as needed
            child: CameraPreview(_controller),
          ),
        ),
      ),
    );
  }
}
