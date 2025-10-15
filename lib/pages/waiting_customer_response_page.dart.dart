import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:technican/pages/HomePage.dart';
import 'package:technican/services/app_config_service.dart';

class WaitingCustomerResponsePage extends StatefulWidget {
  final String requestId;

  const WaitingCustomerResponsePage({
    super.key,
    required this.requestId,
    required Map<String, String> arguments,
  });

  @override
  State<WaitingCustomerResponsePage> createState() =>
      _WaitingCustomerResponsePageState();
}

class _WaitingCustomerResponsePageState
    extends State<WaitingCustomerResponsePage> {
  Timer? _timer;
  int _seconds = 0;
  bool _showSummary = false;

  final appConfig = Get.find<AppConfigService>();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _seconds++);
    });
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return "$minutes:$secs";
  }

  @override
  Widget build(BuildContext context) {
    final docRef = FirebaseFirestore.instance
        .collection('requests')
        .doc(widget.requestId);

    return Obx(
      () => Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            "انتظار رد العميل".tr,
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Color(
            int.parse(
              appConfig.themePrimaryColor.value.replaceFirst('#', '0xff'),
            ),
          ),
        ),
        body: StreamBuilder<DocumentSnapshot>(
          stream: docRef.snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Center(child: Text("لا يوجد بيانات.".tr));
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;
            final status = data['status'];
            final finalPrice = (data['finalPrice'] ?? 0).toDouble();

            if (status == 'accepted_by_customer') {
              if (_seconds == 0) _startTimer();
              return _showSummary
                  ? _buildSummary(finalPrice, data)
                  : _buildWorkInProgress(finalPrice);
            }

            if (status == 'rejected_by_customer') {
              return _buildRejectionSection(data);
            }

            if (status == 'cash_paid_and_closed') {
              Future.microtask(() {
                Get.snackbar(
                  "شكراً لك".tr,
                  "شكراً لإنجاز عملك!".tr,
                  backgroundColor: Color(
                    int.parse(
                      appConfig.themePrimaryColor.value.replaceFirst(
                        '#',
                        '0xff',
                      ),
                    ),
                  ).withOpacity(0.1),
                  colorText: Colors.black,
                  snackPosition: SnackPosition.TOP,
                );
                Get.offAllNamed('/technician_requests');
              });
              return const Center(child: CircularProgressIndicator());
            }

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(
                    "جاري انتظار رد العميل...".tr,
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWorkInProgress(double finalPrice) {
    return Obx(
      () => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "✅ تم بدء العمل".tr,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            Text(
              _formatTime(_seconds),
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text("⏳ جاري العمل".tr, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => setState(() => _showSummary = true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(
                  int.parse(
                    appConfig.themeAccentColor.value.replaceFirst('#', '0xff'),
                  ),
                ),
              ),
              child: Text(
                "💵 تحصيل - تم الانتهاء".tr,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(double finalPrice, Map<String, dynamic> requestData) {
    final customerTotal = finalPrice + 20;
    return Obx(
      () => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "💰 المبلغ الواجب تحصيله (شامل 20 خدمة)".tr,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              "$customerTotal جم",
              style: const TextStyle(fontSize: 36, color: Colors.green),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                _showRatingDialog(context, finalPrice, requestData);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(
                  int.parse(
                    appConfig.themePrimaryColor.value.replaceFirst('#', '0xff'),
                  ),
                ),
              ),
              child: Text(
                "تم التحصيل".tr,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRatingDialog(
    BuildContext context,
    double finalPrice,
    Map<String, dynamic> requestData,
  ) {
    double rating = 3;
    final serviceFee = 20.0;
    final commission = finalPrice * 0.10;
    final totalDeduction = commission + serviceFee;
    final netAmountCollected = finalPrice - commission - serviceFee;

    Get.dialog(
      Obx(
        () => AlertDialog(
          backgroundColor: Colors.white,
          title: Text("تقييم العميل".tr),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("من فضلك قيّم العميل بعد انتهاء المهمة".tr),
              const SizedBox(height: 20),
              RatingBar.builder(
                initialRating: 3,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: false,
                itemCount: 5,
                itemBuilder: (context, _) =>
                    const Icon(Icons.star, color: Colors.amber),
                onRatingUpdate: (value) => rating = value,
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(
                  int.parse(
                    appConfig.themePrimaryColor.value.replaceFirst('#', '0xff'),
                  ),
                ),
              ),
              onPressed: () async {
                Get.back();

                final docRef = FirebaseFirestore.instance
                    .collection('requests')
                    .doc(widget.requestId);
                final technicianId =
                    FirebaseAuth.instance.currentUser?.uid ?? '';
                final techRef = FirebaseFirestore.instance
                    .collection('technicians')
                    .doc(technicianId);
                final techSnapshot = await techRef.get();
                final currentBalance = (techSnapshot.data()?['balance'] ?? 0)
                    .toDouble();

                await techRef.update({
                  'balance': currentBalance - totalDeduction,
                });
                await docRef.update({'status': 'cash_paid_and_closed'});

                await FirebaseFirestore.instance
                    .collection('completedOrders')
                    .add({
                      'requestId': widget.requestId,
                      'technicianId': technicianId,
                      'customerName': requestData['userName'] ?? '',
                      'address': requestData['userAddress'] ?? '',
                      'amountCollected': netAmountCollected,
                      'netProfit': netAmountCollected,
                      'status': 'مقبول',
                      'timestamp': DateTime.now(),
                      'customerRatingFromTechnician': rating,
                    });

                Get.snackbar(
                  "تم التحصيل".tr,
                  "تم تحصيل ${netAmountCollected.toStringAsFixed(2)} جنيه بعد خصم ${totalDeduction.toStringAsFixed(2)} من المحفظة."
                      .tr,
                  snackPosition: SnackPosition.TOP,
                  backgroundColor: Color(
                    int.parse(
                      appConfig.themePrimaryColor.value.replaceFirst(
                        '#',
                        '0xff',
                      ),
                    ),
                  ).withOpacity(0.1),
                  colorText: Colors.black,
                );

                Get.offAll(() => WaitingRequestsPage());
              },
              child: Text(
                "إرسال التقييم".tr,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRejectionSection(Map<String, dynamic> requestData) {
    return Obx(
      () => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "❌ تم رفض السعر من العميل".tr,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            Text(
              "💵 تحصيل رسوم الزيارة".tr,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () async {
                final docRef = FirebaseFirestore.instance
                    .collection('requests')
                    .doc(widget.requestId);
                final technicianId =
                    FirebaseAuth.instance.currentUser?.uid ?? '';
                final techRef = FirebaseFirestore.instance
                    .collection('technicians')
                    .doc(technicianId);
                final techSnapshot = await techRef.get();
                final currentBalance = (techSnapshot.data()?['balance'] ?? 0)
                    .toDouble();

                const double visitFee = 50.0;
                const double deduction = 10.0;
                const double netVisitFee = visitFee - deduction;

                await techRef.update({'balance': currentBalance - deduction});
                await docRef.update({'status': 'cash_paid_and_closed'});

                await FirebaseFirestore.instance
                    .collection('completedOrders')
                    .add({
                      'requestId': widget.requestId,
                      'technicianId': technicianId,
                      'customerName': requestData['userName'] ?? '',
                      'address': requestData['userAddress'] ?? '',
                      'amountCollected': netVisitFee,
                      'netProfit': netVisitFee,
                      'status': 'مرفوض',
                      'timestamp': DateTime.now(),
                    });

                Get.snackbar(
                  "تم التحصيل".tr,
                  "تم تحصيل ${netVisitFee.toStringAsFixed(2)} جنيه بعد خصم ${deduction.toStringAsFixed(2)} من المحفظة."
                      .tr,
                  snackPosition: SnackPosition.TOP,
                  backgroundColor: Color(
                    int.parse(
                      appConfig.themePrimaryColor.value.replaceFirst(
                        '#',
                        '0xff',
                      ),
                    ),
                  ).withOpacity(0.1),
                  colorText: Colors.black,
                );

                Get.offAll(() => WaitingRequestsPage());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(
                  int.parse(
                    appConfig.themePrimaryColor.value.replaceFirst('#', '0xff'),
                  ),
                ),
              ),
              child: Text(
                "✅ تم التحصيل".tr,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
