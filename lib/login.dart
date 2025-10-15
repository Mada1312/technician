import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:technican/pages/HomePage.dart';
import 'package:technican/services/app_config_service.dart';

class Loginpage extends StatefulWidget {
  const Loginpage({super.key});

  @override
  _LoginpageState createState() => _LoginpageState();
}

class _LoginpageState extends State<Loginpage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  bool _obscurePassword = true;
  bool _rememberMe = false;
  String message = "";
  late AnimationController _controller;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 24,
    ).chain(CurveTween(curve: Curves.elasticIn)).animate(_controller);

    _loadRememberedCredentials();
  }

  Future<void> _loadRememberedCredentials() async {
    final email = await secureStorage.read(key: 'email');
    final password = await secureStorage.read(key: 'password');
    final remember = await secureStorage.read(key: 'remember') == 'true';

    if (remember) {
      if (!mounted) return;
      setState(() {
        _emailController.text = email ?? '';
        _passwordController.text = password ?? '';
        _rememberMe = remember;
      });
    }
  }

  Future<void> _saveCredentialsIfNeeded() async {
    if (_rememberMe) {
      await secureStorage.write(
        key: 'email',
        value: _emailController.text.trim(),
      );
      await secureStorage.write(
        key: 'password',
        value: _passwordController.text.trim(),
      );
      await secureStorage.write(key: 'remember', value: 'true');
    } else {
      await secureStorage.delete(key: 'email');
      await secureStorage.delete(key: 'password');
      await secureStorage.write(key: 'remember', value: 'false');
    }
  }

  void handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      if (!mounted) return;
      setState(() => message = "من فضلك أدخل البريد الإلكتروني وكلمة المرور.");
      _controller.forward(from: 0);
      return;
    }

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _saveCredentialsIfNeeded();

      if (!mounted) return; // ✅ تأكيد أن الصفحة لسه موجودة
      setState(() => message = "تم تسجيل الدخول بنجاح!");
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return; // ✅ تأكيد مرة تانية قبل الانتقال
      Get.offAll(() => const WaitingRequestsPage());
    } catch (e) {
      if (!mounted) return;
      setState(() => message = "فشل تسجيل الدخول: ${e.toString()}");
      _controller.forward(from: 0);
    }
  }

  void showPasswordResetDialog() {
    final resetController = TextEditingController();
    final config = Get.find<AppConfigService>();

    Get.defaultDialog(
      title: "إعادة تعيين كلمة المرور",
      content: Column(
        children: [
          const Text("أدخل بريدك الإلكتروني لإرسال رابط إعادة التعيين:"),
          const SizedBox(height: 10),
          TextField(
            controller: resetController,
            decoration: const InputDecoration(
              hintText: "البريد الإلكتروني",
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      textConfirm: "إرسال",
      textCancel: "إلغاء",
      confirmTextColor: Colors.white,
      buttonColor: Color(
        int.parse(config.themeAccentColor.value.replaceFirst('#', '0xff')),
      ),
      onConfirm: () async {
        final email = resetController.text.trim();
        if (email.isEmpty) return;
        try {
          await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
          Get.back();
          Get.snackbar(
            "تم بنجاح",
            "تم إرسال رابط إعادة تعيين كلمة المرور.",
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } catch (e) {
          Get.snackbar(
            "خطأ",
            "فشل إرسال البريد الإلكتروني.",
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
        backgroundColor: primaryColor.withOpacity(0.9),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(FontAwesomeIcons.toolbox, color: accentColor, size: 60),
                const SizedBox(height: 20),
                const Text(
                  'تسجيل دخول الفني',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                _buildTextField('البريد الإلكتروني', _emailController),
                const SizedBox(height: 20),
                _buildPasswordField(
                  'كلمة المرور',
                  _passwordController,
                  _obscurePassword,
                  () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (val) =>
                          setState(() => _rememberMe = val ?? false),
                      checkColor: Colors.black,
                      activeColor: accentColor,
                    ),
                    const Text("تذكرني", style: TextStyle(color: Colors.white)),
                    const Spacer(),
                    TextButton(
                      onPressed: showPasswordResetDialog,
                      child: Text(
                        "هل نسيت كلمة المرور؟",
                        style: TextStyle(color: accentColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'تسجيل الدخول',
                    style: TextStyle(color: Colors.black, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 20),
                if (message.isNotEmpty)
                  Text(
                    message,
                    style: const TextStyle(color: Colors.redAccent),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildTextField(String hint, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.grey[900],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildPasswordField(
    String hint,
    TextEditingController controller,
    bool obscureText,
    VoidCallback onToggle,
  ) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.grey[900],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }
}
