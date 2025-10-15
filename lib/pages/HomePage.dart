import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:technican/pages/menu.dart';
import 'package:technican/pages/recharge_wallet_page.dart';
import 'package:technican/waiting_requests_controller.dart';
import 'package:technican/technician_types.dart';
import 'package:technican/recharge_wallet_controller.dart';
import 'package:technican/services/app_config_service.dart'; // ✅ مهم

class WaitingRequestsPage extends StatelessWidget {
  const WaitingRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<RechargeWalletController>()) {
      Get.put(RechargeWalletController());
    }

    final controller = Get.put(WaitingRequestsController());
    final locale = Localizations.localeOf(context).languageCode;

    // ✅ Listener لمتابعة الرصيد لحظيًا
    final walletController = Get.find<RechargeWalletController>();
    ever(walletController.currentBalance, (newBalance) {
      controller.technicianBalance.value =
          walletController.currentBalance.value;

      // ✅ Snackbar بلون من AppConfigService
      final config = Get.find<AppConfigService>();
      Get.snackbar(
        "💰 تحديث الرصيد",
        "رصيدك الحالي: ${newBalance.toStringAsFixed(2)} جنيه",
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
        backgroundColor: Color(
          int.parse(config.themePrimaryColor.value.replaceFirst('#', '0xff')),
        ).withOpacity(0.9),
        colorText: Colors.white,
      );
    });

    final config = Get.find<AppConfigService>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(
          int.parse(config.themePrimaryColor.value.replaceFirst('#', '0xff')),
        ),
        centerTitle: true,
        title: const Text(
          "الطلبات المتاحة",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ), // ✅ يجعل الأيقونة بيضاء
      ),

      drawer: const Drawer(child: HomePage()),
      body: Obx(() {
        if (controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.technicianBalance.value <= 0) {
          return _buildNoBalance(config);
        }

        if (controller.requests.isEmpty) {
          return const Center(child: Text("لا توجد طلبات حالياً."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.requests.length,
          itemBuilder: (context, index) {
            final doc = controller.requests[index];
            final data = doc.data() as Map<String, dynamic>;
            final lat = data['location']['lat'];
            final lng = data['location']['lng'];
            final distance = controller
                .calculateDistance(
                  controller.currentPosition!.latitude,
                  controller.currentPosition!.longitude,
                  lat,
                  lng,
                )
                .toStringAsFixed(2);

            final localizedService = TechnicianTypes.getLocalizedTitle(
              data['service'] ?? '',
              locale,
            );

            return Obx(
              () => Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("الاسم: ${data['userName'] ?? 'غير متوفر'}"),
                      Text("الهاتف: ${data['userPhone'] ?? 'غير متوفر'}"),
                      Text("العنوان: ${data['userAddress'] ?? 'غير متوفر'}"),
                      Text("الخدمة: $localizedService"),
                      Text("المسافة: $distance كم"),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check_circle),
                        label: const Text("قبول الطلب"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(
                            int.parse(
                              config.themePrimaryColor.value.replaceFirst(
                                '#',
                                '0xff',
                              ),
                            ),
                          ),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          Get.defaultDialog(
                            title: "تأكيد قبول الطلب",
                            middleText: "هل تريد قبول هذا الطلب؟",
                            textCancel: "رفض",
                            textConfirm: "قبول",
                            confirmTextColor: Colors.white,
                            onConfirm: () {
                              Get.back();
                              controller.acceptRequest(doc, distance);
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildNoBalance(AppConfigService config) {
    return Obx(
      () => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Color(
                int.parse(
                  config.themeAccentColor.value.replaceFirst('#', '0xff'),
                ),
              ),
              size: 60,
            ),
            const SizedBox(height: 16),
            const Text(
              'رصيدك صفر أو أقل.\nلا يمكنك استقبال الطلبات.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Get.to(() => const RechargeWalletPage()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(
                  int.parse(
                    config.themeAccentColor.value.replaceFirst('#', '0xff'),
                  ),
                ),
              ),
              child: const Text(
                "شحن المحفظة",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
