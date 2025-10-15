import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:technican/webview_payment_page.dart';

class RechargeWalletController extends GetxController {
  final currentBalance = 0.0.obs;
  final rechargeHistory = <Map<String, dynamic>>[].obs;
  final amountController = TextEditingController();
  final loading = false.obs;

  final minRechargeAmount = 100.0;
  final maxRechargeAmount = 10000.0;

  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final String quickPayUrl =
      'https://accept.paymobsolutions.com/unifiedcheckout/?publicKey=egy_pk_test_AqjMDsRTUMWILaxKipD3b0y2rrxe4ke7&clientSecret=egy_csk_test_58518c75750f4e4b34efba786beeea0b&multiple_payment_link_token=LRR2NlFvOC8rRElmY3V0TlhZRHRYdENJQT09X3ZsUXo3c1FmMnlRVHFUUnFkeEc0ckE9PQ&multiple_payment_link_attempt=LRR2djJVSlhiYThDTmhibWNRZ1Q5SGN0QT09XzRka3pFZjF0SWh0UVA3TjBqa1hERWc9PQ';

  StreamSubscription<DocumentSnapshot>? _balanceListener;

  @override
  void onInit() {
    super.onInit();
    listenToBalance(); // ✅ بدل fetchBalance()
    fetchRechargeHistory();
  }

  @override
  void onClose() {
    _balanceListener?.cancel(); // ✅ نوقف الـ listener عند الخروج
    amountController.dispose();
    super.onClose();
  }

  /// ✅ متابعة الرصيد لحظيًا
  void listenToBalance() {
    final uid = auth.currentUser?.uid;
    if (uid == null) return;

    _balanceListener = firestore
        .collection('technicians')
        .doc(uid)
        .snapshots()
        .listen((doc) {
          if (doc.exists) {
            currentBalance.value = (doc.data()?['balance'] ?? 0.0).toDouble();
          } else {
            currentBalance.value = 0.0;
          }
        });
  }

  Future<void> fetchRechargeHistory() async {
    try {
      final uid = auth.currentUser?.uid;
      if (uid == null) return;

      final snapshot = await firestore
          .collection('technicians')
          .doc(uid)
          .collection('recharges')
          .orderBy('timestamp', descending: true)
          .get();

      rechargeHistory.assignAll(
        snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList(),
      );
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في جلب سجل الشحنات: ${e.toString()}');
    }
  }

  void processRechargeRequest() {
    final amountText = amountController.text.trim();

    if (amountText.isEmpty) {
      Get.snackbar('خطأ', 'الرجاء إدخال المبلغ المطلوب شحنه.');
      return;
    }

    final double? amount = double.tryParse(amountText);
    if (amount == null) {
      Get.snackbar('خطأ', 'الرجاء إدخال مبلغ صحيح.');
      return;
    }

    if (amount < minRechargeAmount) {
      Get.snackbar(
        'خطأ',
        'الحد الأدنى للشحن هو ${minRechargeAmount.toStringAsFixed(0)} جنيه.',
      );
      return;
    }

    if (amount > maxRechargeAmount) {
      Get.snackbar(
        'خطأ',
        'الحد الأقصى للشحن هو ${maxRechargeAmount.toStringAsFixed(0)} جنيه.',
      );
      return;
    }

    showConfirmationDialog(amount);
  }

  Future<void> showConfirmationDialog(double amount) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('تأكيد الشحن'),
        content: Text('هل تريد شحن ${amount.toStringAsFixed(2)} جنيه؟'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      Get.to(
        () => WebViewPaymentPage(
          paymentUrl: quickPayUrl,
          amount: amount,
          onPaymentSuccess: (amount) {
            Get.snackbar("تم", "تم الدفع بنجاح بمبلغ $amount جنيه");
          },
          onPaymentError: () {
            Get.snackbar("فشل", "حدث خطأ أثناء عملية الدفع");
          },
        ),
      );
    }
  }

  String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final dt = timestamp.toDate();
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute}';
  }
}
