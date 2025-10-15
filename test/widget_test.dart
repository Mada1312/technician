import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:technican/main.dart';
import 'package:technican/services/app_config_service.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // 🧩 إنشاء نسخة وهمية من AppConfigService
    final mockConfig = Get.put(AppConfigService());

    // 🧩 تمريرها إلى MyApp كما هو مطلوب
    await tester.pumpWidget(MyApp(config: mockConfig));

    // التحقق من وجود النصوص الافتراضية (للتأكد إن التطبيق اشتغل)
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // محاولة الضغط على أيقونة +
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // تحقق إن العداد اتغير
    expect(find.text('1'), findsOneWidget);
  });
}
