import 'package:dart_geohash/dart_geohash.dart';
import 'package:peanut/App/configs.dart';

GeoHasher geoHasher = GeoHasher();

class MapModel {
  final String addr;
  final double lat;
  final double lng;

  const MapModel({required this.addr, required this.lat, required this.lng});

  String? get geohash => geoHasher.encode(lng, lat, precision: Configs.geohashPrecision);
}
