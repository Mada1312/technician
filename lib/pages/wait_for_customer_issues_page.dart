import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:technican/pages/price_page.dart';
import 'package:get/get.dart';
import 'package:technican/services/app_config_service.dart';

class WaitForCustomerIssuesPage extends StatefulWidget {
  final String requestId;

  const WaitForCustomerIssuesPage({super.key, required this.requestId});

  @override
  State<WaitForCustomerIssuesPage> createState() =>
      _WaitForCustomerIssuesPageState();
}

class _WaitForCustomerIssuesPageState extends State<WaitForCustomerIssuesPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _priceController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeIn;

  final appConfig = Get.find<AppConfigService>();

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeIn = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _priceController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final requestRef = FirebaseFirestore.instance
        .collection('requests')
        .doc(widget.requestId);

    return Obx(
      () => Scaffold(
        appBar: AppBar(
          title: Text(
            "في انتظار العميل".tr,
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          backgroundColor: Color(
            int.parse(
              appConfig.themePrimaryColor.value.replaceFirst('#', '0xff'),
            ),
          ),
        ),
        body: StreamBuilder<DocumentSnapshot>(
          stream: requestRef.snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data!.data() as Map<String, dynamic>?;
            if (data == null) {
              return Center(child: Text("لا توجد بيانات".tr));
            }

            final status = data['status'] ?? '';
            final issues = data['issues'] as List<dynamic>?;

            // 📌 الحالة: في انتظار تسعير الأدمن
            if (status == "waiting_admin_pricing") {
              return _buildStatusView(
                icon: Icons.hourglass_top,
                color: Colors.orange,
                text: "برجاء انتظار تحديد السعر من قبل الادمن".tr,
              );
            }

            // 📌 الحالة: في انتظار الفني → تحويل تلقائي
            if (status == "waiting_technican") {
              final selectedIssues = (issues ?? []).map<Map<String, dynamic>>((
                e,
              ) {
                final issue = Map<String, dynamic>.from(e);
                return {
                  'id': issue['id'] ?? '',
                  'category': issue['category'] ?? '',
                  'description': issue['description'] ?? '',
                  'name_ar': issue['name_ar'] ?? '',
                  'price': (issue['price'] is num) ? issue['price'] : 0,
                };
              }).toList();

              Future.microtask(() {
                Get.off(
                  () => ConfirmServicePricePage(
                    requestId: widget.requestId,
                    selectedIssues: selectedIssues,
                  ),
                );
              });

              return const SizedBox();
            }

            // 📌 الحالة: انتظار العميل لاختيار الأعطال
            if (issues == null || issues.isEmpty) {
              return _buildStatusView(
                icon: Icons.hourglass_top,
                color: Colors.teal,
                text: "جارٍ انتظار العميل لاختيار الأعطال...".tr,
              );
            }

            // 📌 الحالة: تم اختيار الأعطال → عرض صفحة التأكيد
            final selectedIssues = issues.map<Map<String, dynamic>>((e) {
              final issue = Map<String, dynamic>.from(e);
              return {
                'id': issue['id'] ?? '',
                'category': issue['category'] ?? '',
                'description': issue['description'] ?? '',
                'name_ar': issue['name_ar'] ?? '',
                'price': (issue['price'] is num) ? issue['price'] : 0,
              };
            }).toList();

            return ConfirmServicePricePage(
              requestId: widget.requestId,
              selectedIssues: selectedIssues,
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusView({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Obx(
      () => Center(
        child: FadeTransition(
          opacity: _fadeIn,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 80, color: color),
              const SizedBox(height: 20),
              Text(
                text,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Color(
                    int.parse(
                      appConfig.themeAccentColor.value.replaceFirst(
                        '#',
                        '0xff',
                      ),
                    ),
                  ),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                "يتم التحديث تلقائيًا عند أي تغيير".tr,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(
                    int.parse(
                      appConfig.themePrimaryColor.value.replaceFirst(
                        '#',
                        '0xff',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
