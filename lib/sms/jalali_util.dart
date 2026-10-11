// Dart خالص، بدون وابستگی به Flutter. الگوریتم کلاسیک چرخه‌ی ۳۳ساله.

const List<int> _gDays = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
const List<int> _jDays = [31, 31, 31, 31, 31, 31, 30, 30, 30, 30, 30, 29];

int _div(int a, int b) => (a / b).floor();

bool _isGregorianLeap(int y) => (y % 4 == 0 && y % 100 != 0) || y % 400 == 0;

/// شمسی → میلادی (فقط تاریخ، ساعت ۰۰:۰۰)
DateTime jalaliToGregorian(int jy, int jm, int jd) {
  final y = jy - 979;
  var dayNo = 365 * y + _div(y, 33) * 8 + _div(y % 33 + 3, 4);
  for (var i = 0; i < jm - 1; i++) {
    dayNo += _jDays[i];
  }
  dayNo += jd - 1;

  var g = dayNo + 79;
  var gy = 1600 + 400 * _div(g, 146097);
  g %= 146097;
  var leap = true;
  if (g >= 36525) {
    g--;
    gy += 100 * _div(g, 36524);
    g %= 36524;
    if (g >= 365) {
      g++;
    } else {
      leap = false;
    }
  }
  gy += 4 * _div(g, 1461);
  g %= 1461;
  if (g >= 366) {
    leap = false;
    g--;
    gy += _div(g, 365);
    g %= 365;
  }
  var gm = 0;
  for (var i = 0; i < 12; i++) {
    final len = _gDays[i] + (i == 1 && leap ? 1 : 0);
    if (g < len) {
      gm = i + 1;
      break;
    }
    g -= len;
  }
  return DateTime(gy, gm, g + 1);
}

/// میلادی → شمسی به‌صورت [سال، ماه، روز]
List<int> gregorianToJalali(DateTime date) {
  final gy = date.year - 1600;
  var dayNo =
      365 * gy + _div(gy + 3, 4) - _div(gy + 99, 100) + _div(gy + 399, 400);
  for (var i = 0; i < date.month - 1; i++) {
    dayNo += _gDays[i];
  }
  if (date.month > 2 && _isGregorianLeap(date.year)) dayNo++;
  dayNo += date.day - 1;

  var j = dayNo - 79;
  final cycles = _div(j, 12053);
  j %= 12053;
  var jy = 979 + 33 * cycles + 4 * _div(j, 1461);
  j %= 1461;
  if (j >= 366) {
    jy += _div(j - 1, 365);
    j = (j - 1) % 365;
  }
  var jm = 0;
  for (var i = 0; i < 11 && j >= _jDays[i]; i++) {
    j -= _jDays[i];
    jm = i + 1;
  }
  return [jy, jm + 1, j + 1];
}
