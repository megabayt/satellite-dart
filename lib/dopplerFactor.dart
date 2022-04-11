import 'dart:math' as Math;

double dopplerFactor(Map<String, dynamic> location,
    Map<String, dynamic> position, Map<String, dynamic> velocity) {
  const mfactor = 7.292115E-5;
  const c = 299792.458; // Speed of light in km/s

  var range = {
    'x': position['x'] - location['x'],
    'y': position['y'] - location['y'],
    'z': position['z'] - location['z'],
  };
  range['w'] = Math.sqrt(Math.pow(range['x'], 2) +
      Math.pow(range['y'], 2) +
      Math.pow(range['z'], 2));

  var rangeVel = {
    'x': velocity['x'] + mfactor * location['y'],
    'y': velocity['y'] - mfactor * location['x'],
    'z': velocity['z'],
  };

  var rangeRate = (range['x'] * rangeVel['x'] +
          range['y'] * rangeVel['y'] +
          range['z'] * rangeVel['z']) /
      range['w'];

  return (1 + (rangeRate / c) * _sign(rangeRate)) as double;
}

int _sign(double value) {
  return value >= 0 ? 1 : -1;
}
