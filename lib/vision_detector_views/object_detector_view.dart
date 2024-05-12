import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http; // Import the http package
import 'package:sound_wave/secrets.dart';

import 'detector_view.dart';
import 'painters/object_detector_painter.dart';
import 'utils.dart';

class ObjectDetectorView extends StatefulWidget {
  const ObjectDetectorView({super.key});

  @override
  State<ObjectDetectorView> createState() => _ObjectDetectorView();
}

class _ObjectDetectorView extends State<ObjectDetectorView> {
  ObjectDetector? _objectDetector;
  DetectionMode _mode = DetectionMode.stream;
  bool _canProcess = false;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  String? _text;
  var _cameraLensDirection = CameraLensDirection.back;
  final int _option = 0;
  FlutterTts flutterTts = FlutterTts(); // Initialize FlutterTts

  @override
  void dispose() {
    _canProcess = false;
    _objectDetector?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(children: [
          DetectorView(
            title: 'Object Detector',
            customPaint: _customPaint,
            text: _text,
            onImage: _processImage,
            initialCameraLensDirection: _cameraLensDirection,
            onCameraLensDirectionChanged: (value) =>
                _cameraLensDirection = value,
            onCameraFeedReady: _initializeDetector,
            initialDetectionMode: DetectorViewMode.values[_mode.index],
            onDetectorViewModeChanged: _onScreenModeChanged,
          ),
          Positioned(
              top: 30,
              left: 100,
              right: 100,
              child: Row(
                children: [
                  const Spacer(),
                  Container(
                      // decoration: BoxDecoration(
                      //   color: Colors.black54,
                      //   borderRadius: BorderRadius.circular(10.0),
                      // ),
                      child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    // child: _buildDropdown(),
                  )),
                  const Spacer(),
                ],
              )),
        ]),
      ),
    );
  }

  void _onScreenModeChanged(DetectorViewMode mode) {
    switch (mode) {
      case DetectorViewMode.gallery:
        _mode = DetectionMode.single;
        _initializeDetector();
        return;

      case DetectorViewMode.liveFeed:
        _mode = DetectionMode.stream;
        _initializeDetector();
        return;
    }
  }

  void _initializeDetector() async {
    _objectDetector?.close();
    _objectDetector = null;

    if (_option == 0) {
      final modelPath = await getAssetPath('assets/ml/object_labeler.tflite');
      final options = LocalObjectDetectorOptions(
        mode: _mode,
        modelPath: modelPath,
        classifyObjects: true,
        multipleObjects: true,
      );
      _objectDetector = ObjectDetector(options: options);
    }
    _canProcess = true;
  }

  Future<void> _processImage(InputImage inputImage) async {
    if (_objectDetector == null) return;
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;
    setState(() {
      _text = '';
    });
    final objects = await _objectDetector!.processImage(inputImage);
    //print('Objects found: ${objects.length}');

    for (final object in objects) {
      print(
          'Object: trackingId: ${object.trackingId} - Labels: ${object.labels.map((e) => e.text).join(', ')}');

      for (final label in object.labels) {
        final description = await chatGPTAPI(label.text);
        print('Description for ${label.text}: $description');

        // Speak the description
        await flutterTts.speak(description);
      }
    }

    if (inputImage.metadata?.size != null &&
        inputImage.metadata?.rotation != null) {
      final painter = ObjectDetectorPainter(
        objects,
        inputImage.metadata!.size,
        inputImage.metadata!.rotation,
        _cameraLensDirection,
      );
      _customPaint = CustomPaint(painter: painter);
    } else {
      _customPaint = null;
    }
    _isBusy = false;
    if (mounted) {
      setState(() {});
    }
    await flutterTts.setIosAudioCategory(IosTextToSpeechAudioCategory.playback,
        [IosTextToSpeechAudioCategoryOptions.defaultToSpeaker]);
    await flutterTts.setVoice({"name": "Isha", "locale": "en-IN"});
  }
}

// Function to get object description from ChatGPT API
Future<String> chatGPTAPI(String label) async {
  final List<Map<String, String>> messages = [];
  messages.add({'role': 'user', 'content': label});
  try {
    final res = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $openAIAPIKey'
        },
        body: jsonEncode({
          "model": "gpt-3.5-turbo",
          "messages": messages,
        }));
    if (res.statusCode == 200) {
      String content = jsonDecode(res.body)['choices'][0]['message']['content'];
      content = content.trim();
      messages.add({
        'role': 'assistant',
        'content': content,
      });
      return content;
    }
    return 'An internal error occured.';
  } catch (e) {
    return e.toString();
  }
}
