import 'package:get/get.dart';

class MyTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'en_US': {
      'Sal7ly': 'Sal7ly',
      'Request Technician': 'Request Technician',
      'Account Settings': 'Account Settings',
      'Settings': 'Settings',
      'Log Out': 'Log Out',
      'Menu': 'Menu',
      'Electrician': 'Electrician',
      'Plumber': 'Plumber',
      'Painter': 'Painter',
      'Carpenter': 'Carpenter',
      'AC Technician': 'AC Technician',

      // Account settings
      'Personal Information': 'Personal Information',
      'Saved Address': 'Saved Address',
      'Email': 'Email',
      'Saved Cards': 'Saved Cards',
      'Notifications': 'Notifications',
      'Delete Account': 'Delete Account',
      'Change Language': 'Change Language',
      'English': 'English',
      'Arabic': 'Arabic',

      // Request flow
      'Searching for': 'Searching for :service',
      'Looking for nearest': 'Looking for nearest :service...',
      'seconds remaining': 'seconds remaining',
      'Cancel Request': 'Cancel Request',
      'Technician Assigned': 'Technician Assigned',
      'Name': 'Name',
      'Phone': 'Phone Number',
      'Rating': 'Rating',
      'Arrival Time': 'Arrival Time',
      'min': 'min',
      'minutes': 'minutes',
      'OK': 'OK',
      'Request Timeout': 'Request Timeout',
      'No technician found.': 'No technician found.',
      'Incomplete user data': 'Incomplete user data',

      // Notifications Page
      'Notifications settings coming soon...':
          'Notifications settings coming soon...',

      // Saved Cards Page
      'This feature is coming soon...': 'This feature is coming soon...',

      // Email Page
      'Email Address': 'Email Address',
      'Registered Email': 'Registered Email',
      'No email available': 'No email available',
      'Note: Email change is not allowed for security reasons.':
          'Note: Email change is not allowed for security reasons.',

      // Saved Address Page
      'Governorate': 'Governorate',
      'City': 'City',
      'Area': 'Area',
      'Street': 'Street',
      'Building Number': 'Building Number',
      'Floor Number': 'Floor Number',
      'Apartment Number': 'Apartment Number',
      'Save Address': 'Save Address',
      'Success': 'Success',
      'Address updated successfully.': 'Address updated successfully.',

      // Delete Account
      'Warning!': 'Warning!',
      'Deleting your account will permanently erase all your data. This action cannot be undone.':
          'Deleting your account will permanently erase all your data. This action cannot be undone.',
      'Delete My Account': 'Delete My Account',
      'Re-authenticate': 'Re-authenticate',
      'Password': 'Password',
      'Confirm Delete': 'Confirm Delete',
      'Cancel': 'Cancel',
      'Deleted': 'Deleted',
      'Account deleted successfully': 'Account deleted successfully',
      'Failed to delete account': 'Failed to delete account',
      'service': 'service',

      // Edit Personal Info
      'Save': 'Save',
      'Personal information updated successfully.':
          'Personal information updated successfully.',

      // Pricing page
      'Pricing': 'Pricing',
      'Service Pricing': 'Service Pricing',

      // Issues page
      "Choose the issues you're facing": "Choose the issues you're facing",
      'Other': 'Other',
      'Write the issue': 'Write the issue',
      'Confirm Issues': 'Confirm Issues',
      'Alert': 'Alert',
      'Please select or write the issue.': 'Please select or write the issue.',
      'Sent': 'Sent',
      'Issues submitted successfully.': 'Issues submitted successfully.',
      'Error occurred while sending': 'Error occurred while sending',
      'Review and Confirm Price': 'Review and Confirm Price',
      'Selected Issues:': 'Selected Issues:',
      'Base Price:': 'Base Price:',
      'Technical Addition (up to 50 EGP):':
          'Technical Addition (up to 50 EGP):',
      'Final Price:': 'Final Price:',
      'Confirm and Send Price': 'Confirm and Send Price',
      'Sending...': 'Sending...',
      'Confirm Price': 'Confirm Price',
      'Are you sure to send final price: :price EGP?':
          'Are you sure to send final price: :price EGP?',
      'Final price sent to customer successfully.':
          'Final price sent to customer successfully.',
      'Error': 'Error',
      'Previous Tasks': 'Previous Tasks',
      'Total Orders': 'Total Orders',
      'No tasks found on this day': 'No tasks found on this day',
      'completed': 'Completed',
      'in_progress': 'In Progress',
      'cancelled': 'Cancelled',
      'navigate to customer': 'Navigate to Customer',
      'customer location': 'Customer Location',
      'your location': 'Your Location',
      'open in google maps': 'Open in Google Maps',
      'confirm arrival': 'Confirm Arrival',
      'error': 'Error',
      'arrival error': 'An error occurred while confirming arrival',
      'cannot open google maps': 'Could not open Google Maps',
      'Start Work': 'Start Work',
      'Work in progress...': 'Work in progress...',
      'Finish': 'Finish',
      'Work completed successfully': 'Work completed successfully',
      'Time spent': 'Time spent',
      'Rate the Customer': 'Rate the Customer',
      'Submit Rating': 'Submit Rating',
      'Enter your notes': 'Enter your notes',
      'Rating submitted successfully': 'Rating submitted successfully',
      'Error submitting rating': 'Error submitting rating',
      'Confirm Arrival': 'Confirm Arrival',
      'Arrival confirmed': 'Arrival confirmed',
      'Failed to confirm arrival': 'Failed to confirm arrival',
      '00:00': '00:00',
      'Waiting for customer': 'Waiting for customer',
      'Waiting for customer to choose issues...':
          'Waiting for customer to choose issues...',

      // Pricing Confirmation Page
      'Confirm': 'Confirm',

      'An error occurred while sending the price.':
          'An error occurred while sending the price.',

      // Previous Tasks
      'No tasks on this day': 'No tasks on this day',
      'Total Tasks': 'Total Tasks',
      'Customer': 'Customer',
      'Address': 'Address',
      'Amount Collected': 'Amount Collected',
      'Net Profit': 'Net Profit',
      'Status': 'Status',
      'Accepted': 'Accepted',
      'Cancelled': 'Cancelled',
      'Unknown': 'Unknown',
    },

    'ar_EG': {
      'Sal7ly': 'صلحلي',
      'Request Technician': 'طلب فني',
      'Account Settings': 'إعدادات الحساب',
      'Settings': 'الإعدادات',
      'Log Out': 'تسجيل الخروج',
      'Menu': 'القائمة',
      'Electrician': 'كهربائي',
      'Plumber': 'سباك',
      'Painter': 'نقاش',
      'Carpenter': 'نجار',
      'AC Technician': 'فني تكييفات',

      // Account settings
      'Personal Information': 'المعلومات الشخصية',
      'Saved Address': 'العنوان المحفوظ',
      'Email': 'البريد الإلكتروني',
      'Saved Cards': 'الكروت المحفوظة',
      'Notifications': 'الإشعارات',
      'Delete Account': 'حذف الحساب',
      'Change Language': 'تغيير اللغة',
      'English': 'الإنجليزية',
      'Arabic': 'العربية',

      // Request flow
      'Searching for': 'جارٍ البحث عن :service',
      'Looking for nearest': 'جارٍ البحث عن أقرب :service...',
      'seconds remaining': 'ثانية متبقية',
      'Cancel Request': 'إلغاء الطلب',
      'Technician Assigned': 'تم تعيين الفني',
      'Name': 'الاسم',
      'Phone': 'رقم الهاتف',
      'Rating': 'التقييم',
      'Arrival Time': 'وقت الوصول',
      'min': 'دقيقة',
      'minutes': 'دقيقة',
      'OK': 'موافق',
      'Request Timeout': 'انتهى الوقت',
      'No technician found.': 'لم يتم العثور على فني',
      'Incomplete user data': 'بيانات المستخدم غير مكتملة',

      // Notifications Page
      'Notifications settings coming soon...':
          'إعدادات الإشعارات قادمة قريبًا...',

      // Saved Cards Page
      'This feature is coming soon...': 'هذه الميزة قادمة قريبًا...',

      // Email Page
      'Email Address': 'عنوان البريد الإلكتروني',
      'Registered Email': 'البريد الإلكتروني المسجل',
      'No email available': 'لا يوجد بريد إلكتروني متاح',
      'Note: Email change is not allowed for security reasons.':
          'ملاحظة: لا يُسمح بتغيير البريد الإلكتروني لأسباب أمنية.',

      // Saved Address Page
      'Governorate': 'المحافظة',
      'City': 'المدينة',
      'Area': 'المنطقة',
      'Street': 'الشارع',
      'Building Number': 'رقم المبنى',
      'Floor Number': 'رقم الدور',
      'Apartment Number': 'رقم الشقة',
      'Save Address': 'حفظ العنوان',
      'Success': 'تم بنجاح',
      'Address updated successfully.': 'تم تحديث العنوان بنجاح.',

      // Delete Account
      'Warning!': 'تحذير!',
      'Deleting your account will permanently erase all your data. This action cannot be undone.':
          'حذف حسابك سيمحو جميع بياناتك بشكل دائم. لا يمكن التراجع عن هذا الإجراء.',
      'Delete My Account': 'احذف حسابي',
      'Re-authenticate': 'أعد تسجيل الدخول',
      'Password': 'كلمة المرور',
      'Confirm Delete': 'تأكيد الحذف',
      'Cancel': 'إلغاء',
      'Deleted': 'تم الحذف',
      'Account deleted successfully': 'تم حذف الحساب بنجاح',
      'Failed to delete account': 'فشل في حذف الحساب',
      'service': 'خدمة',

      // Edit Personal Info
      'Save': 'حفظ',
      'Personal information updated successfully.':
          'تم تحديث المعلومات الشخصية بنجاح.',

      // Pricing page
      'Pricing': 'التسعيرة',
      'Service Pricing': 'تسعيرة الخدمة',

      // Issues page
      "Choose the issues you're facing": "اختر الأعطال التي تواجهك",
      'Other': 'أخرى',
      'Write the issue': 'اكتب المشكلة',
      'Confirm Issues': 'تأكيد الأعطال',
      'Alert': 'تنبيه',
      'Please select or write the issue.': 'يرجى اختيار أو كتابة المشكلة.',
      'Sent': 'تم',
      'Issues submitted successfully.': 'تم إرسال الأعطال بنجاح.',
      'Error occurred while sending': 'حدث خطأ أثناء الإرسال',
      'Review and Confirm Price': 'مراجعة وتأكيد السعر',
      'Selected Issues:': 'المشكلات المختارة:',
      'Base Price:': 'السعر الأساسى:',
      'Technical Addition (up to 50 EGP):': 'إضافة فنية (حد أقصى ٥٠ جم):',
      'Final Price:': 'السعر النهائى:',
      'Confirm and Send Price': 'تأكيد السعر وإرساله',
      'Sending...': 'جارى الإرسال...',
      'Confirm Price': 'تأكيد السعر',
      'Are you sure to send final price: :price EGP?':
          'هل أنت متأكد من إرسال السعر النهائى: :price جم؟',
      'Final price sent to customer successfully.':
          'تم إرسال السعر النهائي للعميل بنجاح.',
      'Error': 'خطأ',
      'Previous Tasks': 'مهامي السابقة',
      'Total Orders': 'عدد الطلبات',
      'No tasks found on this day': 'لا توجد طلبات في هذا اليوم',
      'completed': 'تم التنفيذ',
      'in_progress': 'قيد التنفيذ',
      'cancelled': 'أُلغي',
      'navigate to customer': 'التوجه للعميل',
      'customer location': 'موقع العميل',
      'your location': 'موقعك',
      'open in google maps': 'افتح في Google Maps',
      'confirm arrival': 'تأكيد الوصول',
      'error': 'خطأ',
      'arrival error': 'حدث خطأ أثناء تأكيد الوصول',
      'cannot open google maps': 'تعذر فتح Google Maps',
      'Start Work': 'بدء العمل',
      'Work in progress...': 'جاري تنفيذ العمل...',
      'Finish': 'تم الانتهاء',
      'Work completed successfully': 'تم الانتهاء من العمل بنجاح',
      'Time spent': 'الوقت المستغرق',
      'Rate the Customer': 'قيم العميل',
      'Submit Rating': 'إرسال التقييم',
      'Enter your notes': 'أدخل ملاحظاتك',
      'Rating submitted successfully': 'تم إرسال التقييم بنجاح',
      'Error submitting rating': 'حدث خطأ أثناء إرسال التقييم',
      'Confirm Arrival': 'تأكيد الوصول',
      'Arrival confirmed': 'تم تأكيد الوصول',
      'Failed to confirm arrival': 'فشل في تأكيد الوصول',
      '00:00': '٠٠:٠٠',
      'Waiting for customer': 'في انتظار العميل',
      'Waiting for customer to choose issues...':
          'جارٍ انتظار العميل لاختيار الأعطال...',

      // Pricing Confirmation Page
      'Confirm': 'تأكيد',

      'An error occurred while sending the price.':
          'حدث خطأ أثناء إرسال السعر.',

      // المهام السابقة
      'No tasks on this day': 'لا يوجد مهام في هذا اليوم',
      'Total Tasks': 'إجمالي المهام',
      'Customer': 'العميل',
      'Address': 'العنوان',
      'Amount Collected': 'المبلغ المحصل',
      'Net Profit': 'ربحك بعد الخصم',
      'Status': 'الحالة',
      'Accepted': 'مقبول',
      'Cancelled': 'ملغي',
      'Unknown': 'غير معروف',
    },
  };
}
