import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Çöp Sınıflandırıcı',
      theme: ThemeData(primarySwatch: Colors.green),
      home: ImageUploadScreen(),
    );
  }
}

class ImageUploadScreen extends StatefulWidget {
  @override
  _ImageUploadScreenState createState() => _ImageUploadScreenState();
}

class _ImageUploadScreenState extends State<ImageUploadScreen> {
  File? _image;
  String _prediction = '';

  Future<void> captureImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera); // 👈 burası değişti
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      await sendImageToAPI(_image!);
    }
  }

  Future<void> sendImageToAPI(File image) async {
    var uri = Uri.parse('http://192.168.1.104:5000/predict');
    var request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath(
      'image', image.path,
      contentType: MediaType('image', 'jpeg'),
    ));
    var response = await request.send();

    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      final decoded = jsonDecode(respStr);
      setState(() {
        _prediction = decoded['prediction'];
      });
    } else {
      print('Tahmin başarısız: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Kamera ile Çöp Sınıflandırıcı")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _image != null
                ? Image.file(_image!, height: 200)
                : Text("Henüz fotoğraf çekilmedi."),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: captureImage,
              child: Text("Fotoğraf Çek"),
            ),
            SizedBox(height: 20),
            Text("Tahmin: $_prediction", style: TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
}
