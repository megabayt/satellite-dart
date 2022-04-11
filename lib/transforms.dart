import 'dart:math' as Math;

import 'package:satellite_dart/constants.dart';


double radiansToDegrees(radians) {
  return radians * rad2deg;
}

double degreesToRadians(degrees) {
  return degrees * deg2rad;
}

double degreesLat(radians) {
  if (radians < (-pi / 2) || radians > (pi / 2)) {
    throw new RangeError('Latitude radians must be in range [-pi/2; pi/2].');
  }
  return radiansToDegrees(radians);
}

double degreesLong(radians) {
  if (radians < -pi || radians > pi) {
    throw new RangeError('Longitude radians must be in range [-pi; pi].');
  }
  return radiansToDegrees(radians);
}

double radiansLat(degrees) {
  if (degrees < -90 || degrees > 90) {
    throw new RangeError('Latitude degrees must be in range [-90; 90].');
  }
  return degreesToRadians(degrees);
}

double radiansLong(degrees) {
  if (degrees < -180 || degrees > 180) {
    throw new RangeError('Longitude degrees must be in range [-180; 180].');
  }
  return degreesToRadians(degrees);
}

Map<String, dynamic> geodeticToEcf(Map<String, dynamic> geodetic) {
  final longitude = geodetic['longitude'];
  final latitude = geodetic['latitude'];
  final height = geodetic['height'];

  final a = 6378.137;
  final b = 6356.7523142;
  final f = (a - b) / a;
  final e2 = ((2 * f) - (f * f));
  final normal = a / Math.sqrt(1 - (e2 * (Math.sin(latitude) * Math.sin(latitude))));

  final x = (normal + height) * Math.cos(latitude) * Math.cos(longitude);
  final y = (normal + height) * Math.cos(latitude) * Math.sin(longitude);
  final z = ((normal * (1 - e2)) + height) * Math.sin(latitude);

  return {
    'x': x,
    'y': y,
    'z': z,
  };
}

Map<String, dynamic> eciToGeodetic(Map<String, dynamic> eci, gmst) {
  // http://www.celestrak.com/columns/v02n03/
  final a = 6378.137;
  final b = 6356.7523142;
  final R = Math.sqrt((eci['x'] * eci['x']) + (eci['y'] * eci['y']));
  final f = (a - b) / a;
  final e2 = ((2 * f) - (f * f));

  var longitude = Math.atan2(eci['y'], eci['x']) - gmst;
  while (longitude < -pi) {
    longitude += twoPi;
  }
  while (longitude > pi) {
    longitude -= twoPi;
  }

  final kmax = 20;
  var k = 0;
  var latitude = Math.atan2(
    eci['z'],
    Math.sqrt((eci['x'] * eci['x']) + (eci['y'] * eci['y'])),
  );
  var C;
  while (k < kmax) {
    C = 1 / Math.sqrt(1 - (e2 * (Math.sin(latitude) * Math.sin(latitude))));
    latitude = Math.atan2(eci['z'] + (a * C * e2 * Math.sin(latitude)), R);
    k += 1;
  }
  final height = (R / Math.cos(latitude)) - (a * C);
  return { 'longitude': longitude, 'latitude': latitude, 'height': height };
}

Map<String, dynamic> ecfToEci(Map<String, dynamic> ecf, gmst) {
  // ccar.colorado.edu/ASEN5070/handouts/coordsys.doc
  //
  // [X]     [C -S  0][X]
  // [Y]  =  [S  C  0][Y]
  // [Z]eci  [0  0  1][Z]ecf
  //
  final X = (ecf['x'] * Math.cos(gmst)) - (ecf['y'] * Math.sin(gmst));
  final Y = (ecf['x'] * (Math.sin(gmst))) + (ecf['y'] * Math.cos(gmst));
  final Z = ecf['z'];
  return { 'x': X, 'y': Y, 'z': Z };
}

Map<String, dynamic> eciToEcf(Map<String, dynamic> eci, gmst) {
  // ccar.colorado.edu/ASEN5070/handouts/coordsys.doc
  //
  // [X]     [C -S  0][X]
  // [Y]  =  [S  C  0][Y]
  // [Z]eci  [0  0  1][Z]ecf
  //
  //
  // Inverse:
  // [X]     [C  S  0][X]
  // [Y]  =  [-S C  0][Y]
  // [Z]ecf  [0  0  1][Z]eci

  final x = (eci['x'] * Math.cos(gmst)) + (eci['y'] * Math.sin(gmst));
  final y = (eci['x'] * (-Math.sin(gmst))) + (eci['y'] * Math.cos(gmst));
  final z = eci['z'];

  return {
    'x': x,
    'y': y,
    'z': z,
  };
}

Map<String, dynamic> topocentric(Map<String, dynamic> observerGeodetic, Map<String, dynamic> satelliteEcf) {
  // http://www.celestrak.com/columns/v02n02/
  // TS Kelso's method, except I'm using ECF frame
  // and he uses ECI.

  final longitude = observerGeodetic['longitude'];
  final latitude = observerGeodetic['latitude'];

  final observerEcf = geodeticToEcf(observerGeodetic);

  final rx = satelliteEcf['x'] - observerEcf['x'];
  final ry = satelliteEcf['y'] - observerEcf['y'];
  final rz = satelliteEcf['z'] - observerEcf['z'];

  final topS = ((Math.sin(latitude) * Math.cos(longitude) * rx)
      + (Math.sin(latitude) * Math.sin(longitude) * ry))
    - (Math.cos(latitude) * rz);

  final topE = (-Math.sin(longitude) * rx)
    + (Math.cos(longitude) * ry);

  final topZ = (Math.cos(latitude) * Math.cos(longitude) * rx)
    + (Math.cos(latitude) * Math.sin(longitude) * ry)
    + (Math.sin(latitude) * rz);

  return { 'topS': topS, 'topE': topE, 'topZ': topZ };
}

/**
 * @param {Object} tc
 * @param {Number} tc.topS Positive horizontal vector S due south.
 * @param {Number} tc.topE Positive horizontal vector E due east.
 * @param {Number} tc.topZ Vector Z normal to the surface of the earth (up).
 * @returns {Object}
 */
Map<String, dynamic> topocentricToLookAngles(Map<String, dynamic> tc) {
  final topS = tc['topS'];
  final topE = tc['topE'];
  final topZ = tc['topZ'];
  final rangeSat = Math.sqrt((topS * topS) + (topE * topE) + (topZ * topZ));
  final El = Math.asin(topZ / rangeSat);
  final Az = Math.atan2(-topE, topS) + pi;

  return {
    'azimuth': Az,
    'elevation': El,
    'rangeSat': rangeSat, // Range in km
  };
}

Map<String, dynamic> ecfToLookAngles(observerGeodetic, satelliteEcf) {
  final topocentricCoords = topocentric(observerGeodetic, satelliteEcf);
  return topocentricToLookAngles(topocentricCoords);
}
