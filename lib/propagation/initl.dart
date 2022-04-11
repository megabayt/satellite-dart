import 'dart:math' as Math;

import 'package:satellite_dart/constants.dart';
import 'package:satellite_dart/propagation/gstime.dart';

/*-----------------------------------------------------------------------------
 *
 *                           procedure initl
 *
 *  this procedure initializes the sgp4 propagator. all the initialization is
 *    consolidated here instead of having multiple loops inside other routines.
 *
 *  author        : david vallado                  719-573-2600   28 jun 2005
 *
 *  inputs        :
 *    ecco        - eccentricity                           0.0 - 1.0
 *    epoch       - epoch time in days from jan 0, 1950. 0 hr
 *    inclo       - inclination of satellite
 *    no          - mean motion of satellite
 *    satn        - satellite number
 *
 *  outputs       :
 *    ainv        - 1.0 / a
 *    ao          - semi major axis
 *    con41       -
 *    con42       - 1.0 - 5.0 cos(i)
 *    cosio       - cosine of inclination
 *    cosio2      - cosio squared
 *    eccsq       - eccentricity squared
 *    method      - flag for deep space                    'd', 'n'
 *    omeosq      - 1.0 - ecco * ecco
 *    posq        - semi-parameter squared
 *    rp          - radius of perigee
 *    rteosq      - square root of (1.0 - ecco*ecco)
 *    sinio       - sine of inclination
 *    gsto        - gst at time of observation               rad
 *    no          - mean motion of satellite
 *
 *  locals        :
 *    ak          -
 *    d1          -
 *    del         -
 *    adel        -
 *    po          -
 *
 *  coupling      :
 *    getgravfinal
 *    gstime      - find greenwich sidereal time from the julian date
 *
 *  references    :
 *    hoots, roehrich, norad spacetrack report #3 1980
 *    hoots, norad spacetrack report #6 1986
 *    hoots, schumacher and glover 2004
 *    vallado, crawford, hujsak, kelso  2006
 ----------------------------------------------------------------------------*/
Map<String, dynamic> initl(Map<String, dynamic> options) {
  final ecco = options['ecco'];
  final epoch = options['epoch'];
  final inclo = options['inclo'];
  final opsmode = options['opsmode'];
  var no = options['no'];

  // sgp4fix use old way of finding gst
  // ----------------------- earth finalants ---------------------
  // sgp4fix identify finalants and allow alternate values

  // ------------- calculate auxillary epoch quantities ----------
  final eccsq = ecco * ecco;
  final omeosq = 1.0 - eccsq;
  final rteosq = Math.sqrt(omeosq);
  final cosio = Math.cos(inclo);
  final cosio2 = cosio * cosio;

  // ------------------ un-kozai the mean motion -----------------
  final ak = Math.pow((xke / no), x2o3);
  final d1 = (0.75 * j2 * ((3.0 * cosio2) - 1.0)) / (rteosq * omeosq);
  var delPrime = d1 / (ak * ak);
  final adel = ak *
      (1.0 -
          (delPrime * delPrime) -
          (delPrime * ((1.0 / 3.0) + ((134.0 * delPrime * delPrime) / 81.0))));
  delPrime = d1 / (adel * adel);
  no /= (1.0 + delPrime);

  final ao = Math.pow((xke / no), x2o3);
  final sinio = Math.sin(inclo);
  final po = ao * omeosq;
  final con42 = 1.0 - (5.0 * cosio2);
  final con41 = -con42 - cosio2 - cosio2;
  final ainv = 1.0 / ao;
  final posq = po * po;
  final rp = ao * (1.0 - ecco);
  final method = 'n';

  //  sgp4fix modern approach to finding sidereal time
  var gsto;
  if (opsmode == 'a') {
    //  sgp4fix use old way of finding gst
    //  count integer number of days from 0 jan 1970
    final ts70 = epoch - 7305.0;
    final ds70 = (ts70 + 1.0e-8).floor();
    final tfrac = ts70 - ds70;

    //  find greenwich location at epoch
    final c1 = 1.72027916940703639e-2;
    final thgr70 = 1.7321343856509374;
    final fk5r = 5.07551419432269442e-15;
    final c1p2p = c1 + twoPi;
    gsto =
        (thgr70 + (c1 * ds70) + (c1p2p * tfrac) + (ts70 * ts70 * fk5r)) % twoPi;
    if (gsto < 0.0) {
      gsto += twoPi;
    }
  } else {
    gsto = gstime(epoch + 2433281.5);
  }

  return {
    'no': no,
    'method': method,
    'ainv': ainv,
    'ao': ao,
    'con41': con41,
    'con42': con42,
    'cosio': cosio,
    'cosio2': cosio2,
    'eccsq': eccsq,
    'omeosq': omeosq,
    'posq': posq,
    'rp': rp,
    'rteosq': rteosq,
    'sinio': sinio,
    'gsto': gsto,
  };
}
