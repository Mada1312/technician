import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:technican/login.dart';
import 'package:technican/pages/previous_tasks_page.dart';
import 'package:technican/pages/recharge_wallet_page.dart';
import 'package:technican/pages/support_page.dart';
import 'package:technican/recharge_wallet_controller.dart';
import 'package:technican/services/app_config_service.dart';
import 'package:technican/waiting_requests_controller.dart'; // ✅ مهم جدًا

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? technicianName;
  String? technicianImageUrl;
  String? technicianId;
  double? technicianBalance;
  String? technicianBranch;
  double? technicianRating;

  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _fetchTechnicianData();
  }

  Future<void> _fetchTechnicianData() async {
    if (currentUserId.isEmpty) return;

    final docRef = FirebaseFirestore.instance
        .collection('technicians')
        .doc(currentUserId);
    final doc = await docRef.get();

    if (!doc.exists) return;

    final data = doc.data()!;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    double totalNetProfit = 0;

    // ✅ حساب أرباح اليوم فقط
    final ordersSnapshot = await FirebaseFirestore.instance
        .collection('completedOrders')
        .where('technicianId', isEqualTo: currentUserId)
        .where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart),
        )
        .where('timestamp', isLessThan: Timestamp.fromDate(todayEnd))
        .get();

    for (var doc in ordersSnapshot.docs) {
      totalNetProfit += (doc['netProfit'] ?? 0).toDouble();
    }

    if (!mounted) return; // ✅ أضف هذا الشرط قبل setState()

    setState(() {
      technicianName = data['name'] ?? '';
      technicianImageUrl = data['imageUrl'];
      technicianId = data['technicianId']?.toString();
      technicianBalance = totalNetProfit;
      technicianBranch = data['branch'] ?? '';
      technicianRating = (data['rating'] ?? 0).toDouble();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appConfig = Get.find<AppConfigService>();

    return Scaffold(
      body: Obx(
        () => ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Color(
                  int.parse(
                    appConfig.themeSecondaryColor.value.replaceFirst(
                      '#',
                      '0xff',
                    ),
                  ),
                ).withOpacity(0.1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  CircleAvatar(
                    radius: 35,
                    backgroundImage: technicianImageUrl != null
                        ? NetworkImage(technicianImageUrl!)
                        : null,
                    backgroundColor: Colors.grey[200],
                    child: technicianImageUrl == null
                        ? const Icon(Icons.person, size: 40, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    technicianName ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black,
                    ),
                  ),
                  if (technicianId != null)
                    Text(
                      'معرف: $technicianId',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${'المبلغ المُحصل'.tr}: ${technicianBalance?.toStringAsFixed(2) ?? '0'} ${'ج.م'.tr}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.history, color: Colors.blue),
              title: Text("مهامي السابقة".tr),
              onTap: () {
                Get.offAll(() => const PreviousTasksPage());
              },
            ),
            ListTile(
              leading: const Icon(Icons.support_agent, color: Colors.green),
              title: Text("الدعم الفني".tr),
              onTap: () {
                Get.to(() => const SupportPage()); // ✅ تفعيل الصفحة
              },
            ),

            ListTile(
              leading: const Icon(Icons.wallet, color: Colors.green),
              title: Text("المحفظة"),
              onTap: () {
                Get.to(() => const RechargeWalletPage());
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: Text(
                "تسجيل الخروج".tr,
                style: const TextStyle(color: Colors.red),
              ),
              onTap: () async {
                try {
                  await FirebaseAuth.instance.signOut();

                  if (Get.isRegistered<RechargeWalletController>()) {
                    Get.delete<RechargeWalletController>(force: true);
                  }
                  if (Get.isRegistered<WaitingRequestsController>()) {
                    Get.delete<WaitingRequestsController>(force: true);
                  }

                  // ⚙️ تأكد أن AppConfigService متسجل (ما نحذفوش)
                  if (!Get.isRegistered<AppConfigService>()) {
                    Get.put(AppConfigService());
                  }

                  // ⏩ بعدين روح لصفحة تسجيل الدخول
                  Get.offAll(() => const Loginpage());
                } catch (e) {
                  print('Logout error: $e');
                }
              },
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Center(
                child: Text(
                  'الإصدار'.trParams({'v': '1.0.0'}),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
