import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:technican/auth.dart';
import 'package:technican/mytranslations.dart';
import 'package:technican/pages/recharge_wallet_page.dart';
import 'package:technican/recharge_wallet_controller.dart';
import 'package:technican/webview_payment_page.dart';
import 'firebase_options.dart';

// ✅ import config service
import 'package:technican/services/app_config_service.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.debug,
        appleProvider: AppleProvider.debug,
      );

      await GetStorage.init();
      final box = GetStorage();
      await box.writeIfNull('first_run', true);

      // ✅ تحميل إعدادات التطبيق من Firebase
      final config = Get.put(AppConfigService());
      await config.loadConfig(appKey: 'technicians');

      config.appName.listen((value) {
        print('📢 App Name changed: $value');
      });

      // ✅ عرض القيم فى الكونسول للتأكد
      print('✅ App Name: ${config.appName.value}');
      print('✅ Commission Rate: ${config.commissionRate.value}%');
      print(
        '✅ Push Notifications: ${config.enablePush.value ? 'Enabled' : 'Disabled'}',
      );

      Get.put(RechargeWalletController(), permanent: true);

      // ✅ تمرير config داخل MyApp علشان نستخدم الألوان
      runApp(MyApp(config: config));
    },
    (error, stackTrace) {
      debugPrint('Uncaught error: $error');
    },
  );
}

class MyApp extends StatelessWidget {
  final AppConfigService config;
  const MyApp({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // ✅ ألوان الديناميكية جاية من Firebase config
      final theme = ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(
            int.parse(config.themePrimaryColor.value.replaceFirst('#', '0xff')),
          ),
          primary: Color(
            int.parse(config.themePrimaryColor.value.replaceFirst('#', '0xff')),
          ),
          secondary: Color(
            int.parse(
              config.themeSecondaryColor.value.replaceFirst('#', '0xff'),
            ),
          ),
        ),
        useMaterial3: true,
      );

      return GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: config.appName.value,
        theme: theme,
        home: const AuthPage(),
        translations: MyTranslations(),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ar'), Locale('en')],
        locale: Get.deviceLocale ?? const Locale('ar'),
        fallbackLocale: const Locale('en'),
        getPages: [
          GetPage(
            name: '/recharge-wallet',
            page: () => const RechargeWalletPage(),
            binding: BindingsBuilder(() {
              Get.lazyPut<RechargeWalletController>(
                () => RechargeWalletController(),
              );
            }),
          ),
          GetPage(
            name: '/webview',
            page: () {
              final args = Get.arguments as Map<String, dynamic>;
              return WebViewPaymentPage(
                paymentUrl: args['paymentUrl'],
                amount: args['amount'],
                onPaymentSuccess: args['onSuccess'],
                onPaymentError: args['onError'],
              );
            },
          ),
        ],
      );
    });
  }
}
