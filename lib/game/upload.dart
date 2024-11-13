import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  File? _image;
  String? _uploadedImageUrl;
  final picker = ImagePicker();
  final String cloudName = 'ds1awslfj'; // Your Cloudinary cloud name
  final String apiKey = 'y993596581268421'; // Your Cloudinary API key
  final String uploadPreset =
      'ml_default'; // Your Cloudinary upload preset

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      _uploadImageToCloudinary();
    }
  }

  Future<void> _uploadImageToCloudinary() async {
    if (_image == null) return;

    final url =
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    final request = http.MultipartRequest('POST', url);

    request.fields['upload_preset'] = uploadPreset;
    request.files.add(await http.MultipartFile.fromPath('file', _image!.path));

    final response = await request.send();
    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseBody);

      setState(() {
        _uploadedImageUrl = jsonResponse['secure_url'];
      });
      print("Image uploaded successfully: $_uploadedImageUrl");
    } else {
      print("Failed to upload image: ${response.statusCode}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Cloudinary Image Upload")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _uploadedImageUrl == null
                ? Text("No image uploaded")
                : Image.network(_uploadedImageUrl!, width: 200, height: 200),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text("Pick Image and Upload"),
            ),
          ],
        ),
      ),
    );
  }
}
