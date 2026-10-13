import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:share_plus/share_plus.dart';

import 'package:finance/database/transaction_repository.dart';
import 'package:finance/services/pdf_report_builder.dart';

enum PdfRange { thisMonth, lastMonth, last3Months, all }

class PdfReportService {
  PdfReportService._();

  static Jalali _addMonths(Jalali j, int delta) {
    var y = j.year;
    var m = j.month + delta;
    while (m < 1) {
      m += 12;
      y--;
    }
    while (m > 12) {
      m -= 12;
      y++;
    }
    return Jalali(y, m, 1);
  }

  static ({DateTime start, DateTime end}) _bounds(PdfRange r) {
    final j = Jalali.fromDateTime(DateTime.now());
    switch (r) {
      case PdfRange.thisMonth:
        return (
          start: _addMonths(j, 0).toDateTime(),
          end: _addMonths(j, 1).toDateTime(),
        );
      case PdfRange.lastMonth:
        return (
          start: _addMonths(j, -1).toDateTime(),
          end: _addMonths(j, 0).toDateTime(),
        );
      case PdfRange.last3Months:
        return (
          start: _addMonths(j, -2).toDateTime(),
          end: _addMonths(j, 1).toDateTime(),
        );
      case PdfRange.all:
        return (start: DateTime(2000), end: DateTime(2100));
    }
  }

  /// false یعنی توی بازه تراکنشی نبود
  static Future<bool> exportAndShare(PdfRange range) async {
    final b = _bounds(range);
    final rows = await getTransactionsInRange(b.start, b.end);
    if (rows.isEmpty) return false;

    // برای «همه»، بازه‌ی واقعی از اولین تا آخرین تراکنش (rows جدید → قدیم)
    final from = range == PdfRange.all ? rows.last.transaction.date : b.start;
    final to = range == PdfRange.all
        ? rows.first.transaction.date
        : b.end.subtract(const Duration(days: 1));

    final bytes = await buildReportPdf(rows: rows, from: from, to: to);

    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/minty_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(bytes, flush: true);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/pdf')],
        subject: 'گزارش گردش مالی',
      ),
    );
    return true;
  }
}
