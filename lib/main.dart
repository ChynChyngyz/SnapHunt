import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
    orElse: () => cameras.first,
  );

  runApp(MyApp(camera: backCamera));
}

class MyApp extends StatelessWidget {
  final CameraDescription camera;

  const MyApp({super.key, required this.camera});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Camera',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: MyHomePage(camera: camera),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final CameraDescription camera;

  const MyHomePage({super.key, required this.camera});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );
    _initializeControllerFuture = _controller?.initialize();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _openCamera() async {
    try {
      await _initializeControllerFuture;
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CameraPreviewPage(controller: _controller!),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка инициализации камеры: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Camera'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const <Widget>[
            Text('Нажмите на иконку камеры, чтобы открыть камеру:'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCamera,
        tooltip: 'Открыть камеру',
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}

class CameraPreviewPage extends StatefulWidget {
  final CameraController controller;

  const CameraPreviewPage({super.key, required this.controller});

  @override
  _CameraPreviewPageState createState() => _CameraPreviewPageState();
}

class _CameraPreviewPageState extends State<CameraPreviewPage> {
  String? _imagePath;

  void _takePicture() async {
    try {
      // Делаем фото
      final XFile picture = await widget.controller.takePicture();

      // Сохраняем в галерею с помощью gallery_saver_plus
      await GallerySaver.saveImage(
        picture.path,
        albumName: 'My Camera App',
      ).then((bool? success) {
        if (success == true) {
          setState(() {
            _imagePath = picture.path;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Фото сохранено в галерею! 📸')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Не удалось сохранить фото')),
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Предпросмотр камеры")),
      body: Column(
        children: <Widget>[
          Expanded(
            child: CameraPreview(widget.controller),
          ),
          if (_imagePath != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Image.file(File(_imagePath!)),
                  const SizedBox(height: 10),
                  const Text(
                    'Фото сохранено в галерее!',
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _takePicture,
        tooltip: 'Сделать фото',
        child: const Icon(Icons.camera),
      ),
    );
  }
}