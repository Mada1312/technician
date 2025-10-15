import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:technican/login.dart';
import 'package:technican/pages/HomePage.dart';
import 'package:technican/pages/compelete_info_page.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen(
            message: "جاري التحقق من تسجيل الدخول...",
          );
        }

        // ⛔ المستخدم غير مسجل دخول
        if (!snapshot.hasData) {
          return const Loginpage();
        }

        final uid = snapshot.data!.uid;

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('technicians')
              .doc(uid)
              .get(),
          builder: (context, techSnapshot) {
            if (techSnapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingScreen(
                message: "جاري تحميل بيانات الفني...",
              );
            }

            if (techSnapshot.hasError) {
              return const _ErrorScreen();
            }

            if (!techSnapshot.hasData || !techSnapshot.data!.exists) {
              // ⛔ بيانات الفني غير مكتملة
              return const CompleteTechnicianInfoPage();
            }

            // ✅ كل شيء تمام - الانتقال لواجهة الطلبات
            return const WaitingRequestsPage();
          },
        );
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  final String message;
  const _LoadingScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset("assets/images/icon.png", width: 80, height: 80),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
            const SizedBox(height: 10),
            Text(message, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 20),
            const Text(
              "حدث خطأ ما. يرجى المحاولة مرة أخرى.",
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => Get.forceAppUpdate(),
              child: const Text("إعادة المحاولة"),
            ),
          ],
        ),
      ),
    );
  }
}
