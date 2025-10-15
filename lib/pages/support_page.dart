import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:technican/services/app_config_service.dart';

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;

  String? ticketId;
  bool _loadingTicket = true;
  bool _chatStarted = false;
  String technicianName = "الفني";
  String technicianId = "";
  String ticketStatus = "";

  @override
  void initState() {
    super.initState();
    _loadTechnicianData();
  }

  /// ✅ تحميل بيانات الفني
  Future<void> _loadTechnicianData() async {
    try {
      technicianId = user?.uid ?? '';
      if (technicianId.isEmpty) return;

      final doc = await _firestore
          .collection('technicians')
          .doc(technicianId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        technicianName = data['name'] ?? 'الفني';
      }
    } catch (e) {
      debugPrint('❌ خطأ أثناء تحميل بيانات الفني: $e');
    } finally {
      setState(() => _loadingTicket = false);
    }
  }

  /// ✅ بدء المحادثة (إنشاء تيكت للفني)
  Future<void> _startChat() async {
    setState(() => _loadingTicket = true);

    try {
      final newTicket = await _firestore.collection('supportTickets').add({
        'userId': technicianId,
        'userName': technicianName,
        'userType': 'Technician',
        'status': 'pending',
        'issue': '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      ticketId = newTicket.id;
      ticketStatus = "pending";
      _chatStarted = true;
    } catch (e) {
      Get.snackbar(
        "خطأ",
        "حدث خطأ أثناء بدء المحادثة.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _loadingTicket = false);
    }
  }

  /// ✅ إرسال رسالة
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || ticketId == null) return;

    try {
      await _firestore
          .collection('supportTickets')
          .doc(ticketId)
          .collection('messages')
          .add({
            'message': text,
            'sender': 'technician',
            'timestamp': FieldValue.serverTimestamp(),
          });

      _messageController.clear();
    } catch (e) {
      Get.snackbar(
        "خطأ",
        "فشل في إرسال الرسالة.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// ✅ Stream لحالة التيكت
  Stream<DocumentSnapshot>? getTicketStream() {
    if (ticketId == null) return null;
    return _firestore.collection('supportTickets').doc(ticketId).snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final config = Get.find<AppConfigService>();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("الدعم الفني", style: TextStyle(color: Colors.white)),
        backgroundColor: Color(
          int.parse(config.themePrimaryColor.value.replaceFirst('#', '0xff')),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loadingTicket
          ? const Center(child: CircularProgressIndicator())
          : !_chatStarted
          // 💬 لسه مابدأش محادثة
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.support_agent, size: 80, color: Colors.grey),
                  const SizedBox(height: 20),
                  const Text(
                    "مرحبًا 👋\nكيف يمكننا مساعدتك اليوم؟",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _startChat,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(
                        int.parse(
                          config.themeAccentColor.value.replaceFirst(
                            '#',
                            '0xff',
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "ابدأ المحادثة",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            )
          : StreamBuilder<DocumentSnapshot>(
              stream: getTicketStream(),
              builder: (context, ticketSnapshot) {
                if (!ticketSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data =
                    ticketSnapshot.data!.data() as Map<String, dynamic>?;
                ticketStatus = data?['status'] ?? 'pending';

                // 🎯 لو التيكت اتقفلت
                if (ticketStatus == 'closed') {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 80,
                          color: Colors.green,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "تم إغلاق المحادثة ✅\nنشكرك على تواصلك معنا ❤️",
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              ticketId = null;
                              _chatStarted = false;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(
                              int.parse(
                                config.themeAccentColor.value.replaceFirst(
                                  '#',
                                  '0xff',
                                ),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            "ابدأ محادثة جديدة",
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // 💬 عرض المحادثة
                return Column(
                  children: [
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: _firestore
                            .collection('supportTickets')
                            .doc(ticketId)
                            .collection('messages')
                            .orderBy('timestamp', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final messages = snapshot.data!.docs;

                          if (messages.isEmpty) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text(
                                  "من فضلك اكتب مشكلتك وسيتم الرد عليك خلال دقائق.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            reverse: true,
                            padding: const EdgeInsets.all(8),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final msg =
                                  messages[index].data()
                                      as Map<String, dynamic>;
                              final isTechnician =
                                  msg['sender'] == 'technician';

                              return Align(
                                alignment: isTechnician
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 4.0,
                                  ),
                                  padding: const EdgeInsets.all(10.0),
                                  decoration: BoxDecoration(
                                    color: isTechnician
                                        ? Color(
                                            int.parse(
                                              config.themeAccentColor.value
                                                  .replaceFirst('#', '0xff'),
                                            ),
                                          )
                                        : Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    msg['message'] ?? '',
                                    style: TextStyle(
                                      color: isTechnician
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),

                    // 📨 إدخال الرسالة
                    Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.grey.shade100,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              decoration: const InputDecoration(
                                hintText: "اكتب رسالتك هنا...",
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _sendMessage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(
                                int.parse(
                                  config.themeAccentColor.value.replaceFirst(
                                    '#',
                                    '0xff',
                                  ),
                                ),
                              ),
                              padding: const EdgeInsets.all(12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Icon(Icons.send, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
