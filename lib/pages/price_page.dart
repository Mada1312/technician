import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:technican/pages/waiting_customer_response_page.dart.dart';
import 'package:technican/services/app_config_service.dart';

class ConfirmServicePricePage extends StatefulWidget {
  final String requestId;
  final List<Map<String, dynamic>> selectedIssues;

  const ConfirmServicePricePage({
    super.key,
    required this.requestId,
    required this.selectedIssues,
  });

  @override
  State<ConfirmServicePricePage> createState() =>
      _ConfirmServicePricePageState();
}

class _ConfirmServicePricePageState extends State<ConfirmServicePricePage>
    with SingleTickerProviderStateMixin {
  double addedPrice = 0;
  bool isSubmitting = false;
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  final TextEditingController addedPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    addedPriceController.dispose();
    super.dispose();
  }

  Future<void> _submitPrice(double basePrice) async {
    final total = basePrice + addedPrice;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تأكيد السعر'.tr),
        content: Text(
          'هل أنت متأكد من إرسال السعر النهائي: :price جم؟'.trParams({
            'price': total.toString(),
          }),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء'.tr),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('تأكيد'.tr),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => isSubmitting = true);

    try {
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(widget.requestId)
          .update({
            'basePrice': basePrice,
            'addedPrice': addedPrice,
            'finalPrice': total,
            'status': 'waiting_customer_approval',
            'priceApproved': null,
            'issues': widget.selectedIssues,
          });

      if (!mounted) return; // ✅ تحقق قبل استخدام setState أو التنقل
      Get.snackbar('تم الإرسال'.tr, 'تم إرسال السعر للعميل بنجاح.'.tr);

      Get.offAll(
        WaitingCustomerResponsePage(
          arguments: {'requestId': widget.requestId},
          requestId: widget.requestId,
        ),
      );
    } catch (e) {
      if (!mounted) return; // ✅ تحقق قبل عرض Snackbar
      Get.snackbar('خطأ'.tr, 'حدث خطأ أثناء إرسال السعر.'.tr);
    } finally {
      if (!mounted) return; // ✅ تحقق قبل setState
      setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestRef = FirebaseFirestore.instance
        .collection('requests')
        .doc(widget.requestId);
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
          title: Text(
            'مراجعة وتأكيد السعر'.tr,
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          backgroundColor: primaryColor,
        ),
        body: StreamBuilder<DocumentSnapshot>(
          stream: requestRef.snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data!.data() as Map<String, dynamic>?;

            if (data == null) {
              return const Center(child: Text("خطأ في قراءة البيانات"));
            }

            final basePrice = (data['basePrice'] ?? 0).toDouble();

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: FadeTransition(
                opacity: _fadeIn,
                child: Column(
                  children: [
                    Text(
                      'الأعطال المحددة:'.tr,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView(
                        children: widget.selectedIssues.map((issue) {
                          return ListTile(
                            title: Text(
                              (issue['name_ar'] ?? 'بدون اسم').toString(),
                            ),
                            trailing: Text("${issue['price'] ?? 0} جم"),
                          );
                        }).toList(),
                      ),
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'السعر الأساسي:'.tr,
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          "$basePrice جم",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'إضافة من الفني (حتى ٥٠ جم):'.tr,
                          style: const TextStyle(fontSize: 16),
                        ),
                        SizedBox(
                          width: 100,
                          child: TextFormField(
                            controller: addedPriceController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              hintText: '0',
                              suffixText: 'جم',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            ),
                            onChanged: (value) {
                              final parsed = double.tryParse(value) ?? 0;
                              if (parsed <= 50) {
                                setState(() => addedPrice = parsed);
                              } else {
                                setState(() {
                                  addedPrice = 50;
                                  addedPriceController.text = '50';
                                });
                                Get.snackbar(
                                  'تنبيه',
                                  'الزيادة لا يمكن أن تتجاوز ٥٠ جم',
                                  backgroundColor: Colors.orange.shade100,
                                  colorText: Colors.black,
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'السعر النهائي:'.tr,
                          style: const TextStyle(fontSize: 18),
                        ),
                        Text(
                          "${basePrice + addedPrice} جم",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: isSubmitting
                          ? null
                          : () => _submitPrice(basePrice),
                      icon: isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      label: Text(
                        isSubmitting
                            ? 'جاري الإرسال...'.tr
                            : 'تأكيد وإرسال السعر'.tr,
                      ),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    });
  }
}
