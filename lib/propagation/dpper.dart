import 'dart:math' as Math;

import 'package:satellite_dart/constants.dart';
import 'package:satellite_dart/utils/abs.dart';

/* -----------------------------------------------------------------------------
 *
 *                           procedure dpper
 *
 *  this procedure provides deep space long period periodic contributions
 *    to the mean elements.  by design, these periodics are zero at epoch.
 *    this used to be dscom which included initialization, but it's really a
 *    recurring function.
 *
 *  author        : david vallado                  719-573-2600   28 jun 2005
 *
 *  inputs        :
 *    e3          -
 *    ee2         -
 *    peo         -
 *    pgho        -
 *    pho         -
 *    pinco       -
 *    plo         -
 *    se2 , se3 , sgh2, sgh3, sgh4, sh2, sh3, si2, si3, sl2, sl3, sl4 -
 *    t           -
 *    xh2, xh3, xi2, xi3, xl2, xl3, xl4 -
 *    zmol        -
 *    zmos        -
 *    ep          - eccentricity                           0.0 - 1.0
 *    inclo       - inclination - needed for lyddane modification
 *    nodep       - right ascension of ascending node
 *    argpp       - argument of perigee
 *    mp          - mean anomaly
 *
 *  outputs       :
 *    ep          - eccentricity                           0.0 - 1.0
 *    inclp       - inclination
 *    nodep        - right ascension of ascending node
 *    argpp       - argument of perigee
 *    mp          - mean anomaly
 *
 *  locals        :
 *    alfdp       -
 *    betdp       -
 *    cosip  , sinip  , cosop  , sinop  ,
 *    dalf        -
 *    dbet        -
 *    dls         -
 *    f2, f3      -
 *    pe          -
 *    pgh         -
 *    ph          -
 *    pinc        -
 *    pl          -
 *    sel   , ses   , sghl  , sghs  , shl   , shs   , sil   , sinzf , sis   ,
 *    sll   , sls
 *    xls         -
 *    xnoh        -
 *    zf          -
 *    zm          -
 *
 *  coupling      :
 *    none.
 *
 *  references    :
 *    hoots, roehrich, norad spacetrack report #3 1980
 *    hoots, norad spacetrack report #6 1986
 *    hoots, schumacher and glover 2004
 *    vallado, crawford, hujsak, kelso  2006
 ----------------------------------------------------------------------------*/
Map<String, dynamic> dpper(Map<String, dynamic> satrec, Map<String, dynamic> options) {
  final e3 = satrec['e3'];
  final ee2 = satrec['ee2'];
  final peo = satrec['peo'];
  final pgho = satrec['pgho'];
  final pho = satrec['pho'];
  final pinco = satrec['pinco'];
  final plo = satrec['plo'];
  final se2 = satrec['se2'];
  final se3 = satrec['se3'];
  final sgh2 = satrec['sgh2'];
  final sgh3 = satrec['sgh3'];
  final sgh4 = satrec['sgh4'];
  final sh2 = satrec['sh2'];
  final sh3 = satrec['sh3'];
  final si2 = satrec['si2'];
  final si3 = satrec['si3'];
  final sl2 = satrec['sl2'];
  final sl3 = satrec['sl3'];
  final sl4 = satrec['sl4'];
  final t = satrec['t'];
  final xgh2 = satrec['xgh2'];
  final xgh3 = satrec['xgh3'];
  final xgh4 = satrec['xgh4'];
  final xh2 = satrec['xh2'];
  final xh3 = satrec['xh3'];
  final xi2 = satrec['xi2'];
  final xi3 = satrec['xi3'];
  final xl2 = satrec['xl2'];
  final xl3 = satrec['xl3'];
  final xl4 = satrec['xl4'];
  final zmol = satrec['zmol'];
  final zmos = satrec['zmos'];

  final init = options['init'];
  final opsmode = options['opsmode'];
  var ep = options['ep'];
  var inclp = options['inclp'];
  var nodep = options['nodep'];
  var argpp = options['argpp'];
  var mp = options['mp'];

  // Copy satellite attributes into local variables for convenience
  // and symmetry in writing formulae.

  var alfdp;
  var betdp;
  var cosip;
  var sinip;
  var cosop;
  var sinop;
  var dalf;
  var dbet;
  var dls;
  var f2;
  var f3;
  var pe;
  var pgh;
  var ph;
  var pinc;
  var pl;
  var sinzf;
  var xls;
  var xnoh;
  var zf;
  var zm;

  //  ---------------------- constants -----------------------------
  const zns = 1.19459e-5;
  const zes = 0.01675;
  const znl = 1.5835218e-4;
  const zel = 0.05490;

  //  --------------- calculate time varying periodics -----------
  zm = zmos + (zns * t);

  // be sure that the initial call has time set to zero
  if (init == 'y') {
    zm = zmos;
  }
  zf = zm + (2.0 * zes * Math.sin(zm));
  sinzf = Math.sin(zf);
  f2 = (0.5 * sinzf * sinzf) - 0.25;
  f3 = -0.5 * sinzf * Math.cos(zf);

  final ses = (se2 * f2) + (se3 * f3);
  final sis = (si2 * f2) + (si3 * f3);
  final sls = (sl2 * f2) + (sl3 * f3) + (sl4 * sinzf);
  final sghs = (sgh2 * f2) + (sgh3 * f3) + (sgh4 * sinzf);
  final shs = (sh2 * f2) + (sh3 * f3);

  zm = zmol + (znl * t);
  if (init == 'y') {
    zm = zmol;
  }

  zf = zm + (2.0 * zel * Math.sin(zm));
  sinzf = Math.sin(zf);
  f2 = (0.5 * sinzf * sinzf) - 0.25;
  f3 = -0.5 * sinzf * Math.cos(zf);

  final sel = (ee2 * f2) + (e3 * f3);
  final sil = (xi2 * f2) + (xi3 * f3);
  final sll = (xl2 * f2) + (xl3 * f3) + (xl4 * sinzf);
  final sghl = (xgh2 * f2) + (xgh3 * f3) + (xgh4 * sinzf);
  final shll = (xh2 * f2) + (xh3 * f3);

  pe = ses + sel;
  pinc = sis + sil;
  pl = sls + sll;
  pgh = sghs + sghl;
  ph = shs + shll;

  if (init == 'n') {
    pe -= peo;
    pinc -= pinco;
    pl -= plo;
    pgh -= pgho;
    ph -= pho;
    inclp += pinc;
    ep += pe;
    sinip = Math.sin(inclp);
    cosip = Math.cos(inclp);

    /* ----------------- apply periodics directly ------------ */
    // sgp4fix for lyddane choice
    // strn3 used original inclination - this is technically feasible
    // gsfc used perturbed inclination - also technically feasible
    // probably best to readjust the 0.2 limit value and limit discontinuity
    // 0.2 rad = 11.45916 deg
    // use next line for original strn3 approach and original inclination
    // if (inclo >= 0.2)
    // use next line for gsfc version and perturbed inclination
    if (inclp >= 0.2) {
      ph /= sinip;
      pgh -= cosip * ph;
      argpp += pgh;
      nodep += ph;
      mp += pl;
    } else {
      //  ---- apply periodics with lyddane modification ----
      sinop = Math.sin(nodep);
      cosop = Math.cos(nodep);
      alfdp = sinip * sinop;
      betdp = sinip * cosop;
      dalf = (ph * cosop) + (pinc * cosip * sinop);
      dbet = (-ph * sinop) + (pinc * cosip * cosop);
      alfdp += dalf;
      betdp += dbet;
      nodep %= twoPi;

      //  sgp4fix for afspc written intrinsic functions
      //  nodep used without a trigonometric function ahead
      if (nodep < 0.0 && opsmode == 'a') {
        nodep += twoPi;
      }
      xls = mp + argpp + (cosip * nodep);
      dls = (pl + pgh) - (pinc * nodep * sinip);
      xls += dls;
      xnoh = nodep;
      nodep = Math.atan2(alfdp, betdp);

      //  sgp4fix for afspc written intrinsic functions
      //  nodep used without a trigonometric function ahead
      if (nodep < 0.0 && opsmode == 'a') {
        nodep += twoPi;
      }
      if (abs(xnoh - nodep) > pi) {
        if (nodep < xnoh) {
          nodep += twoPi;
        } else {
          nodep -= twoPi;
        }
      }
      mp += pl;
      argpp = xls - mp - (cosip * nodep);
    }
  }

  return {
    'ep': ep,
    'inclp': inclp,
    'nodep': nodep,
    'argpp': argpp,
    'mp': mp,
  };
}
