import 'dart:async';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppConfigService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // القيم الحالية
  final appName = ''.obs;
  final commissionRate = 0.0.obs;
  final enablePush = false.obs;

  // ✅ ألوان الثيم الجديدة
  final themePrimaryColor = '#1B5E20'.obs;
  final themeSecondaryColor = '#388E3C'.obs;
  final themeAccentColor = '#FFC107'.obs;

  StreamSubscription<DocumentSnapshot>? _settingsListener;

  Future<void> loadConfig({required String appKey}) async {
    try {
      final docRef = _db.collection('config').doc('settings');

      // ✅ أول تحميل
      final doc = await docRef.get();
      _applyConfig(doc.data(), appKey);

      // ✅ تفعيل الـ listener عشان التحديث يكون Real-time
      _settingsListener = docRef.snapshots().listen((snapshot) {
        if (snapshot.exists) {
          _applyConfig(snapshot.data(), appKey);
          print('🔁 Config updated automatically from Firestore.');
        }
      });
    } catch (e) {
      print('❌ Error loading config: $e');
    }
  }

  void _applyConfig(Map<String, dynamic>? data, String appKey) {
    if (data == null) return;

    final appConfig = data['apps']?[appKey];
    if (appConfig == null) return;

    // ✅ تطبيق الإعدادات العامة
    appName.value = appConfig['app_name'] ?? '';
    commissionRate.value = (appConfig['commissionRate'] ?? 0).toDouble();
    enablePush.value = appConfig['notifications']?['enablePush'] ?? false;

    // ✅ تطبيق ألوان الثيم
    themePrimaryColor.value = appConfig['theme']?['primaryColor'] ?? '#1B5E20';
    themeSecondaryColor.value =
        appConfig['theme']?['secondaryColor'] ?? '#388E3C';
    themeAccentColor.value = appConfig['theme']?['accentColor'] ?? '#FFC107';
  }

  void dispose() {
    _settingsListener?.cancel();
  }
}
