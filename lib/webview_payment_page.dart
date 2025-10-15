import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:technican/recharge_wallet_controller.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WebViewPaymentPage extends StatefulWidget {
  final String paymentUrl;
  final double amount;
  final Function(double) onPaymentSuccess;
  final Function() onPaymentError;

  const WebViewPaymentPage({
    super.key,
    required this.paymentUrl,
    required this.amount,
    required this.onPaymentSuccess,
    required this.onPaymentError,
  });

  @override
  State<WebViewPaymentPage> createState() => _WebViewPaymentPageState();
}

class _WebViewPaymentPageState extends State<WebViewPaymentPage> {
  late final WebViewController controller;
  bool isLoading = true;
  bool paymentCompleted = false;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() => isLoading = progress < 100);
          },
          onPageStarted: (String url) {
            setState(() => isLoading = true);
          },
          onPageFinished: (String url) {
            setState(() => isLoading = false);
            _checkPaymentStatus(url);
          },
          onNavigationRequest: (NavigationRequest request) {
            return _handleNavigation(request.url);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  NavigationDecision _handleNavigation(String url) {
    if (_isPaymentSuccess(url)) {
      if (!paymentCompleted) {
        paymentCompleted = true;
        _updateBalanceAndHistory(widget.amount);
      }
      return NavigationDecision.prevent;
    } else if (_isPaymentError(url)) {
      widget.onPaymentError();
      Get.back();
      return NavigationDecision.prevent;
    }
    return NavigationDecision.navigate;
  }

  void _checkPaymentStatus(String url) {
    if (_isPaymentSuccess(url) && !paymentCompleted) {
      paymentCompleted = true;
      _updateBalanceAndHistory(widget.amount);
    } else if (_isPaymentError(url)) {
      widget.onPaymentError();
      Get.back();
    }
  }

  bool _isPaymentSuccess(String url) {
    final lowerUrl = url.toLowerCase();
    return lowerUrl.contains("success") ||
        lowerUrl.contains("successful") ||
        lowerUrl.contains("completed");
  }

  bool _isPaymentError(String url) {
    final lowerUrl = url.toLowerCase();
    return lowerUrl.contains("fail") ||
        lowerUrl.contains("error") ||
        lowerUrl.contains("cancel");
  }

  /// ✅ تحديث الرصيد وتسجيل عملية الشحن
  Future<void> _updateBalanceAndHistory(double amount) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final firestore = FirebaseFirestore.instance;

      // زيادة الرصيد
      await firestore.collection('technicians').doc(uid).update({
        'balance': FieldValue.increment(amount),
      });

      // إضافة سجل شحن جديد
      await firestore
          .collection('technicians')
          .doc(uid)
          .collection('recharges')
          .add({
            'amount': amount,
            'timestamp': FieldValue.serverTimestamp(),
            'method': 'Paymob',
          });

      widget.onPaymentSuccess(amount);
      Get.snackbar("تم", "تم شحن رصيدك بنجاح بمبلغ $amount جنيه");
      Get.back();
    } catch (e) {
      widget.onPaymentError();
      Get.snackbar("خطأ", "فشل في تحديث الرصيد: $e");
      Get.back();
    }
  }

  Future<void> _showExitDialog() async {
    final shouldExit = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('إلغاء الدفع؟'),
        content: const Text('هل أنت متأكد أنك تريد إلغاء عملية الدفع؟'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('لا'),
          ),
          TextButton(
            onPressed: () => Get.put(RechargeWalletController()),
            child: const Text('نعم'),
          ),
        ],
      ),
    );

    if (shouldExit == true) {
      widget.onPaymentError();
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("إتمام عملية الدفع"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _showExitDialog,
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: controller),
          if (isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
