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

class InfoScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Geri Dönüşüm Bilgisi")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
               "♻️ Geri Dönüşüm Neden Önemli?\n\n"
                "Geri dönüşüm, doğaya atılan atık miktarını azaltır ve doğal kaynakları korur. "
                "Aynı zamanda enerji tasarrufu sağlar ve sera gazı salınımını düşürür.\n\n"

                "♻️ Geri Dönüştürülebilen Atık Türleri:\n\n"
                "🧴 Plastik: Su şişeleri, poşetler, temizlik ürünleri kapları\n"
                "🍾 Cam: Cam şişeler, kavanozlar\n"
                "📄 Kağıt: Gazeteler, dergiler, ofis kâğıtları\n"
                "📦 Karton: Koli, pizza kutusu, yumurta kartonları\n"
                "🔩 Metal: Konserve kutuları, içecek kutuları, alüminyum folyo\n\n"

                "❗ Not: Atıkları temiz ve kuru şekilde atmak, geri dönüşüm kalitesini artırır.\n\n"

                "Bu uygulama ile atığınızın geri dönüştürülebilir olup olmadığını kolayca tespit edebilirsiniz. "
                 "Fotoğraf çekin, biz size ne olduğunu söyleyelim!",
                  style: TextStyle(fontSize: 18, height: 1.5),
                ),

            Spacer(),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ImageUploadScreen()),
                );
              },
              icon: Icon(Icons.camera_alt),
              label: Text("Fotoğraf Çek ve Sınıflandır"),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                textStyle: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Çöp Sınıflandırıcı',
      theme: ThemeData(primarySwatch: Colors.green),
      home: InfoScreen(),
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
  double _confidence = 0.0;
  bool _isLoading = false;

  bool isRecyclable(String prediction) {
  final recyclable = [
    'battery',
    'cardboard',
    'glass',
    'metal',
    'paper',
    'plastic',
  ];
  return recyclable.contains(prediction.toLowerCase());
}

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
  setState(() {
    _isLoading = true;
  });

  var uri = Uri.parse('http://192.168.1.104:5000/predict');
  var request = http.MultipartRequest('POST', uri);
  request.files.add(await http.MultipartFile.fromPath(
    'image', image.path,
    contentType: MediaType('image', 'jpeg'),
  ));

  var response = await request.send();
  final respStr = await response.stream.bytesToString();

  setState(() {
    _isLoading = false;
    if (response.statusCode == 200) {
      final decoded = jsonDecode(respStr);
      _prediction = decoded['prediction'];
      _confidence = decoded['confidence'];  // 🔥 Artık düzgün set ediliyor
    } else {
      _prediction = 'Tahmin alınamadı 😕';
      _confidence = 0.0;
    }
  });
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
          _isLoading
              ? CircularProgressIndicator()
              : _prediction.isNotEmpty
  ? Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isRecyclable(_prediction)
                  ? Icons.check_circle
                  : Icons.cancel,
              color: isRecyclable(_prediction)
                  ? Colors.green
                  : Colors.red,
              size: 28,
            ),
            SizedBox(width: 10),
            Text(
              isRecyclable(_prediction)
                  ? "♻️ Geri dönüştürülebilir madde!"
                  : "🚫 Geri dönüştürülemez.",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isRecyclable(_prediction)
                    ? Colors.green
                    : Colors.red,
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        Text(
          "🔍 Tahmin: ${_prediction[0].toUpperCase()}${_prediction.substring(1)}",
          style: TextStyle(fontSize: 16),
        ),
        Text(
          "📊 Güven: %${(_confidence * 100).toStringAsFixed(1)}",
          style: TextStyle(fontSize: 16),
        ),
      ],
    )
  : Container(),

        ],
      ),
    ),
  );
}
}
