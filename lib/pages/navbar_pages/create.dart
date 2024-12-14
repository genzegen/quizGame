import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gameflow/components/textfield.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class CreatePage extends StatefulWidget {
  const CreatePage({super.key});

  @override
  State<CreatePage> createState() => _CreatePageState();
}

class _CreatePageState extends State<CreatePage> {
  final TextEditingController option1Controller = TextEditingController();
  final TextEditingController option2Controller = TextEditingController();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  String? selectedOption;
  String? title;
  String? titleLower;
  String? description;
  int currentRound = 1;
  final int maxRounds = 2;  // Max rounds limit
  File? _image;
  String? _uploadedImageUrl;

  final user = FirebaseAuth.instance.currentUser;
  String? quizId; // Store quizId after creating quiz in Firestore

  final picker = ImagePicker();
  final String cloudName = 'ds1awslfj';
  final String apiKey = 'y993596581268421';
  final String uploadPreset = 'ml_default';

  Future<void> _createQuizInFirestore() async {
    // Create a new quiz document with a title
    final quizDoc = await FirebaseFirestore.instance.collection('quizzes').add({
      'description': descriptionController.text,
      'title': titleController.text,
      'titleLower': titleController.text.toLowerCase(),
      'createdAt': Timestamp.now(),
      'userId': user?.uid,
    });
    quizId = quizDoc.id;
  }

  Future<void> _saveQuestionInFirestore() async {
    if (quizId == null) {
      await _createQuizInFirestore();
    }

    await FirebaseFirestore.instance
        .collection('quizzes')
        .doc(quizId)
        .collection('questions')
        .add({
      'option1': option1Controller.text,
      'option2': option2Controller.text,
      'correctAnswer': selectedOption == 'Option 1' ? option1Controller.text : option2Controller.text,
      'imageUrl': _uploadedImageUrl,
    });

    // Reset for the next question
    option1Controller.clear();
    option2Controller.clear();
    setState(() {
      selectedOption = null;
      _uploadedImageUrl = null;
      currentRound++;  // Increment the round
    });
  }

  Future<void> _pickImage() async {
    if (_uploadedImageUrl != null) return; // Prevent picking another image if one is already uploaded

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

  // Show a Snackbar when max rounds are reached and navigate back
  void _handleSubmit() async {
    // Ensure all questions are saved
    await _saveQuestionInFirestore();

    // Show Snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Quiz Submitted! Create again later!'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Navigate back after a short delay
    Future.delayed(const Duration(seconds: 1), () {
      Navigator.pop(context);  // Go back to the previous page
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Page",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      resizeToAvoidBottomInset: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Center(
                child: Text("Let's create a quiz!",
                    style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic)),
              ),
              const SizedBox(height: 20),
              if (currentRound == 1)
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: MyTextField(
                          hintText: "Enter a title for your quiz",
                          obscureText: false,
                          controller: titleController),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        if (titleController.text.isNotEmpty) {
                          setState(() {
                            title = titleController.text;
                          });
                          _createQuizInFirestore();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor:
                          Theme.of(context).colorScheme.tertiary),
                      child: const Text("Set Title",
                          style: TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: MyTextField(
                          hintText: "Write a description about your quiz",
                          obscureText: false,
                          controller: descriptionController),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        if (descriptionController.text.isNotEmpty) {
                          setState(() {
                            description = descriptionController.text;
                          });
                          _createQuizInFirestore();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor:
                          Theme.of(context).colorScheme.tertiary),
                      child: const Text("Set Description",
                          style: TextStyle(fontSize: 18)),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    Text(title ?? titleController.text,
                        style: const TextStyle(
                            fontSize: 30, fontWeight: FontWeight.bold)),
                    Text(description ?? descriptionController.text,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
              const SizedBox(height: 20),
              const Text("Step 1: Import an image for the quiz!",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _uploadedImageUrl == null
                  ? GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: 200,
                  decoration: BoxDecoration(
                      border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2)),
                  child: const Center(child: Text("No image selected")),
                ),
              )
                  : Image.network(_uploadedImageUrl!, width: 200, height: 200),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _uploadedImageUrl == null ? _pickImage : null,  // Disable if image is uploaded
                style: ElevatedButton.styleFrom(
                    elevation: 5,
                    backgroundColor: Theme.of(context).colorScheme.tertiary),
                child:
                const Text("Pick an Image", style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(height: 20),
              const Text("Step 2: Enter your options:",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: MyTextField(
                    hintText: "Option 1",
                    obscureText: false,
                    controller: option1Controller),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: MyTextField(
                    hintText: "Option 2",
                    obscureText: false,
                    controller: option2Controller),
              ),
              const SizedBox(height: 20),
              Text("Correct answer: $selectedOption",
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 20),

              // Radio buttons for correct option selection
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Radio<String>(
                    value: 'Option 1',
                    groupValue: selectedOption,
                    onChanged: (value) {
                      setState(() {
                        selectedOption = value;
                      });
                    },
                  ),
                  const Text('Option 1', style: TextStyle(fontSize: 18)),
                  Radio<String>(
                    value: 'Option 2',
                    groupValue: selectedOption,
                    onChanged: (value) {
                      setState(() {
                        selectedOption = value;
                      });
                    },
                  ),
                  const Text('Option 2', style: TextStyle(fontSize: 18)),
                ],
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: currentRound < maxRounds
                    ? _saveQuestionInFirestore
                    : _handleSubmit,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.tertiary),
                child: Text(
                  currentRound == maxRounds ? "Submit" : "Next",
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
