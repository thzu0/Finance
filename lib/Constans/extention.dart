import 'package:finance/extentions/extentions.dart';

/// عدد و واحدش (هزار/میلیون تومان) رو جدا برمی‌گردونه
({String value, String unit}) formatShortAmountParts(double amount) {
  final n = amount.round();
  final digitCount = n.abs().toString().length;

  if (digitCount > 7) {
    final millions = n / 1000000.0;
    var text = millions.toStringAsFixed(1);
    if (text.endsWith('.0')) {
      text = text.substring(0, text.length - 2);
    }
    return (value: text.farsiNumber, unit: 'میلیون تومان');
  } else {
    final thousands = (n / 1000).round();
    return (value: thousands.toString().farsiNumber, unit: 'هزار تومان');
  }
}
