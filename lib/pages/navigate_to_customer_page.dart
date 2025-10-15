import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:technican/pages/wait_for_customer_issues_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:technican/services/app_config_service.dart';

class NavigateToCustomerPage extends StatefulWidget {
  final LatLng customerLocation;
  final String requestId;
  final String technicianId;

  const NavigateToCustomerPage({
    super.key,
    required this.customerLocation,
    required this.requestId,
    required this.technicianId,
  });

  @override
  State<NavigateToCustomerPage> createState() => _NavigateToCustomerPageState();
}

class _NavigateToCustomerPageState extends State<NavigateToCustomerPage>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  LatLng? _technicianLocation;
  StreamSubscription<Position>? _locationStream;
  Set<Polyline> _polylines = {};
  bool _canConfirmArrival = false;

  String _distanceText = '';
  String _durationText = '';

  final String googleApiKey =
      "AIzaSyAZHlDQBDRtQmEfu0Lrt_JJT8UV5QIYrZc"; // 🔑 ضع مفتاحك هنا

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final appConfig = Get.find<AppConfigService>();

  @override
  void initState() {
    super.initState();
    _trackTechnician();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _locationStream?.cancel(); // ✅ إيقاف الـ Stream عند التخلص من الصفحة
    _animationController.dispose();
    super.dispose();
  }

  /// ✅ متابعة موقع الفني ورفع الموقع على Firestore
  void _trackTechnician() async {
    LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _locationStream =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (pos) async {
            if (!mounted) return; // ✅ تأكد أن الصفحة مازالت موجودة

            final techLoc = LatLng(pos.latitude, pos.longitude);

            setState(() {
              _technicianLocation = techLoc;
            });

            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              await FirebaseFirestore.instance
                  .collection('technicians')
                  .doc(user.uid)
                  .update({
                    'location': {'lat': pos.latitude, 'lng': pos.longitude},
                  });
            }

            await _drawRouteAndCalculateETA();

            final distance = Geolocator.distanceBetween(
              pos.latitude,
              pos.longitude,
              widget.customerLocation.latitude,
              widget.customerLocation.longitude,
            );

            if (!mounted) return; // ✅ تحقق إضافي قبل setState
            setState(() {
              _canConfirmArrival = distance < 100;
            });

            if (_mapController != null && mounted) {
              _mapController!.animateCamera(CameraUpdate.newLatLng(techLoc));
            }
          },
          onError: (e) {
            debugPrint('❌ Error in location stream: $e');
          },
        );
  }

  /// ✅ رسم الطريق باستخدام Google Directions API
  Future<void> _drawRouteAndCalculateETA() async {
    if (_technicianLocation == null) return;

    final url =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${_technicianLocation!.latitude},${_technicianLocation!.longitude}&destination=${widget.customerLocation.latitude},${widget.customerLocation.longitude}&mode=driving&key=$googleApiKey";

    final response = await http.get(Uri.parse(url));
    final data = jsonDecode(response.body);

    if (data["routes"].isNotEmpty) {
      final points = _decodePolyline(
        data["routes"][0]["overview_polyline"]["points"],
      );
      final leg = data["routes"][0]["legs"][0];

      if (!mounted) return; // ✅ تحقق قبل setState
      setState(() {
        _distanceText = leg["distance"]["text"];
        _durationText = leg["duration"]["text"];
        _polylines = {
          Polyline(
            polylineId: const PolylineId("route"),
            color: Color(
              int.parse(
                appConfig.themePrimaryColor.value.replaceFirst('#', '0xff'),
              ),
            ),
            width: 6,
            points: points,
          ),
        };
      });
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polylinePoints = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      polylinePoints.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return polylinePoints;
  }

  /// ✅ تأكيد الوصول
  Future<void> _confirmArrivalAndNavigate() async {
    try {
      _locationStream?.cancel(); // ✅ أوقف الـ Stream قبل الانتقال

      final pos = _technicianLocation;
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(widget.requestId)
          .update({
            'status': 'arrived',
            'technician.arrivalTime': FieldValue.serverTimestamp(),
            'technician.location': {
              'lat': pos?.latitude ?? 0,
              'lng': pos?.longitude ?? 0,
            },
          });

      Get.off(() => WaitForCustomerIssuesPage(requestId: widget.requestId));
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء تأكيد الوصول',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _openInGoogleMaps() async {
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=${widget.customerLocation.latitude},${widget.customerLocation.longitude}&travelmode=driving';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('لا يمكن فتح خرائط جوجل')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Color(
          int.parse(
            Get.find<AppConfigService>().themePrimaryColor.value.replaceFirst(
              '#',
              '0xff',
            ),
          ),
        ),
        title: const Text(
          '🚗 التوجه إلى العميل',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) => _mapController = controller,
            initialCameraPosition: CameraPosition(
              target: widget.customerLocation,
              zoom: 15,
            ),
            markers: {
              Marker(
                markerId: const MarkerId('customer'),
                position: widget.customerLocation,
                infoWindow: const InfoWindow(title: 'موقع العميل'),
              ),
              if (_technicianLocation != null)
                Marker(
                  markerId: const MarkerId('technician'),
                  position: _technicianLocation!,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueAzure,
                  ),
                  infoWindow: const InfoWindow(title: 'موقعك الحالي'),
                ),
            },
            polylines: _polylines,
            myLocationEnabled: true,
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Obx(
                () => Column(
                  children: [
                    if (_distanceText.isNotEmpty && _durationText.isNotEmpty)
                      Text(
                        "المسافة: $_distanceText | الوقت المتوقع: $_durationText",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _openInGoogleMaps,
                      icon: const Icon(Icons.navigation, color: Colors.white),
                      label: const Text(
                        "افتح في خرائط جوجل",
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(
                          int.parse(
                            Get.find<AppConfigService>().themeAccentColor.value
                                .replaceFirst('#', '0xff'),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _canConfirmArrival
                          ? _confirmArrivalAndNavigate
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _canConfirmArrival
                            ? Color(
                                int.parse(
                                  Get.find<AppConfigService>()
                                      .themePrimaryColor
                                      .value
                                      .replaceFirst('#', '0xff'),
                                ),
                              )
                            : Color(
                                int.parse(
                                  Get.find<AppConfigService>()
                                      .themeSecondaryColor
                                      .value
                                      .replaceFirst('#', '0xff'),
                                ),
                              ).withOpacity(0.5),
                      ),
                      child: const Text(
                        "✅ تأكيد الوصول",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
