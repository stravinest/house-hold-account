import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../transaction/domain/entities/transaction.dart';

enum ExportFileFormat { xlsx, csv }

class ExportOptions {
  final DateTime startDate;
  final DateTime endDate;
  final String? transactionType; // null = all, 'expense', 'income', 'asset'
  final bool includeCategory;
  final bool includePaymentMethod;
  final bool includeMemo;
  final bool includeAuthor;
  final bool includeFixedExpense;
  final ExportFileFormat format;

  const ExportOptions({
    required this.startDate,
    required this.endDate,
    this.transactionType,
    this.includeCategory = true,
    this.includePaymentMethod = true,
    this.includeMemo = true,
    this.includeAuthor = false,
    this.includeFixedExpense = false,
    this.format = ExportFileFormat.xlsx,
  });
}

class ExportService {
  static final _dateFormat = DateFormat('yyyy-MM-dd');
  static final _fileNameFormat = DateFormat('yyMMdd_HHmm');

  static List<Transaction> _filterTransactions(
    List<Transaction> transactions,
    ExportOptions options,
  ) {
    var filtered = transactions.where((t) {
      final date = t.date;
      return !date.isBefore(options.startDate) &&
          !date.isAfter(options.endDate);
    }).toList();

    if (options.transactionType != null) {
      filtered = filtered
          .where((t) => t.type == options.transactionType)
          .toList();
    }

    filtered.sort((a, b) => a.date.compareTo(b.date));
    return filtered;
  }

  static String _getTypeLabel(String type, AppLocalizations l10n) {
    switch (type) {
      case 'expense':
        return l10n.transactionExpense;
      case 'income':
        return l10n.transactionIncome;
      case 'asset':
        return l10n.transactionAsset;
      default:
        return type;
    }
  }

  static List<String> _buildHeaders(
    ExportOptions options,
    AppLocalizations l10n,
  ) {
    final headers = <String>[
      l10n.exportColumnDate,
      l10n.exportColumnType,
      l10n.exportColumnAmount,
      l10n.exportColumnTitle,
    ];

    if (options.includeCategory) {
      headers.add(l10n.exportColumnCategory);
    }
    if (options.includePaymentMethod) {
      headers.add(l10n.exportColumnPaymentMethod);
    }
    if (options.includeMemo) {
      headers.add(l10n.exportColumnMemo);
    }
    if (options.includeAuthor) {
      headers.add(l10n.exportColumnAuthor);
    }
    if (options.includeFixedExpense) {
      headers.add(l10n.exportColumnFixedExpense);
    }

    return headers;
  }

  static List<String> _buildRow(
    Transaction t,
    ExportOptions options,
    AppLocalizations l10n,
  ) {
    final row = <String>[
      _dateFormat.format(t.date),
      _getTypeLabel(t.type, l10n),
      t.amount.toString(),
      t.title ?? '',
    ];

    if (options.includeCategory) {
      row.add(t.categoryName ?? '');
    }
    if (options.includePaymentMethod) {
      row.add(t.paymentMethodName ?? '');
    }
    if (options.includeMemo) {
      row.add(t.memo ?? '');
    }
    if (options.includeAuthor) {
      row.add(t.userName ?? '');
    }
    if (options.includeFixedExpense) {
      final isKo = l10n.localeName == 'ko';
      row.add(t.isFixedExpense ? (isKo ? 'O' : 'Yes') : '');
    }

    return row;
  }

  static String _generateFileName(ExportFileFormat format) {
    final timestamp = _fileNameFormat.format(DateTime.now());
    final ext = format == ExportFileFormat.xlsx ? 'xlsx' : 'csv';
    return 'ledger_$timestamp.$ext';
  }

  static Future<File> exportToExcel(
    List<Transaction> transactions,
    ExportOptions options, {
    required AppLocalizations l10n,
  }) async {
    final filtered = _filterTransactions(transactions, options);
    final headers = _buildHeaders(options, l10n);

    final excel = Excel.createExcel();
    final sheetName = l10n.localeName == 'ko' ? '거래내역' : 'Transactions';
    final sheet = excel[sheetName];

    // 기본 시트 삭제
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    // 헤더 작성
    for (var i = 0; i < headers.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          .value = TextCellValue(
        headers[i],
      );
    }

    // 데이터 작성
    for (var rowIdx = 0; rowIdx < filtered.length; rowIdx++) {
      final row = _buildRow(filtered[rowIdx], options, l10n);
      for (var colIdx = 0; colIdx < row.length; colIdx++) {
        final cellValue = row[colIdx];
        // 금액 컬럼(인덱스 2)은 숫자로 저장
        if (colIdx == 2) {
          final numValue = int.tryParse(cellValue);
          if (numValue != null) {
            sheet
                .cell(
                  CellIndex.indexByColumnRow(
                    columnIndex: colIdx,
                    rowIndex: rowIdx + 1,
                  ),
                )
                .value = IntCellValue(
              numValue,
            );
            continue;
          }
        }
        sheet
            .cell(
              CellIndex.indexByColumnRow(
                columnIndex: colIdx,
                rowIndex: rowIdx + 1,
              ),
            )
            .value = TextCellValue(
          cellValue,
        );
      }
    }

    final dir = await getTemporaryDirectory();
    final fileName = _generateFileName(ExportFileFormat.xlsx);
    final filePath = '${dir.path}/$fileName';
    final fileBytes = excel.save();

    if (fileBytes == null) {
      throw Exception('Excel file encoding failed');
    }

    final file = File(filePath);
    await file.writeAsBytes(fileBytes);
    return file;
  }

  static Future<File> exportToCsv(
    List<Transaction> transactions,
    ExportOptions options, {
    required AppLocalizations l10n,
  }) async {
    final filtered = _filterTransactions(transactions, options);
    final headers = _buildHeaders(options, l10n);

    final rows = <List<String>>[headers];
    for (final t in filtered) {
      rows.add(_buildRow(t, options, l10n));
    }

    final csvString = const ListToCsvConverter().convert(rows);

    final dir = await getTemporaryDirectory();
    final fileName = _generateFileName(ExportFileFormat.csv);
    final filePath = '${dir.path}/$fileName';

    // BOM + UTF-8 인코딩으로 한글 보장
    final file = File(filePath);
    final bom = [0xEF, 0xBB, 0xBF];
    final csvBytes = utf8.encode(csvString);
    await file.writeAsBytes([...bom, ...csvBytes]);
    return file;
  }

  static Future<void> exportAndShare(
    List<Transaction> transactions,
    ExportOptions options, {
    required AppLocalizations l10n,
  }) async {
    final File file;
    if (options.format == ExportFileFormat.xlsx) {
      file = await exportToExcel(transactions, options, l10n: l10n);
    } else {
      file = await exportToCsv(transactions, options, l10n: l10n);
    }

    await Share.shareXFiles([XFile(file.path)]);
  }
}
