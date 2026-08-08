import 'dart:ui' as ui;
import 'package:flutter/services.dart' show ByteData, Uint8List;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;
import 'package:fastnet_mobile_front_end/config/constants.dart';
import 'package:fastnet_mobile_front_end/models/destination.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart' as geo;

class FullscreenMapScreen extends StatefulWidget {
  final Destination destination;

  const FullscreenMapScreen({
    Key? key,
    required this.destination,
  }) : super(key: key);

  @override
  State<FullscreenMapScreen> createState() => _FullscreenMapScreenState();
}

class _FullscreenMapScreenState extends State<FullscreenMapScreen> {
  MapboxMap? _mapboxMap;
  CircleAnnotationManager? _circleAnnotationManager;
  PointAnnotationManager? _pointAnnotationManager;
  PolylineAnnotationManager? _polylineAnnotationManager;
  bool _isFetchingRoute = false;
  String? _routeDistance;
  String? _routeDuration;

  Future<Uint8List> _getTeardropPinBytes() async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    const double width = 120.0;
    const double height = 150.0;

    final Paint pinPaint = Paint()
      ..color = const Color(0xFF003580) // Dark Navy Blue
      ..style = PaintingStyle.fill;

    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0;

    final Paint dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final Path path = Path();
    const Offset center = Offset(60, 55);
    path.addOval(Rect.fromCircle(center: center, radius: 44));
    path.moveTo(20, 70);
    path.lineTo(60, 142);
    path.lineTo(100, 70);
    path.close();

    canvas.drawPath(path, pinPaint);
    canvas.drawPath(path, borderPaint);
    canvas.drawCircle(center, 16.0, dotPaint);

    final ui.Image image = await recorder.endRecording().toImage(width.toInt(), height.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    final lat = widget.destination.latitude;
    final lon = widget.destination.longitude;

    final pinBytes = await _getTeardropPinBytes();

    // Add teardrop pin marker with lodge name below it
    _mapboxMap?.annotations.createPointAnnotationManager().then((manager) {
      _pointAnnotationManager = manager;
      _pointAnnotationManager?.create(PointAnnotationOptions(
        geometry: Point(coordinates: Position(lon, lat)),
        image: pinBytes,
        iconSize: 0.9,
        textField: widget.destination.name,
        textSize: 11.5,
        textColor: const Color(0xFF0F172A).toARGB32(),
        textHaloColor: Colors.white.toARGB32(),
        textHaloWidth: 2.0,
        textOffset: const [0.0, 1.0],
        textAnchor: TextAnchor.TOP,
      ));
    });
  }

  void _zoomIn() {
    _mapboxMap?.getCameraState().then((state) {
      _mapboxMap?.setCamera(CameraOptions(zoom: state.zoom + 1));
    });
  }

  void _zoomOut() {
    _mapboxMap?.getCameraState().then((state) {
      _mapboxMap?.setCamera(CameraOptions(zoom: state.zoom - 1));
    });
  }

  void _reCenter() {
    final lat = widget.destination.latitude;
    final lon = widget.destination.longitude;
    _mapboxMap?.setCamera(
      CameraOptions(
        center: Point(coordinates: Position(lon, lat)),
        zoom: 15.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lat = widget.destination.latitude;
    final lon = widget.destination.longitude;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Interactive map
          if (kIsWeb)
            Container(
              color: const Color(0xFFE2E8F0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.map_outlined, size: 64, color: Color(0xFF1E88E5)),
                    const SizedBox(height: 12),
                    Text(
                      widget.destination.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${lat.toStringAsFixed(4)}°, ${lon.toStringAsFixed(4)}°',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            )
          else
            MapWidget(
              key: const ValueKey("mapWidget"),
              cameraOptions: CameraOptions(
                center: Point(coordinates: Position(lon, lat)),
                zoom: 14.5,
              ),
              styleUri: MapboxStyles.MAPBOX_STREETS,
              onMapCreated: _onMapCreated,
            ),

          // 2. Custom Floating circular close button

          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: FloatingActionButton(
              heroTag: 'close_map',
              mini: true,
              backgroundColor: Colors.white,
              elevation: 4,
              shape: const CircleBorder(),
              onPressed: () => Navigator.pop(context),
              child: const Icon(Icons.close, color: Colors.black87),
            ),
          ),

          // 3. Zoom Controls Column (Right Side)
          Positioned(
            right: 16,
            top: MediaQuery.of(context).size.height / 2 - 80,
            child: Column(
              children: [
                _buildFloatingButton(Icons.add, _zoomIn, 'zoom_in'),
                const SizedBox(height: 8),
                _buildFloatingButton(Icons.remove, _zoomOut, 'zoom_out'),
                const SizedBox(height: 8),
                _buildFloatingButton(Icons.my_location, _reCenter, 're_center'),
              ],
            ),
          ),

          // 4. Sleek bottom details overlay card
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      widget.destination.imageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey.shade100,
                        child: const Icon(Icons.image_outlined, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.destination.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 14),
                            const SizedBox(width: 2),
                            Text(
                              widget.destination.rating.toString(),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '(${widget.destination.city})',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              'TSh ${widget.destination.price.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]},")}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF385C),
                              ),
                            ),
                            Text(
                              ' / night',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        if (_routeDistance != null) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.directions_car, size: 14, color: Colors.blue.shade700),
                                const SizedBox(width: 6),
                                Text(
                                  '$_routeDuration - $_routeDistance',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // CTA Button
                  Material(
                    color: _isFetchingRoute ? Colors.grey.shade400 : const Color(0xFFFF385C),
                    borderRadius: BorderRadius.circular(30),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: _launchDirections,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: _isFetchingRoute 
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.directions, color: Colors.white, size: 24),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButton(IconData icon, VoidCallback onPressed, String tag) {
    return FloatingActionButton(
      heroTag: tag,
      mini: true,
      backgroundColor: Colors.white,
      elevation: 4,
      shape: const CircleBorder(),
      onPressed: onPressed,
      child: Icon(icon, color: Colors.black87, size: 20),
    );
  }

  Future<void> _launchDirections() async {
    if (_isFetchingRoute) return;
    setState(() => _isFetchingRoute = true);

    try {
      geo.LocationPermission permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
        if (permission == geo.LocationPermission.denied) {
          throw Exception("Location permissions denied.");
        }
      }
      if (permission == geo.LocationPermission.deniedForever) {
        throw Exception("Location permissions are permanently denied.");
      }

      geo.Position userPos = await geo.Geolocator.getCurrentPosition(desiredAccuracy: geo.LocationAccuracy.high);

      final lat = widget.destination.latitude;
      final lon = widget.destination.longitude;
      final token = AppConstants.mapboxApiKey;
      final url = Uri.parse(
          'https://api.mapbox.com/directions/v5/mapbox/driving/${userPos.longitude},${userPos.latitude};$lon,$lat?geometries=geojson&access_token=$token'
      );

      final response = await http.get(url);
      if (response.statusCode != 200) throw Exception("Failed to fetch route");

      final data = jsonDecode(response.body);
      if (data['routes'] == null || data['routes'].isEmpty) throw Exception("No route found");

      final route = data['routes'][0];
      final geometry = route['geometry'];
      final coords = geometry['coordinates'] as List<dynamic>;

      final List<Position> polylinePositions = coords.map((c) => Position(c[0] as num, c[1] as num)).toList();

      final distanceMeters = route['distance'] as num;
      final durationSeconds = route['duration'] as num;
      final distanceKm = (distanceMeters / 1000).toStringAsFixed(1);
      final durationMins = (durationSeconds / 60).round();

      if (!mounted) return;
      setState(() {
        _routeDistance = "$distanceKm km";
        _routeDuration = "$durationMins min";
      });

      if (_polylineAnnotationManager == null) {
        _polylineAnnotationManager = await _mapboxMap?.annotations.createPolylineAnnotationManager();
      } else {
        await _polylineAnnotationManager?.deleteAll();
      }

      await _polylineAnnotationManager?.create(PolylineAnnotationOptions(
        geometry: LineString(coordinates: polylinePositions),
        lineColor: const Color(0xFF003580).toARGB32(), // dark navy blue
        lineWidth: 6.0,
      ));

      final midLon = (userPos.longitude + lon) / 2;
      final midLat = (userPos.latitude + lat) / 2;

      _mapboxMap?.location.updateSettings(LocationComponentSettings(
        enabled: true,
        pulsingEnabled: false,
        pulsingColor: const Color(0xFF003580).toARGB32(),
        pulsingMaxRadius: 30.0,
      ));

      _mapboxMap?.setCamera(
        CameraOptions(
          center: Point(coordinates: Position(midLon, midLat)),
          zoom: 11.5,
          pitch: 45.0, // 3D driving perspective
        ),
      );

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error finding route: ${e.toString().replaceAll("Exception: ", "")}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isFetchingRoute = false);
    }
  }
}

