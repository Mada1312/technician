import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:technican/pages/HomePage.dart';
import 'package:technican/services/app_config_service.dart';

class PreviousTasksPage extends StatefulWidget {
  const PreviousTasksPage({super.key});

  @override
  State<PreviousTasksPage> createState() => _PreviousTasksPageState();
}

class _PreviousTasksPageState extends State<PreviousTasksPage> {
  DateTime selectedDate = DateTime.now();
  bool isLocaleInitialized = false;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting(Get.locale?.languageCode ?? 'ar', null).then((_) {
      setState(() {
        isLocaleInitialized = true;
      });
    });
  }

  String formatDate(DateTime date) {
    final locale = Get.locale?.languageCode ?? 'ar';
    return DateFormat('d MMMM، y', locale).format(date);
  }

  Future<QuerySnapshot> fetchOrdersForDate(DateTime date) async {
    DateTime startOfDay = DateTime(date.year, date.month, date.day);
    DateTime endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      return Future.error("لم يتم تسجيل دخول الفني.".tr);
    }

    return FirebaseFirestore.instance
        .collection('completedOrders')
        .where('technicianId', isEqualTo: currentUserId)
        .where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .get();
  }

  void _openDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: Get.locale ?? const Locale('ar'),
    );
    if (picked != null && picked != selectedDate) {
      setState(() => selectedDate = picked);
    }
  }

  void _incrementDate() {
    setState(() {
      selectedDate = selectedDate.add(const Duration(days: 1));
    });
  }

  void _decrementDate() {
    setState(() {
      selectedDate = selectedDate.subtract(const Duration(days: 1));
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!isLocaleInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final appConfig = Get.find<AppConfigService>();

    return Obx(() {
      final primaryColor = Color(
        int.parse(appConfig.themePrimaryColor.value.replaceFirst('#', '0xff')),
      );
      final accentColor = Color(
        int.parse(appConfig.themeAccentColor.value.replaceFirst('#', '0xff')),
      );

      return Scaffold(
        appBar: AppBar(
          backgroundColor: primaryColor,
          title: Text("مهامي السابقة".tr),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Get.offAll(() => const WaitingRequestsPage());
            },
          ),
        ),
        body: FutureBuilder<QuerySnapshot>(
          future: fetchOrdersForDate(selectedDate),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text("حدث خطأ".tr));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Column(
                children: [
                  buildDateHeader(accentColor),
                  Expanded(
                    child: Center(
                      child: Text(
                        "لا يوجد مهام في هذا اليوم".tr,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            final orders = snapshot.data!.docs;

            return Column(
              children: [
                buildDateHeader(accentColor),
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "إجمالي المهام".tr,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        "${orders.length}",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final orderData =
                          orders[index].data() as Map<String, dynamic>;
                      final customerName =
                          orderData['customerName'] ?? 'بدون اسم'.tr;

                      String address = 'لا يوجد عنوان'.tr;
                      final rawAddress = orderData['address'];
                      if (rawAddress is String) {
                        address = rawAddress;
                      } else if (rawAddress is Map) {
                        address = rawAddress.values.join("، ");
                      }

                      final String status = orderData['status'] ?? '';
                      final double amountCollected =
                          double.tryParse(
                            orderData['amountCollected']?.toString() ?? '0',
                          ) ??
                          0;
                      final double netProfit =
                          double.tryParse(
                            orderData['netProfit']?.toString() ?? '0',
                          ) ??
                          0;

                      String statusText = switch (status) {
                        'مقبول' => 'مقبول'.tr,
                        'مرفوض' => 'ملغي'.tr,
                        _ => 'غير معروف'.tr,
                      };

                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Card(
                          key: ValueKey(index),
                          margin: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "👤 ${'العميل'.tr}: $customerName",
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "📍 ${'العنوان'.tr}: $address",
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "💰 ${'المبلغ المحصل'.tr}: ${amountCollected.toStringAsFixed(2)} جم",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "💸 ${'ربحك بعد الخصم'.tr}: ${netProfit.toStringAsFixed(2)} جم",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "📄 ${'الحالة'.tr}: $statusText",
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      );
    });
  }

  Widget buildDateHeader(Color accentColor) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: _decrementDate,
          ),
          GestureDetector(
            onTap: _openDatePicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      formatDate(selectedDate),
                      key: ValueKey(selectedDate),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.calendar_today, size: 18),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            onPressed: _incrementDate,
          ),
        ],
      ),
    );
  }
}
