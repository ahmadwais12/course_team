import 'package:intl/intl.dart';

/// Formats an amount as a plain grouped number, e.g. `12,500.00`.
String fmtAmount(double v) => NumberFormat('#,##0.00').format(v);

/// Formats an amount with the [currency] code prefix (schema default AFN).
String fmtMoney(double v, {String currency = 'AFN'}) =>
    '$currency ${fmtAmount(v)}';
