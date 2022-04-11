import 'dart:math' as Math;

import 'package:satellite_dart/constants.dart';
import 'package:satellite_dart/ext.dart';
import 'package:satellite_dart/propagation/sgp4init.dart';

/* -----------------------------------------------------------------------------
 *
 *                           function twoline2rv
 *
 *  this function converts the two line element set character string data to
 *    variables and initializes the sgp4 variables. several intermediate varaibles
 *    and quantities are determined. note that the result is a structure so multiple
 *    satellites can be processed simultaneously without having to reinitialize. the
 *    verification mode is an important option that permits quick checks of any
 *    changes to the underlying technical theory. this option works using a
 *    modified tle file in which the start, stop, and delta time values are
 *    included at the end of the second line of data. this only works with the
 *    verification mode. the catalog mode simply propagates from -1440 to 1440 min
 *    from epoch and is useful when performing entire catalog runs.
 *
 *  author        : david vallado                  719-573-2600    1 mar 2001
 *
 *  inputs        :
 *    longstr1    - first line of the tle
 *    longstr2    - second line of the tle
 *    typerun     - type of run                    verification 'v', catalog 'c',
 *                                                 manual 'm'
 *    typeinput   - type of manual input           mfe 'm', epoch 'e', dayofyr 'd'
 *    opsmode     - mode of operation afspc or improved 'a', 'i'
 *    whichfinal  - which set of finalants to use  72, 84
 *
 *  outputs       :
 *    satrec      - structure containing all the sgp4 satellite information
 *
 *  coupling      :
 *    getgravfinal-
 *    days2mdhms  - conversion of days to month, day, hour, minute, second
 *    jday        - convert day month year hour minute second into julian date
 *    sgp4init    - initialize the sgp4 variables
 *
 *  references    :
 *    norad spacetrack report #3
 *    vallado, crawford, hujsak, kelso  2006
 --------------------------------------------------------------------------- */

/**
 * Return a Satellite imported from two lines of TLE data.
 *
 * Provide the two TLE lines as strings 'longstr1' and 'longstr2',
 * and select which standard set of gravitational finalants you want
 * by providing 'gravity_finalants':
 *
 * 'sgp4.propagation.wgs72' - Standard WGS 72 model
 * 'sgp4.propagation.wgs84' - More recent WGS 84 model
 * 'sgp4.propagation.wgs72old' - Legacy support for old SGP4 behavior
 *
 * Normally, computations are made using various recent improvements
 * to the algorithm.  If you want to turn some of these off and go
 * back into "afspc" mode, then set 'afspc_mode' to 'True'.
 */
Map<String, dynamic> twoline2satrec(String longstr1, String longstr2) {
  final opsmode = 'i';
  final xpdotp = 1440.0 / (2.0 * pi); // 229.1831180523293;
  var year = 0;

  final Map<String, dynamic> satrec = {};
  satrec['error'] = 0;

  satrec['satnum'] = longstr1.substring(2, 7);

  satrec['epochyr'] = int.parse(longstr1.substring(18, 20));
  satrec['epochdays'] = double.parse(longstr1.substring(20, 32));
  satrec['ndot'] = double.parse(longstr1.substring(33, 43));
  satrec['nddot'] = double.parse(
    '.${int.parse(longstr1.substring(44, 50))}E${longstr1.substring(50, 52)}',
  );
  satrec['bstar'] = double.parse(
    '${longstr1.substring(53, 54)}.${int.parse(longstr1.substring(54, 59))}E${longstr1.substring(59, 61)}',
  );

  // satrec['satnum'] = longstr2.substring(2, 7);
  satrec['inclo'] = double.parse(longstr2.substring(8, 16));
  satrec['nodeo'] = double.parse(longstr2.substring(17, 25));
  satrec['ecco'] = double.parse('.${longstr2.substring(26, 33)}');
  satrec['argpo'] = double.parse(longstr2.substring(34, 42));
  satrec['mo'] = double.parse(longstr2.substring(43, 51));
  satrec['no'] = double.parse(longstr2.substring(52, 63));

  // ---- find no, ndot, nddot ----
  satrec['no'] /= xpdotp; //   rad/min
  // satrec['nddot']= satrec['nddot'] * Math.pow(10.0, nexp);
  // satrec['bstar']= satrec['bstar'] * Math.pow(10.0, ibexp);

  // ---- convert to sgp4 units ----
  satrec['a'] = Math.pow((satrec['no'] * tumin), (-2.0 / 3.0));
  satrec['ndot'] /= (xpdotp * 1440.0); // ? * minperday
  satrec['nddot'] /= (xpdotp * 1440.0 * 1440);

  // ---- find standard orbital elements ----
  satrec['inclo'] *= deg2rad;
  satrec['nodeo'] *= deg2rad;
  satrec['argpo'] *= deg2rad;
  satrec['mo'] *= deg2rad;

  satrec['alta'] = (satrec['a'] * (1.0 + satrec['ecco'])) - 1.0;
  satrec['altp'] = (satrec['a'] * (1.0 - satrec['ecco'])) - 1.0;

  // ----------------------------------------------------------------
  // find sgp4epoch time of element set
  // remember that sgp4 uses units of days from 0 jan 1950 (sgp4epoch)
  // and minutes from the epoch (time)
  // ----------------------------------------------------------------

  // ---------------- temp fix for years from 1957-2056 -------------------
  // --------- correct fix will occur when year is 4-digit in tle ---------

  if (satrec['epochyr'] < 57) {
    year = satrec['epochyr'] + 2000;
  } else {
    year = satrec['epochyr'] + 1900;
  }

  final mdhmsResult = days2mdhms(year, satrec['epochdays']);

  final mon = mdhmsResult.mon;
  final day = mdhmsResult.day;
  final hr = mdhmsResult.hr;
  final minute = mdhmsResult.minute;
  final sec = mdhmsResult.sec;
  satrec['jdsatepoch'] = jday(year, mon, day, hr, minute, sec);

  //  ---------------- initialize the orbit at sgp4epoch -------------------
  sgp4init(satrec, {
    'opsmode': opsmode,
    'satn': satrec['satnum'],
    'epoch': satrec['jdsatepoch'] - 2433281.5,
    'xbstar': satrec['bstar'],
    'xecco': satrec['ecco'],
    'xargpo': satrec['argpo'],
    'xinclo': satrec['inclo'],
    'xmo': satrec['mo'],
    'xno': satrec['no'],
    'xnodeo': satrec['nodeo'],
  });

  return satrec;
}
