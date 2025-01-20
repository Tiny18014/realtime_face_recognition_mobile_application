import 'dart:math';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Recognizer {
  late Interpreter interpreter;
  static const int WIDTH = 112;
  static const int HEIGHT = 112;

  Recognizer({int? numThreads}) {
    _loadModel(numThreads).then((_) {
      print('Recognizer is ready for use.');
    });
  }


  Future<void> _loadModel(int? numThreads) async {
    try {
      InterpreterOptions options = InterpreterOptions();
      if (numThreads != null) {
        options.threads = numThreads;
      }
      interpreter = await Interpreter.fromAsset('assets/mobile_face_net.tflite',
          options: options);
      print('Model loaded successfully!');
    } catch (e) {
      print('Failed to load model: $e');
    }
  }

  Float32List _imageToInputArray(img.Image image) {
    img.Image resized = img.copyResize(image, width: WIDTH, height: HEIGHT);
    Float32List input = Float32List(WIDTH * HEIGHT * 3);
    int index = 0;

    for (int y = 0; y < HEIGHT; y++) {
      for (int x = 0; x < WIDTH; x++) {
        img.Pixel pixel = resized.getPixel(x, y);
        input[index++] = (pixel.r / 255.0) * 2 -
            1; // Normalize pixel value from 0-255 to -1 to 1
        input[index++] = (pixel.g / 255.0) * 2 - 1;
        input[index++] = (pixel.b / 255.0) * 2 - 1;
      }
    }
    return input;
  }

  Future<List<double>> extractEmbeddings(img.Image image) async {
    Float32List input = _imageToInputArray(image);
    List output = List.filled(1 * 192, 0).reshape([1, 192]);
    interpreter.run(input.reshape([1, WIDTH, HEIGHT, 3]), output);
    return List<double>.from(output[0]);
  }

  Future<List<double>?> fetchUserEmbedding(String userId) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        return List<double>.from(doc['faceEmbeddings']);
      }
    } catch (e) {
      print('Error fetching user embedding: $e');
    }
    return null;
  }

  Future<String> findNearest(List<double> liveEmbedding, String userId) async {
    try {
      // Fetch embeddings from Firebase Firestore
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (!userDoc.exists || !userDoc.data()!.containsKey('faceEmbeddings')) {
        throw Exception('No embeddings found for user');
      }

      // Retrieve stored embeddings
      List<dynamic> storedEmbedding = userDoc.data()!['faceEmbeddings'];

      // Convert dynamic list to List<double>
      List<double> storedEmbeddingList = List<double>.from(storedEmbedding);

      // Calculate similarity or distance (Cosine similarity or Euclidean distance)
      double distance = _calculateDistance(liveEmbedding, storedEmbeddingList);
      double similarity =
          _calculateSimilarity(liveEmbedding, storedEmbeddingList);

      // Log the distances and similarity for debugging
      print('Distance: $distance');
      print('Similarity: $similarity');
      print('Threshold for verification: 0.5');

      // Define a threshold for verification
      const double threshold = 0.5;

      if (similarity > threshold) {
        return userId; // Verified match
      } else {
        return ''; // No match
      }
    } catch (e) {
      print('Error finding nearest: $e');
      return '';
    }
  }

// Helper method for cosine similarity
  double _calculateSimilarity(List<double> a, List<dynamic> b) {
    double dotProduct = 0.0, magnitudeA = 0.0, magnitudeB = 0.0;
    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      magnitudeA += a[i] * a[i];
      magnitudeB += b[i] * b[i];
    }
    return dotProduct / (sqrt(magnitudeA) * sqrt(magnitudeB));
  }

  // Helper method for Euclidean distance
  double _calculateDistance(List<double> a, List<dynamic> b) {
    double sum = 0.0;
    for (int i = 0; i < a.length; i++) {
      sum += (a[i] - b[i]) * (a[i] - b[i]);
    }
    return sqrt(sum);
  }

  void close() {
    interpreter.close();
  }
}
