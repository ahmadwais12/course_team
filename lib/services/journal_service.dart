import 'package:supabase_flutter/supabase_flutter.dart';

/// One debit/credit line of a journal.
class JournalLine {
  /// Seeded account code, e.g. '1001' (Cash on Hand).
  final String accountCode;
  final double debit;
  final double credit;
  final String? description;

  const JournalLine({
    required this.accountCode,
    this.debit = 0,
    this.credit = 0,
    this.description,
  });

  factory JournalLine.debit(String code, double amount, {String? description}) =>
      JournalLine(accountCode: code, debit: amount, credit: 0, description: description);

  factory JournalLine.credit(String code, double amount, {String? description}) =>
      JournalLine(accountCode: code, debit: 0, credit: amount, description: description);
}

class JournalAccount {
  final String id;
  final String? accountCode;
  final String name;
  final String accountType;
  final String normalBalance;

  const JournalAccount({
    required this.id,
    this.accountCode,
    required this.name,
    required this.accountType,
    required this.normalBalance,
  });

  factory JournalAccount.fromJson(Map<String, dynamic> json) => JournalAccount(
        id: json['id'] as String,
        accountCode: json['account_code'] as String?,
        name: (json['name'] as String?) ?? '',
        accountType: (json['account_type'] as String?) ?? '',
        normalBalance: (json['normal_balance'] as String?) ?? 'debit',
      );
}

/// Validates that journal lines balance (sum debits == sum credits).
/// Pure and unit-testable.
class JournalValidator {
  const JournalValidator._();

  static ({double totalDebit, double totalCredit, String? error}) validate(
    List<JournalLine> lines,
  ) {
    final debits = lines
        .where((l) => l.debit > 0)
        .fold<double>(0, (s, l) => s + l.debit);
    final credits = lines
        .where((l) => l.credit > 0)
        .fold<double>(0, (s, l) => s + l.credit);

    if (lines.isEmpty) {
      return (totalDebit: 0, totalCredit: 0, error: 'Journal has no lines.');
    }
    for (final line in lines) {
      if (line.debit < 0 || line.credit < 0) {
        return (
          totalDebit: debits,
          totalCredit: credits,
          error: 'Debit/credit amounts cannot be negative.',
        );
      }
      if (line.debit > 0 && line.credit > 0) {
        return (
          totalDebit: debits,
          totalCredit: credits,
          error: 'A line cannot be both debit and credit.',
        );
      }
      if (line.debit == 0 && line.credit == 0) {
        return (
          totalDebit: debits,
          totalCredit: credits,
          error: 'A line has no amount.',
        );
      }
    }
    final roundedD = double.parse(debits.toStringAsFixed(2));
    final roundedC = double.parse(credits.toStringAsFixed(2));
    if (roundedD != roundedC) {
      return (
        totalDebit: roundedD,
        totalCredit: roundedC,
        error:
            'Journal is not balanced (debits $roundedD != credits $roundedC).',
      );
    }
    return (totalDebit: roundedD, totalCredit: roundedC, error: null);
  }
}

/// Shared double-entry service (Finance module guide §6.1).
///
/// Posts a balanced journal into `journals` + `journal_entries` and returns
/// the journal id. Always enforces totalDebit == totalCredit before writing.
class JournalService {
  final SupabaseClient _client;

  JournalService([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  /// List the (seeded) chart of accounts.
  Future<List<JournalAccount>> listAccounts() async {
    final rows = await _client.from('accounts').select().order('account_code');
    return rows
        .map((r) => JournalAccount.fromJson(Map<String, dynamic>.from(r)))
        .toList();
  }

  /// Resolve the id for each account code so lines can carry account_id.
  /// Seeded system accounts live on tenant_id NULL; RLS limits visibility.
  Future<Map<String, String>> _resolveAccountIds(Set<String> codes) async {
    if (codes.isEmpty) return {};
    final rows = await _client
        .from('accounts')
        .select('id, account_code, is_active')
        .inFilter('account_code', codes.toList());
    return {
      for (final r in rows)
        (r['account_code'] as String?) ?? '': (r['id'] as String),
    };
  }

  /// Posts a balanced journal. Throws [JournalNotBalancedException] when the
  /// lines do not balance, and [ArgumentError] for unknown account codes.
  Future<String> postJournal({
    required String tenantId,
    required DateTime date,
    required String description,
    required List<JournalLine> lines,
    String? referenceType,
    String? referenceId,
    String? createdBy,
    String? journalNo,
  }) async {
    final result = JournalValidator.validate(lines);
    if (result.error != null) {
      throw JournalNotBalancedException(result.error!);
    }

    final accountIds =
        await _resolveAccountIds({for (final l in lines) l.accountCode});

    final enrichedLines = <JournalLine>[];
    for (final line in lines) {
      if (!accountIds.containsKey(line.accountCode)) {
        throw ArgumentError(
          'Account code ${line.accountCode} not found in chart of accounts.',
        );
      }
      enrichedLines.add(line);
    }

    final now = DateTime.now().toUtc();
    final journalRows = await _client
        .from('journals')
        .insert({
          'tenant_id': tenantId,
          if (journalNo != null && journalNo.isNotEmpty) 'journal_no': journalNo,
          'journal_date': _dateOnly(date),
          'description': description,
          if (referenceType != null) 'reference_type': referenceType,
          if (referenceId != null) 'reference_id': referenceId,
          'total_debit': result.totalDebit,
          'total_credit': result.totalCredit,
          'is_posted': true,
          'posted_at': now.toIso8601String(),
          if (createdBy != null) 'posted_by': createdBy,
          if (createdBy != null) 'created_by': createdBy,
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        })
        .select('id')
        .single();

    final journalId = journalRows['id'] as String;
    final entryRows = [
      for (final line in enrichedLines)
        {
          'journal_id': journalId,
          'account_id': accountIds[line.accountCode],
          'account_code': line.accountCode,
          if (line.description != null && line.description!.isNotEmpty)
            'description': line.description,
          'debit': line.debit,
          'credit': line.credit,
          if (createdBy != null) 'user_id': createdBy,
        },
    ];
    await _client.from('journal_entries').insert(entryRows);
    return journalId;
  }

  /// Fetch a journal with its lines (account code + amount + description).
  Future<Map<String, dynamic>?> getJournal(String journalId) async {
    final journal = await _client
        .from('journals')
        .select()
        .eq('id', journalId)
        .maybeSingle();
    if (journal == null) return null;
    final lines = await _client
        .from('journal_entries')
        .select('account_code, debit, credit, description')
        .eq('journal_id', journalId)
        .order('created_at');
    return {...journal, 'lines': lines};
  }

  /// Recent journals (newest first). RLS scopes the rows to the current
  /// tenant, so no tenant filter is needed client-side.
  Future<List<Map<String, dynamic>>> listJournals({int limit = 50}) async {
    return _client
        .from('journals')
        .select()
        .order('journal_date', ascending: false)
        .limit(limit);
  }

  String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class JournalNotBalancedException implements Exception {
  final String message;
  const JournalNotBalancedException(this.message);
  @override
  String toString() => 'JournalNotBalancedException: $message';
}
