import 'package:satellite_dart/interfaces/local_date.dart';

/* -----------------------------------------------------------------------------
 *
 *                           procedure days2mdhms
 *
 *  this procedure converts the day of the year, days, to the equivalent month
 *    day, hour, minute and second.
 *
 *  algorithm     : set up array for the number of days per month
 *                  find leap year - use 1900 because 2000 is a leap year
 *                  loop through a temp value while the value is < the days
 *                  perform int conversions to the correct day and month
 *                  convert remainder into h m s using type conversions
 *
 *  author        : david vallado                  719-573-2600    1 mar 2001
 *
 *  inputs          description                    range / units
 *    year        - year                           1900 .. 2100
 *    days        - julian day of the year         0.0  .. 366.0
 *
 *  outputs       :
 *    mon         - month                          1 .. 12
 *    day         - day                            1 .. 28,29,30,31
 *    hr          - hour                           0 .. 23
 *    min         - minute                         0 .. 59
 *    sec         - second                         0.0 .. 59.999
 *
 *  locals        :
 *    dayofyr     - day of year
 *    temp        - temporary extended values
 *    inttemp     - temporary int value
 *    i           - index
 *    lmonth[12]  - int array containing the number of days per month
 *
 *  coupling      :
 *    none.
 * --------------------------------------------------------------------------- */
LocalDate days2mdhms(num year, num days) {
  final lmonth = [
    31,
    (year % 4) == 0 ? 29 : 28,
    31,
    30,
    31,
    30,
    31,
    31,
    30,
    31,
    30,
    31
  ];
  final dayofyr = days.floor();

  //  ----------------- find month and day of month ----------------
  var i = 1;
  var inttemp = 0;
  while ((dayofyr > (inttemp + lmonth[i - 1])) && i < 12) {
    inttemp += lmonth[i - 1];
    i += 1;
  }

  final mon = i;
  final day = dayofyr - inttemp;

  //  ----------------- find hours minutes and seconds -------------
  var temp = (days - dayofyr) * 24.0;
  final hr = temp.floor();
  temp = (temp - hr) * 60.0;
  final minute = temp.floor();
  final sec = (temp - minute) * 60.0;

  return LocalDate(
    mon: mon,
    day: day,
    hr: hr,
    minute: minute,
    sec: sec,
  );
}

/* -----------------------------------------------------------------------------
 *
 *                           procedure jday
 *
 *  this procedure finds the julian date given the year, month, day, and time.
 *    the julian date is defined by each elapsed day since noon, jan 1, 4713 bc.
 *
 *  algorithm     : calculate the answer in one step for efficiency
 *
 *  author        : david vallado                  719-573-2600    1 mar 2001
 *
 *  inputs          description                    range / units
 *    year        - year                           1900 .. 2100
 *    mon         - month                          1 .. 12
 *    day         - day                            1 .. 28,29,30,31
 *    hr          - universal time hour            0 .. 23
 *    min         - universal time min             0 .. 59
 *    sec         - universal time sec             0.0 .. 59.999
 *
 *  outputs       :
 *    jd          - julian date                    days from 4713 bc
 *
 *  locals        :
 *    none.
 *
 *  coupling      :
 *    none.
 *
 *  references    :
 *    vallado       2007, 189, alg 14, ex 3-14
 *
 * --------------------------------------------------------------------------- */
double _jdayInternal(int year, int mon, int day, int hr, int minute, double sec,
    [double msec = 0]) {
  return (((367.0 * year) -
              ((7 * (year + ((mon + 9) / 12.0).floor())) * 0.25).floor()) +
          ((275 * mon) / 9.0).floor() +
          day +
          1721013.5 +
          (((((msec / 60000) + (sec / 60.0) + minute) / 60.0) + hr) /
              24.0) // ut in days
      // # - 0.5*sgn(100.0*year + mon - 190002.5) + 0.5;
      );
}

double? jday(dynamic year,
    [int? mon, int? day, int? hr, int? minute, double? sec, double? msec]) {
  if (year is DateTime) {
    final date = year;
    return _jdayInternal(
      date.year,
      date.month,
      date.day,
      date.hour,
      date.minute,
      date.second.toDouble(),
      date.millisecond.toDouble(),
    );
  }

  if (mon != null &&
      day != null &&
      hr != null &&
      minute != null &&
      sec != null) {
    return _jdayInternal(year as int, mon, day, hr, minute, sec, msec ?? 0);
  }
  return null;
}

/* -----------------------------------------------------------------------------
 *
 *                           procedure invjday
 *
 *  this procedure finds the year, month, day, hour, minute and second
 *  given the julian date. tu can be ut1, tdt, tdb, etc.
 *
 *  algorithm     : set up starting values
 *                  find leap year - use 1900 because 2000 is a leap year
 *                  find the elapsed days through the year in a loop
 *                  call routine to find each individual value
 *
 *  author        : david vallado                  719-573-2600    1 mar 2001
 *
 *  inputs          description                    range / units
 *    jd          - julian date                    days from 4713 bc
 *
 *  outputs       :
 *    year        - year                           1900 .. 2100
 *    mon         - month                          1 .. 12
 *    day         - day                            1 .. 28,29,30,31
 *    hr          - hour                           0 .. 23
 *    min         - minute                         0 .. 59
 *    sec         - second                         0.0 .. 59.999
 *
 *  locals        :
 *    days        - day of year plus fractional
 *                  portion of a day               days
 *    tu          - julian centuries from 0 h
 *                  jan 0, 1900
 *    temp        - temporary double values
 *    leapyrs     - number of leap years from 1900
 *
 *  coupling      :
 *    days2mdhms  - finds month, day, hour, minute and second given days and year
 *
 *  references    :
 *    vallado       2007, 208, alg 22, ex 3-13
 * --------------------------------------------------------------------------- */
dynamic _invjdayInternal(int jd, [bool asArray = false]) {
  // --------------- find year and days of the year -
  final temp = jd - 2415019.5;
  final tu = temp / 365.25;
  var year = 1900 + (tu).floor();
  var leapyrs = ((year - 1901) * 0.25).floor();

  // optional nudge by 8.64x10-7 sec to get even outputs
  var days = (temp - (((year - 1900) * 365.0) + leapyrs)) + 0.00000000001;

  // ------------ check for case of beginning of a year -----------
  if (days < 1.0) {
    year -= 1;
    leapyrs = ((year - 1901) * 0.25).floor();
    days = temp - (((year - 1900) * 365.0) + leapyrs);
  }

  // ----------------- find remaing data  -------------------------
  final mdhms = days2mdhms(year, days.floor());

  final mon = mdhms.mon;
  final day = mdhms.day;
  final hr = mdhms.hr;
  final minute = mdhms.minute;

  final sec = mdhms.sec - 0.00000086400;

  if (asArray) {
    return [year, mon, day, hr, minute, (sec).floor()];
  }

  return DateTime(
    year,
    mon,
    day,
    hr,
    minute,
    (sec).floor(),
  );
}

List<int> invjdayArray(int jd) {
  return _invjdayInternal(jd, true);
}

DateTime invjdayDateTime(int jd) {
  return _invjdayInternal(jd);
}
