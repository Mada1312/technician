import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:technican/pages/navigate_to_customer_page.dart';

class WaitingRequestsController extends GetxController {
  Position? currentPosition;
  StreamSubscription<Position>? _positionStream;

  var technicianName = ''.obs;
  var technicianImageUrl = ''.obs;
  var technicianId = ''.obs;
  var technicianBalance = 0.0.obs;
  var technicianBranch = ''.obs;
  var technicianRating = 0.0.obs;
  var technicianPhone = ''.obs;
  var technicianSpecialty = ''.obs;

  var requests = <QueryDocumentSnapshot>[].obs;
  var loading = true.obs;

  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void onInit() {
    super.onInit();
    _startLocationUpdates();
    _fetchTechnicianData();
    _setTechnicianStatusToSearching();
  }

  @override
  void onClose() {
    _positionStream?.cancel();
    super.onClose();
  }

  void _startLocationUpdates() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      _positionStream = Geolocator.getPositionStream().listen((position) {
        currentPosition = position;

        if (currentUserId.isNotEmpty) {
          FirebaseFirestore.instance
              .collection('technicians')
              .doc(currentUserId)
              .update({
                'location': {
                  'lat': position.latitude,
                  'lng': position.longitude,
                },
                'status': 'searching',
              });
        }

        _listenToRequests();
      });
    }
  }

  Future<void> _fetchTechnicianData() async {
    if (currentUserId.isEmpty) return;

    final doc = await FirebaseFirestore.instance
        .collection('technicians')
        .doc(currentUserId)
        .get();
    if (doc.exists) {
      final data = doc.data()!;
      technicianName.value = data['name'] ?? '';
      technicianImageUrl.value = data['imageUrl'] ?? '';
      technicianId.value = data['technicianId']?.toString() ?? '';
      technicianBalance.value = (data['balance'] ?? 0).toDouble();
      technicianBranch.value = data['branch'] ?? '';
      technicianRating.value = (data['rating'] ?? 0).toDouble();
      technicianPhone.value = data['phone']?.toString() ?? '';
      technicianSpecialty.value = data['service'] ?? data['specialty'] ?? '';
    }
  }

  void _setTechnicianStatusToSearching() {
    if (currentUserId.isNotEmpty) {
      FirebaseFirestore.instance
          .collection('technicians')
          .doc(currentUserId)
          .update({'status': 'searching'});
    }
  }

  void _listenToRequests() {
    if (currentPosition == null) return;

    final serviceKey = technicianSpecialty.value.trim().toLowerCase();

    FirebaseFirestore.instance
        .collection('requests')
        .where('status', isEqualTo: 'searching')
        .snapshots()
        .listen((snapshot) {
          final filtered = snapshot.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;

            final lat = data['location']?['lat'];
            final lng = data['location']?['lng'];
            if (lat == null || lng == null) return false;

            // 🟢 فلترة الخدمة بين الفني والعميل بشكل مرن
            final requestService = (data['service'] ?? '')
                .toString()
                .trim()
                .toLowerCase();

            final normalizedTech = _normalizeService(serviceKey);
            final normalizedRequest = _normalizeService(requestService);

            if (normalizedTech != normalizedRequest) return false;

            final distance = calculateDistance(
              currentPosition!.latitude,
              currentPosition!.longitude,
              lat,
              lng,
            );

            // الطلب يظهر فقط لو جوه 10 كم
            return distance <= 10;
          }).toList();

          requests.assignAll(filtered);
          loading.value = false;
        });
  }

  /// 🟢 دالة للتوحيد بين العربي/الإنجليزي (uppercase/lowercase)
  String _normalizeService(String service) {
    service = service.toLowerCase();

    // Mapping عربي ↔ إنجليزي
    final mapping = {
      'electrician': ['electrician', 'كهربائي', 'كهربا'],
      'plumber': ['plumber', 'سباك'],
      'painter': ['painter', 'نقاش', 'دهان'],
      'carpenter': ['carpenter', 'نجار'],
      'ac technician': ['ac technician', 'فني تكييفات', 'تكييف'],
    };

    for (var key in mapping.keys) {
      if (mapping[key]!.any((word) => service.contains(word))) {
        return key;
      }
    }

    return service;
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a =
        0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  Future<void> acceptRequest(QueryDocumentSnapshot doc, String distance) async {
    final confirm = await Get.defaultDialog<bool>(
      title: "تأكيد",
      middleText: "هل تريد قبول هذا الطلب؟",
      textCancel: "إلغاء",
      textConfirm: "تأكيد",
      confirmTextColor: Color.fromARGB(255, 255, 255, 255),
      onCancel: () => Get.back(result: false),
      onConfirm: () => Get.back(result: true),
    );

    if (confirm != true) return;

    final docRef = FirebaseFirestore.instance
        .collection('requests')
        .doc(doc.id);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final freshSnap = await transaction.get(docRef);
        final freshData = freshSnap.data() as Map<String, dynamic>?;

        if (freshData == null || freshData['status'] != 'searching') {
          Get.snackbar(
            "تنبيه",
            "تم قبول الطلب من فني آخر.",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color.fromARGB(255, 255, 165, 0),
            colorText: const Color.fromARGB(255, 255, 255, 255),
          );
          return;
        }

        final distanceDouble = double.tryParse(distance) ?? 0;
        final arrivalTime = (distanceDouble / 0.05).ceil();

        transaction.update(docRef, {
          'status': 'assigned',
          'technician': {
            'id': currentUserId,
            'name': technicianName.value,
            'phone': technicianPhone.value,
            'rating': technicianRating.value,
            'arrivalTime': arrivalTime,
            'distance': distanceDouble,
            'specialty': technicianSpecialty.value,
            'location': {
              'lat': currentPosition?.latitude,
              'lng': currentPosition?.longitude,
            },
          },
        });

        transaction.update(
          FirebaseFirestore.instance
              .collection('technicians')
              .doc(currentUserId),
          {'status': 'busy'},
        );
      });

      final data = doc.data() as Map<String, dynamic>;

      Get.offAll(
        () => NavigateToCustomerPage(
          customerLocation: LatLng(
            data['location']['lat'],
            data['location']['lng'],
          ),
          requestId: doc.id,
          technicianId: technicianId.value, // ✅ استخدم .value هنا
        ),
      );

      Get.snackbar(
        "تم القبول",
        "تم قبول الطلب، جاري التوجه للعميل",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color.fromARGB(255, 0, 128, 0),
        colorText: const Color.fromARGB(255, 255, 255, 255),
      );
    } catch (e) {
      Get.snackbar(
        "خطأ",
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color.fromARGB(255, 255, 0, 0),
        colorText: const Color.fromARGB(255, 255, 255, 255),
      );
    }
  }
}
