import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RouteResult {
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;
  final bool isRealRoad;

  const RouteResult({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    this.isRealRoad = true,
  });
}

class RoutingService {
  static final RoutingService _instance = RoutingService._internal();
  factory RoutingService() => _instance;
  RoutingService._internal();

  // Rute fallback jalan riil kota Lamongan (Jl. Veteran -> Jl. Basuki Rahmat -> RSUD Dr. Soegiri)
  static const List<LatLng> defaultLamonganRoad = [
    LatLng(-7.126481, 112.418082),
    LatLng(-7.125705, 112.418207),
    LatLng(-7.125487, 112.418237),
    LatLng(-7.125321, 112.418265),
    LatLng(-7.124673, 112.418361),
    LatLng(-7.123686, 112.418482),
    LatLng(-7.123272, 112.418543),
    LatLng(-7.122831, 112.417525),
    LatLng(-7.122392, 112.416292),
    LatLng(-7.122383, 112.416253),
    LatLng(-7.122377, 112.416228),
    LatLng(-7.122371, 112.416203),
    LatLng(-7.122363, 112.416179),
    LatLng(-7.122341, 112.416118),
    LatLng(-7.122335, 112.416105),
    LatLng(-7.122325, 112.416094),
    LatLng(-7.122312, 112.416088),
    LatLng(-7.122298, 112.416085),
    LatLng(-7.122284, 112.416086),
    LatLng(-7.122271, 112.416092),
    LatLng(-7.122230, 112.416115),
    LatLng(-7.122188, 112.416129),
    LatLng(-7.122089, 112.416159),
    LatLng(-7.121975, 112.416213),
    LatLng(-7.121613, 112.416273),
    LatLng(-7.121381, 112.416311),
    LatLng(-7.121260, 112.416331),
    LatLng(-7.121133, 112.416350),
    LatLng(-7.121023, 112.416364),
    LatLng(-7.120849, 112.416389),
    LatLng(-7.120555, 112.416428),
    LatLng(-7.119813, 112.416540),
    LatLng(-7.118836, 112.416668),
    LatLng(-7.118699, 112.416686),
    LatLng(-7.118576, 112.416700),
    LatLng(-7.118305, 112.416739),
    LatLng(-7.117965, 112.416785),
    LatLng(-7.117490, 112.416843),
    LatLng(-7.117081, 112.416880),
    LatLng(-7.116950, 112.416897),
    LatLng(-7.116785, 112.416912),
    LatLng(-7.116628, 112.416928),
    LatLng(-7.116143, 112.416981),
    LatLng(-7.115980, 112.417001),
    LatLng(-7.115488, 112.417070),
    LatLng(-7.115260, 112.417101),
    LatLng(-7.114330, 112.417198),
    LatLng(-7.113959, 112.417249),
    LatLng(-7.113618, 112.417283),
    LatLng(-7.113269, 112.417334),
    LatLng(-7.112948, 112.417381),
    LatLng(-7.112807, 112.417366),
    LatLng(-7.112691, 112.417381),
    LatLng(-7.112627, 112.417381),
    LatLng(-7.112569, 112.417374),
    LatLng(-7.112473, 112.417349),
    LatLng(-7.112438, 112.417288),
    LatLng(-7.112393, 112.417210),
    LatLng(-7.112342, 112.417095),
    LatLng(-7.112306, 112.416990),
    LatLng(-7.112270, 112.416823),
    LatLng(-7.112209, 112.416709),
    LatLng(-7.112185, 112.416609),
    LatLng(-7.112171, 112.416547),
    LatLng(-7.112126, 112.416339),
    LatLng(-7.111925, 112.415312),
    LatLng(-7.111755, 112.414467),
    LatLng(-7.111448, 112.412938),
    LatLng(-7.111754, 112.412874),
  ];

  /// Mengambil rute perjalanan mengikuti jaringan jalan riil menggunakan OSRM
  Future<RouteResult> getRoadRoute(LatLng start, LatLng destination) async {
    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${start.longitude},${start.latitude};${destination.longitude},${destination.latitude}'
        '?overview=full&geometries=geojson',
      );

      final response = await http.get(url, headers: {
        'Accept': 'application/json',
        'User-Agent': 'donor-darah-lamongan/1.0',
      }).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 'Ok' && data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          final coords = route['geometry']['coordinates'] as List;
          final List<LatLng> points = coords.map((c) {
            final lng = (c[0] as num).toDouble();
            final lat = (c[1] as num).toDouble();
            return LatLng(lat, lng);
          }).toList();

          final double distance = (route['distance'] as num?)?.toDouble() ?? 0.0;
          final double duration = (route['duration'] as num?)?.toDouble() ?? 0.0;

          if (points.length >= 2) {
            return RouteResult(
              points: points,
              distanceMeters: distance,
              durationSeconds: duration,
              isRealRoad: true,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('OSRM routing fetch error: $e');
    }

    // Jika OSRM offline/gagal, periksa apakah berada di sekitar Lamongan
    const Distance distCalc = Distance();
    final double distToDefaultStart = distCalc.as(LengthUnit.Meter, start, defaultLamonganRoad.first);
    final double distToDefaultEnd = distCalc.as(LengthUnit.Meter, destination, defaultLamonganRoad.last);

    if (distToDefaultStart < 4000 && distToDefaultEnd < 4000) {
      return RouteResult(
        points: List<LatLng>.from(defaultLamonganRoad),
        distanceMeters: 2287.0,
        durationSeconds: 300.0,
        isRealRoad: true,
      );
    }

    // Fallback interpolasi garis bertahap
    return RouteResult(
      points: [start, destination],
      distanceMeters: distCalc.as(LengthUnit.Meter, start, destination),
      durationSeconds: 180.0,
      isRealRoad: false,
    );
  }

  /// Menghitung posisi koordinat yang berada tepat di jalur jalan berdasarkan progres (0.0 sampai 1.0)
  LatLng getPointAlongRoute(List<LatLng> points, double progress) {
    if (points.isEmpty) return const LatLng(-7.111812, 112.413155);
    if (points.length == 1 || progress <= 0.0) return points.first;
    if (progress >= 1.0) return points.last;

    const Distance distCalc = Distance();

    // 1. Hitung panjang tiap segmen jalan
    List<double> segmentLengths = [];
    double totalDistance = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      final d = distCalc.as(LengthUnit.Meter, points[i], points[i + 1]);
      segmentLengths.add(d);
      totalDistance += d;
    }

    if (totalDistance == 0.0) return points.first;

    // 2. Tentukan segmen target berdasarkan progres jarak
    final double targetDistance = totalDistance * progress.clamp(0.0, 1.0);
    double accumulated = 0.0;

    for (int i = 0; i < segmentLengths.length; i++) {
      final segLen = segmentLengths[i];
      if (accumulated + segLen >= targetDistance) {
        final double remaining = targetDistance - accumulated;
        final double segmentRatio = segLen == 0 ? 0 : (remaining / segLen).clamp(0.0, 1.0);

        final p1 = points[i];
        final p2 = points[i + 1];

        final lat = p1.latitude + (p2.latitude - p1.latitude) * segmentRatio;
        final lng = p1.longitude + (p2.longitude - p1.longitude) * segmentRatio;
        return LatLng(lat, lng);
      }
      accumulated += segLen;
    }

    return points.last;
  }

  /// Menghitung total jarak rute di sepanjang jalan
  double calculateTotalRoadDistance(List<LatLng> points) {
    if (points.length < 2) return 0.0;
    const Distance distCalc = Distance();
    double total = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      total += distCalc.as(LengthUnit.Meter, points[i], points[i + 1]);
    }
    return total;
  }
}
