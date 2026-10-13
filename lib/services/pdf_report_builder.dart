import 'dart:typed_data';

import 'package:finance/widget/form_widget.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:finance/database/card_service.dart';
import 'package:finance/database/transaction_repository.dart';
import 'package:finance/extentions/extentions.dart';

const _regularAsset = 'assets/fonts/Vazirmatn-RD-Regular.ttf';
const _boldAsset =
    'assets/fonts/Vazirmatn-RD-Bold.ttf'; // اگه نداری، خودش Regular می‌گیره

const _ink = PdfColor.fromInt(0xFF1A1A1A);
const _muted = PdfColor.fromInt(0xFF6B6B6B);
const _line = PdfColor.fromInt(0xFFD9D9D9);
const _soft = PdfColor.fromInt(0xFFF3F3F3);
const _green = PdfColor.fromInt(0xFF0F6E56);
const _red = PdfColor.fromInt(0xFFA32D2D);
const _blue = PdfColor.fromInt(0xFF185FA5);

// ترتیب ستون‌ها از چپ به راست (چون صفحه RTL هست، راست‌ترین = تاریخ)
// موجودی بعد | مبلغ | منبع | دسته‌بندی | تاریخ
const _flex = [24, 23, 13, 25, 15];

pw.Widget _t(
  String s, {
  double size = 10,
  PdfColor color = _ink,
  bool bold = false,
  bool ltr = false,
  pw.TextAlign align = pw.TextAlign.right,
}) => pw.Text(
  s,
  textAlign: align,
  textDirection: ltr ? pw.TextDirection.ltr : pw.TextDirection.rtl,
  style: pw.TextStyle(
    fontSize: size,
    color: color,
    fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
  ),
);

pw.Widget _cell(pw.Widget child, int flex) => pw.Expanded(
  flex: flex,
  child: pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
    child: child,
  ),
);

/// مبلغ ذخیره‌شده (ریال) → متن قابل نمایش طبق واحد پول و نوع ارقام
String _money(num rial, {bool plus = false}) {
  final r = rial.round();
  final s = formatAmount(toDisplayAmount(r));
  if (r < 0) return '−$s';
  return plus ? '+$s' : s;
}

String _two(int n) => n.toString().padLeft(2, '0');

Future<pw.Font> _loadFont(String asset) async =>
    pw.Font.ttf(await rootBundle.load(asset));

Future<Uint8List> buildReportPdf({
  required List<TransactionWithCategory> rows,
  required DateTime from,
  required DateTime to,
}) async {
  final regular = await _loadFont(_regularAsset);
  pw.Font bold;
  try {
    bold = await _loadFont(_boldAsset);
  } catch (_) {
    bold = regular;
  }

  final doc = pw.Document(
    theme: pw.ThemeData.withFont(base: regular, bold: bold),
  );

  // ── جمع‌ها ──
  double income = 0, expense = 0;
  final byCat = <String, double>{};
  for (final r in rows) {
    final t = r.transaction;
    if (t.type == 'income') {
      income += t.amount;
    } else {
      expense += t.amount;
      byCat[r.category.name] = (byCat[r.category.name] ?? 0) + t.amount;
    }
  }

  // ── کارت ──
  final card = CardService.instance.getCard();
  final bank = card['bankName'] ?? '';
  final digits = toLatinDigits(
    card['number'] ?? '',
  ).replaceAll(RegExp(r'[^0-9]'), '');
  final last4 = digits.length >= 4
      ? digits.substring(digits.length - 4).farsiNumber
      : '';

  // ── تاریخ ──
  final fromJ = gregorianToJalali(from.year, from.month, from.day);
  final toJ = gregorianToJalali(to.year, to.month, to.day);
  final crossYear = fromJ[0] != toJ[0];

  String shortDate(DateTime d) {
    if (crossYear) {
      final j = gregorianToJalali(d.year, d.month, d.day);
      return '${j[0]}/${_two(j[1])}/${_two(j[2])}'.farsiNumber;
    }
    final p = formatJalali(d).split(' ');
    return '${p[0]} ${p[1]}';
  }

  // ── ردیف‌ها ──
  pw.Widget colHeader() => pw.Container(
    color: _soft,
    child: pw.Row(
      children: [
        _cell(
          _t('موجودی بعد', size: 9, bold: true, align: pw.TextAlign.left),
          _flex[0],
        ),
        _cell(
          _t('مبلغ', size: 9, bold: true, align: pw.TextAlign.left),
          _flex[1],
        ),
        _cell(_t('منبع', size: 9, bold: true), _flex[2]),
        _cell(_t('دسته‌بندی', size: 9, bold: true), _flex[3]),
        _cell(_t('تاریخ', size: 9, bold: true), _flex[4]),
      ],
    ),
  );

  pw.Widget txRow(TransactionWithCategory r) {
    final t = r.transaction;
    final isIncome = t.type == 'income';
    final bal = t.balanceAfterRial;
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _line, width: 0.5)),
      ),
      child: pw.Row(
        children: [
          _cell(
            _t(
              bal == null ? '—' : _money(bal),
              ltr: true,
              size: 9,
              color: bal == null ? _muted : _ink,
              align: pw.TextAlign.left,
            ),
            _flex[0],
          ),
          _cell(
            _t(
              '${isIncome ? '+' : '−'}${_money(t.amount)}',
              ltr: true,
              size: 9,
              color: isIncome ? _green : _red,
              align: pw.TextAlign.left,
            ),
            _flex[1],
          ),
          _cell(
            _t(t.source == 'manual' ? 'دستی' : 'پیامک', size: 9, color: _muted),
            _flex[2],
          ),
          _cell(_t(r.category.name, size: 9), _flex[3]),
          _cell(_t(shortDate(t.date), size: 9, ltr: crossYear), _flex[4]),
        ],
      ),
    );
  }

  // ── کارت‌های خلاصه (چپ → راست: تراز، هزینه، درآمد) ──
  pw.Widget stat(String label, String value, PdfColor color) => pw.Expanded(
    child: pw.Container(
      margin: const pw.EdgeInsets.symmetric(horizontal: 3),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: _soft,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          _t(label, size: 9, color: _muted),
          pw.SizedBox(height: 2),
          _t(value, size: 12, bold: true, color: color, ltr: true),
        ],
      ),
    ),
  );

  // ── خط کارت (چپ → راست: ارقام، بعد متن) ──
  pw.Widget cardLine() {
    if (bank.isEmpty && last4.isEmpty) return pw.SizedBox();
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        if (last4.isNotEmpty)
          _t(
            '•••• $last4',
            size: 9,
            color: _muted,
            ltr: true,
            align: pw.TextAlign.left,
          ),
        _t(
          bank.isEmpty ? 'کارت: ' : 'کارت: $bank${last4.isEmpty ? '' : ' · '}',
          size: 9,
          color: _muted,
        ),
      ],
    );
  }

  pw.Widget bigHeader() => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _t(
                'Noxa',
                size: 16,
                bold: true,
                color: _blue,
                ltr: true,
                align: pw.TextAlign.left,
              ),
              pw.SizedBox(height: 4),
              _t(
                'تاریخ تهیه: ${formatJalali(DateTime.now())}',
                size: 9,
                color: _muted,
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              _t('گزارش گردش مالی', size: 18, bold: true),
              pw.SizedBox(height: 4),
              _t(
                'بازه: ${formatJalali(from)} تا ${formatJalali(to)}',
                size: 9,
                color: _muted,
              ),
              pw.SizedBox(height: 2),
              cardLine(),
            ],
          ),
        ],
      ),
      pw.SizedBox(height: 8),
      pw.Divider(color: _line, thickness: 0.8),
      pw.SizedBox(height: 8),
      pw.Row(
        children: [
          stat('تراز', _money(income - expense), _ink),
          stat('کل هزینه', _money(expense), _red),
          stat('کل درآمد', _money(income), _green),
        ],
      ),
      pw.SizedBox(height: 6),
      _t('مبالغ به $currencyName', size: 9, color: _muted),
      pw.SizedBox(height: 8),
    ],
  );

  pw.Widget slimHeader() => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _t(
            'Minty',
            size: 10,
            color: _blue,
            ltr: true,
            align: pw.TextAlign.left,
          ),
          _t(
            'گزارش گردش مالی${last4.isEmpty ? '' : ' · کارت $last4'}',
            size: 9,
            color: _muted,
          ),
        ],
      ),
      pw.SizedBox(height: 6),
      pw.Divider(color: _line, thickness: 0.8),
      pw.SizedBox(height: 4),
      colHeader(),
    ],
  );

  // ── خلاصه‌ی دسته‌بندی (صفحه‌ی آخر) ──
  pw.Widget categorySection() {
    if (expense <= 0) return pw.SizedBox();

    final sorted = byCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    var g = sorted;
    if (sorted.length > 4) {
      final rest = sorted.skip(4).fold<double>(0, (a, b) => a + b.value);
      g = [...sorted.take(4), MapEntry('سایر', rest)];
    }

    const cf = [30, 40, 30]; // مبلغ | سهم | دسته‌بندی

    pw.Widget bar(double p) => pw.Container(
      width: 80,
      height: 5,
      decoration: pw.BoxDecoration(
        color: _soft,
        borderRadius: pw.BorderRadius.circular(3),
      ),
      child: pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Container(
          width: 80 * p / 100,
          height: 5,
          decoration: pw.BoxDecoration(
            color: _blue,
            borderRadius: pw.BorderRadius.circular(3),
          ),
        ),
      ),
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.SizedBox(height: 18),
        _t('خلاصه هزینه‌ها به تفکیک دسته‌بندی', size: 12, bold: true),
        pw.SizedBox(height: 6),
        pw.Container(
          color: _soft,
          child: pw.Row(
            children: [
              _cell(
                _t('مبلغ', size: 9, bold: true, align: pw.TextAlign.left),
                cf[0],
              ),
              _cell(_t('سهم', size: 9, bold: true), cf[1]),
              _cell(_t('دسته‌بندی', size: 9, bold: true), cf[2]),
            ],
          ),
        ),
        for (final e in g)
          pw.Container(
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: _line, width: 0.5),
              ),
            ),
            child: pw.Row(
              children: [
                _cell(
                  _t(
                    _money(e.value),
                    size: 9,
                    ltr: true,
                    align: pw.TextAlign.left,
                  ),
                  cf[0],
                ),
                _cell(
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      _t(
                        '${(e.value / expense * 100).round()}٪'.farsiNumber,
                        size: 9,
                        ltr: true,
                      ),
                      pw.SizedBox(width: 6),
                      bar(e.value / expense * 100),
                    ],
                  ),
                  cf[1],
                ),
                _cell(_t(e.key, size: 9), cf[2]),
              ],
            ),
          ),
      ],
    );
  }

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(32, 32, 32, 28),
      textDirection: pw.TextDirection.rtl,
      maxPages: 500,
      header: (ctx) => ctx.pageNumber == 1 ? pw.SizedBox() : slimHeader(),
      footer: (ctx) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 8),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _t(
              'Minty',
              size: 9,
              color: _muted,
              ltr: true,
              align: pw.TextAlign.left,
            ),
            _t(
              'صفحه ${ctx.pageNumber} از ${ctx.pagesCount}'.farsiNumber,
              size: 9,
              color: _muted,
            ),
          ],
        ),
      ),
      build: (ctx) => [
        bigHeader(),
        colHeader(),
        ...rows.map(txRow),
        categorySection(),
      ],
    ),
  );

  return doc.save();
}
