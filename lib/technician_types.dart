// class TechnicianTypes {
//   /// المفاتيح المعتمدة (القيم اللي بتتسجل في فايربيز)
//   static const List<String> serviceKeys = [
//     'Electrician',
//     'Plumber',
//     'Painter',
//     'Carpenter',
//     'AC Technician',
//   ];

//   /// ترجمة أسماء الفنيين (عرض للمستخدم)
//   static const Map<String, Map<String, String>> localizedTitles = {
//     'Electrician': {'en': 'Electrician', 'ar': 'كهربائي'},
//     'Plumber': {'en': 'Plumber', 'ar': 'سباك'},
//     'Painter': {'en': 'Painter', 'ar': 'نقاش'},
//     'Carpenter': {'en': 'Carpenter', 'ar': 'نجار'},
//     'AC Technician': {'en': 'AC Technician', 'ar': 'فني تكييفات'},
//   };

//   /// تحويل من المفتاح إلى الاسم المعروض حسب اللغة
//   static String getLocalizedTitle(String key, String locale) {
//     final normalizedKey = _normalizeKey(key);
//     final originalKey = localizedTitles.keys.firstWhere(
//       (k) => _normalizeKey(k) == normalizedKey,
//       orElse: () => key,
//     );
//     return localizedTitles[originalKey]?[locale] ?? originalKey;
//   }

//   /// تحويل من الاسم المعروض (حسب اللغة) إلى المفتاح الأساسي
//   static String? getKeyFromLocalizedTitle(String title, String locale) {
//     final normalizedTitle = title.toLowerCase().trim();
//     return localizedTitles.entries
//         .firstWhere(
//           (entry) =>
//               entry.value[locale]?.toLowerCase().trim() == normalizedTitle,
//           orElse: () => const MapEntry('', {}),
//         )
//         .key;
//   }

//   /// جلب القائمة كلها مترجمة
//   static List<String> getLocalizedList(String locale) {
//     return serviceKeys.map((key) => getLocalizedTitle(key, locale)).toList();
//   }

//   /// تحويل المفتاح إلى lowercase موحد
//   static String _normalizeKey(String key) => key.toLowerCase().trim();
// }

class TechnicianTypes {
  static const List<String> serviceKeys = [
    'Electrician',
    'Plumber',
    'Painter',
    'Carpenter',
    'AC Technician',
  ];

  static const Map<String, Map<String, String>> localizedTitles = {
    'Electrician': {'en': 'Electrician', 'ar': 'كهربائي'},
    'Plumber': {'en': 'Plumber', 'ar': 'سباك'},
    'Painter': {'en': 'Painter', 'ar': 'نقاش'},
    'Carpenter': {'en': 'Carpenter', 'ar': 'نجار'},
    'AC Technician': {'en': 'AC Technician', 'ar': 'فني تكييفات'},
  };

  static String getLocalizedTitle(String key, String locale) {
    final normalizedKey = _normalizeKey(key);
    final originalKey = localizedTitles.keys.firstWhere(
      (k) => _normalizeKey(k) == normalizedKey,
      orElse: () => key,
    );
    return localizedTitles[originalKey]?[locale] ?? originalKey;
  }

  static String? getKeyFromLocalizedTitle(String title, String locale) {
    final normalizedTitle = title.toLowerCase().trim();

    for (final entry in localizedTitles.entries) {
      final localized = entry.value[locale]?.toLowerCase().trim();
      if (localized == normalizedTitle) {
        print('✅ Matched localized title "$title" → key: ${entry.key}');
        return entry.key;
      }
    }

    print('⚠️ لم يتم العثور على مفتاح للخدمة "$title" بلغة "$locale"');
    return null;
  }

  static List<String> getLocalizedList(String locale) {
    return serviceKeys.map((key) => getLocalizedTitle(key, locale)).toList();
  }

  static String _normalizeKey(String key) => key.toLowerCase().trim();
}
