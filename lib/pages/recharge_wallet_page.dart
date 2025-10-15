import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:technican/recharge_wallet_controller.dart';
import 'package:technican/services/app_config_service.dart';

class RechargeWalletPage extends StatelessWidget {
  const RechargeWalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ تسجيل الكنترولر في GetX (علشان ما يظهرش الخطأ)
    final controller = Get.put(RechargeWalletController());
    final config = Get.find<AppConfigService>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(
          int.parse(config.themePrimaryColor.value.replaceFirst('#', '0xff')),
        ),
        title: const Text('شحن المحفظة', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Obx(() {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ الرصيد الحالي
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(
                    int.parse(
                      config.themeSecondaryColor.value.replaceFirst(
                        '#',
                        '0xff',
                      ),
                    ),
                  ).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'رصيدك الحالي: ${controller.currentBalance.value.toStringAsFixed(2)} ج.م',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ✅ إدخال المبلغ
              TextField(
                controller: controller.amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'أدخل المبلغ المراد شحنه',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.attach_money),
                ),
              ),

              const SizedBox(height: 20),

              // ✅ زر الشحن
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(
                      int.parse(
                        config.themePrimaryColor.value.replaceFirst(
                          '#',
                          '0xff',
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  onPressed: controller.processRechargeRequest,
                  icon: const Icon(Icons.payment),
                  label: Center(
                    child: const Text(
                      "شحن الآن",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              Center(
                child: const Text(
                  "سجل عمليات الشحن السابقة:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),

              // ✅ سجل عمليات الشحن
              Expanded(
                child: controller.rechargeHistory.isEmpty
                    ? const Center(child: Text("لا يوجد عمليات شحن سابقة"))
                    : ListView.builder(
                        itemCount: controller.rechargeHistory.length,
                        itemBuilder: (context, index) {
                          final recharge = controller.rechargeHistory[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              leading: const Icon(Icons.history),
                              title: Text(
                                "${recharge['amount']} ج.م",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                controller.formatTimestamp(
                                  recharge['timestamp'],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
