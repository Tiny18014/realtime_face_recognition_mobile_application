import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import '../ML/RecognizerClass.dart'; // Your recognizer class path
import 'package:firebase_auth/firebase_auth.dart'; // Assuming Firebase Auth is used

class FaceVerificationPage extends StatefulWidget {
  final String userId;
  final String subjectName;
  const FaceVerificationPage({
    Key? key,
    required this.subjectName, // Make subjectName required
    required this.userId, // Make userId required
  }) : super(key: key);

  @override
  _FaceVerificationPageState createState() => _FaceVerificationPageState();
}

class _FaceVerificationPageState extends State<FaceVerificationPage> {
  late CameraController _cameraController;
  late List<CameraDescription> _cameras;
  bool _isCameraInitialized = false;
  bool _isFlippingCamera =
      false; // Flag to disable flip button during re-initialization
  int _selectedCameraIndex = 0; // 0 for back, 1 for front camera
  final Recognizer recognizer = Recognizer();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {

      _cameras = await availableCameras();


      final CameraDescription camera = _cameras[_selectedCameraIndex];
      _cameraController = CameraController(camera, ResolutionPreset.high);

      await _cameraController.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      print("Error initializing camera: $e");
    }
  }

  Future<img.Image> _captureLiveImage() async {
    if (!_cameraController.value.isInitialized) {
      throw Exception('Camera not initialized');
    }
    final XFile picture = await _cameraController.takePicture();
    return img.decodeImage(await picture.readAsBytes())!;
  }

  Future<bool> _verifyFace(img.Image liveImage) async {
    try {

      List<double>? liveEmbedding =
          await recognizer.extractEmbeddings(liveImage);


      print('Live Embedding: $liveEmbedding');

      if (liveEmbedding == null) {

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No face detected. Please try again.')),
        );
        return false;
      }


      String closestName =
          await recognizer.findNearest(liveEmbedding, widget.userId);

      if (closestName == widget.userId) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Face verification successful!')),
        );
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Face verification failed.')),
        );
        return false;
      }
    } catch (e) {
      print('Error during face verification: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during verification. Please try again.')),
      );
      return false;
    }
  }


  void _toggleCamera() async {
    setState(() {
      _isFlippingCamera = true;
    });

    setState(() {
      _selectedCameraIndex = (_selectedCameraIndex == 0) ? 1 : 0;
    });


    await _initializeCamera();

    setState(() {
      _isFlippingCamera =
          false;
    });
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: Text('Face Verification')),
      body: SingleChildScrollView(

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Container(
              width: double.infinity,
              height: 400,
              child: CameraPreview(_cameraController),
            ),


            IconButton(
              icon: Icon(
                Icons.flip_camera_ios,
                size: 30,
              ),
              onPressed: _isFlippingCamera
                  ? null
                  : _toggleCamera,
            ),

            ElevatedButton(
              onPressed: () async {
                try {
                  img.Image liveImage = await _captureLiveImage();
                  bool isFaceVerified = await _verifyFace(liveImage);
                  Navigator.pop(context, isFaceVerified);
                } catch (e) {
                  print('Error capturing image: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error capturing image.')));
                }
              },
              child: Text('Verify Face'),
            ),
          ],
        ),
      ),
    );
  }
}
