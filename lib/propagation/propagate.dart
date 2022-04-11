import 'package:satellite_dart/constants.dart';
import 'package:satellite_dart/ext.dart';
import 'package:satellite_dart/propagation/sgp4.dart';

Map<String, dynamic>? propagate(Map<String, dynamic> satrec, DateTime date) {
  // Return a position and velocity vector for a given date and time.
  final j = jday(date) ?? 0;
  final m = (j - satrec['jdsatepoch']) * minutesPerDay;
  return sgp4(satrec, m);
}
