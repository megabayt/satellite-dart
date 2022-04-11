import 'dart:math' as Math;

const pi = Math.pi;
const twoPi = pi * 2;
const deg2rad = pi / 180.0;
const rad2deg = 180 / pi;
const minutesPerDay = 1440.0;
const mu = 398600.5; // in km3 / s2
const earthRadius = 6378.137; // in km
final xke = 60.0 / Math.sqrt((earthRadius * earthRadius * earthRadius) / mu);
final vkmpersec = (earthRadius * xke) / 60.0;
final tumin = 1.0 / xke;
const j2 = 0.00108262998905;
const j3 = -0.00000253215306;
const j4 = -0.00000161098761;
const j3oj2 = j3 / j2;
const x2o3 = 2.0 / 3.0;
