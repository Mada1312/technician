import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:technican/pages/HomePage.dart';
import 'package:technican/technician_types.dart';
import 'package:technican/services/app_config_service.dart';
import 'package:uuid/uuid.dart';

class CompleteTechnicianInfoPage extends StatefulWidget {
  const CompleteTechnicianInfoPage({super.key});

  @override
  State<CompleteTechnicianInfoPage> createState() =>
      _CompleteTechnicianInfoPageState();
}

class _CompleteTechnicianInfoPageState
    extends State<CompleteTechnicianInfoPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  String? selectedSpecialtyKey;
  File? selectedImage;
  bool isSaving = false;

  final locale = 'ar';

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => selectedImage = File(picked.path));
    }
  }

  Future<String?> uploadImageToCloudinary(File imageFile) async {
    const cloudName = 'ds6huy8fp';
    const uploadPreset = 'technician_upload';

    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final resStr = await response.stream.bytesToString();
      final resJson = json.decode(resStr);
      return resJson['secure_url'];
    } else {
      print('Upload failed: ${response.statusCode}');
      return null;
    }
  }

  Future<void> saveInfo() async {
    final config = Get.find<AppConfigService>();
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    final specialtyKey = selectedSpecialtyKey;

    if (name.isEmpty ||
        phone.isEmpty ||
        specialtyKey == null ||
        selectedImage == null) {
      Get.snackbar(
        'incomplete_data'.tr,
        'please_enter_all_data_and_select_image'.tr,
        backgroundColor: Color(
          int.parse(config.themeAccentColor.value.replaceFirst('#', '0xff')),
        ),
        colorText: Colors.white,
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final technicianId =
          'TECH-${const Uuid().v4().substring(0, 6).toUpperCase()}';

      final imageUrl = await uploadImageToCloudinary(selectedImage!);
      if (imageUrl == null) throw Exception('image_upload_failed'.tr);

      await FirebaseFirestore.instance.collection('technicians').doc(uid).set({
        'name': name,
        'phone': phone,
        'specialty': specialtyKey,
        'imageUrl': imageUrl,
        'technicianId': technicianId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      Get.offAll(() => const WaitingRequestsPage());
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        '${'failed_to_save_data'.tr}: $e',
        backgroundColor: Color(
          int.parse(config.themeAccentColor.value.replaceFirst('#', '0xff')),
        ),
        colorText: Colors.white,
      );
    } finally {
      setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = Get.find<AppConfigService>();

    return Obx(() {
      final primaryColor = Color(
        int.parse(config.themePrimaryColor.value.replaceFirst('#', '0xff')),
      );
      final accentColor = Color(
        int.parse(config.themeAccentColor.value.replaceFirst('#', '0xff')),
      );

      return Scaffold(
        appBar: AppBar(
          backgroundColor: primaryColor,
          title: Text('complete_technician_info'.tr),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: pickImage,
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: accentColor.withOpacity(0.2),
                  backgroundImage: selectedImage != null
                      ? FileImage(selectedImage!)
                      : null,
                  child: selectedImage == null
                      ? Icon(Icons.camera_alt, size: 40, color: accentColor)
                      : null,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'full_name'.tr,
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: primaryColor),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'phone_number'.tr,
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: primaryColor),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'specialty'.tr,
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: primaryColor),
                  ),
                ),
                items: TechnicianTypes.serviceKeys.map((key) {
                  return DropdownMenuItem(
                    value: key,
                    child: Text(TechnicianTypes.getLocalizedTitle(key, locale)),
                  );
                }).toList(),
                onChanged: (val) => setState(() => selectedSpecialtyKey = val),
                value: selectedSpecialtyKey,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSaving ? null : saveInfo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'حفظ البيانات',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
