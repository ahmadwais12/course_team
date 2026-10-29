import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/theme.dart';
import 'package:go_router/go_router.dart';
import 'package:course_emis/widgets/base_panel_layout.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/l10n/locale_keys.dart';

// 1. Reception Panel
class ReceptionPanelScreen extends StatefulWidget {
  const ReceptionPanelScreen({super.key});

  @override
  State<ReceptionPanelScreen> createState() => _ReceptionPanelScreenState();
}

class _ReceptionPanelScreenState extends State<ReceptionPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reception'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Inquiries'),
            Tab(text: 'Visitors'),
            Tab(text: 'Registration'),
            Tab(text: 'Appointments'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/admissions'),
        child: const Icon(Icons.add),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ReceptionList(table: 'inquiries', fallbackTable: 'leads', icon: Icons.person, subtitleField: 'course', statusField: 'status'),
          _ReceptionList(table: 'visitors', icon: Icons.badge, subtitlePrefix: 'Time: ', subtitleField: 'time', subtitleSuffix: ' Ã¢â‚¬Â¢ Purpose: ', secondaryField: 'purpose', printAction: true),
          _buildRegistration(),
          _ReceptionList(table: 'appointments', icon: Icons.calendar_today, subtitlePrefix: 'Date: ', subtitleField: 'date', subtitleSuffix: ' Ã¢â‚¬Â¢ Time: ', secondaryField: 'time'),
        ],
      ),
    );
  }

  Widget _buildRegistration() {
    return Center(
        child: ElevatedButton.icon(
      onPressed: () => context.go('/admissions'),
      icon: const Icon(Icons.person_add),
      label: Consumer(builder: (context, ref, _) => Text(t(LStaff.newRegistration, ref))),
    ));
  }
}

class _ReceptionList extends StatefulWidget {
  final String table;
  final String? fallbackTable;
  final IconData icon;
  final String? subtitleField;
  final String? statusField;
  final String? subtitlePrefix;
  final String? subtitleSuffix;
  final String? secondaryField;
  final bool printAction;

  const _ReceptionList({
    required this.table,
    this.fallbackTable,
    required this.icon,
    this.subtitleField,
    this.statusField,
    this.subtitlePrefix,
    this.subtitleSuffix,
    this.secondaryField,
    this.printAction = false,
  });

  @override
  State<_ReceptionList> createState() => _ReceptionListState();
}

class _ReceptionListState extends State<_ReceptionList> {
  List<Map<String, dynamic>> _data = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      List<Map<String, dynamic>> result;
      try {
        result = await Supabase.instance.client.from(widget.table).select().order('created_at', ascending: false).limit(5);
      } catch (_) {
        if (widget.fallbackTable != null) {
          result = await Supabase.instance.client.from(widget.fallbackTable!).select().order('created_at', ascending: false).limit(5);
        } else {
          result = [];
        }
      }
      if (mounted) setState(() { _data = result; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 8),
          Text('Error loading ${widget.table}'),
          const SizedBox(height: 8),
          FilledButton(onPressed: _load, child: const Text('Retry')),
        ],
      ),
    );
    }
    if (_data.isEmpty) {
      return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text('No ${widget.table} records', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          FilledButton(onPressed: _load, child: const Text('Refresh')),
        ],
      ),
    );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: AppSpacing.paddingLg,
        itemCount: _data.length,
        itemBuilder: (context, index) {
          final item = _data[index];
          final title = item['name']?.toString() ?? item['title']?.toString() ?? '${widget.table} #${index + 1}';
          final subtitle = _buildSubtitle(item);
          return Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            child: ListTile(
              leading: CircleAvatar(child: Icon(widget.icon)),
              title: Text(title),
              subtitle: subtitle != null ? Text(subtitle) : null,
              trailing: widget.printAction
                  ? IconButton(
                      icon: const Icon(Icons.print),
                      onPressed: () => context.go('/visitors'),
                    )
                  : const Icon(Icons.arrow_forward_ios, size: 16),
            ),
          );
        },
      ),
    );
  }

  String? _buildSubtitle(Map<String, dynamic> item) {
    final parts = <String>[];
    if (widget.subtitleField != null && item[widget.subtitleField] != null) {
      parts.add(item[widget.subtitleField].toString());
    }
    if (widget.statusField != null && item[widget.statusField] != null) {
      parts.add('Status: ${item[widget.statusField]}');
    }
    if (widget.secondaryField != null && item[widget.secondaryField] != null) {
      parts.add(item[widget.secondaryField].toString());
    }
    return parts.isNotEmpty ? parts.join(' Ã¢â‚¬Â¢ ') : null;
  }
}

// 2. Accountant Panel
class AccountantPanelScreen extends StatefulWidget {
  const AccountantPanelScreen({super.key});

  @override
  State<AccountantPanelScreen> createState() => _AccountantPanelScreenState();
}

class _AccountantPanelScreenState extends State<AccountantPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accountant'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Fees'),
            Tab(text: 'Payments'),
            Tab(text: 'Expenses'),
            Tab(text: 'Reports'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _FinanceList(table: 'fees', icon: Icons.receipt),
          _FinanceList(table: 'payments', icon: Icons.payment),
          _FinanceList(table: 'expenses', icon: Icons.trending_down),
          _FinanceList(table: 'financial_reports', icon: Icons.analytics),
        ],
      ),
    );
  }
}

class _FinanceList extends StatefulWidget {
  final String table;
  final IconData icon;

  const _FinanceList({required this.table, required this.icon});

  @override
  State<_FinanceList> createState() => _FinanceListState();
}

class _FinanceListState extends State<_FinanceList> {
  List<Map<String, dynamic>> _data = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await Supabase.instance.client.from(widget.table).select().order('created_at', ascending: false).limit(10);
      if (mounted) setState(() { _data = result; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 8),
          Text('Error loading ${widget.table}'),
          const SizedBox(height: 8),
          FilledButton(onPressed: _load, child: const Text('Retry')),
        ],
      ),
    );
    }
    if (_data.isEmpty) {
      return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text('No ${widget.table} records'),
          const SizedBox(height: 8),
          FilledButton(onPressed: _load, child: const Text('Refresh')),
        ],
      ),
    );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: AppSpacing.paddingLg,
        itemCount: _data.length,
        itemBuilder: (context, index) {
          final item = _data[index];
          final title = item['title']?.toString() ?? item['name']?.toString() ?? '${widget.table} #${index + 1}';
          final amount = item['amount'] != null ? 'Amount: PKR ${item['amount']}' : null;
          final status = item['status']?.toString();
          final subtitle = [if (amount != null) amount, if (status != null) 'Status: $status'].join(' Ã¢â‚¬Â¢ ');
          return Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            child: ListTile(
              leading: CircleAvatar(child: Icon(widget.icon)),
              title: Text(title),
              subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            ),
          );
        },
      ),
    );
  }
}

// 3. Librarian Panel
class LibrarianPanelScreen extends StatefulWidget {
  const LibrarianPanelScreen({super.key});

  @override
  State<LibrarianPanelScreen> createState() => _LibrarianPanelScreenState();
}

class _LibrarianPanelScreenState extends State<LibrarianPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Librarian'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Books'),
            Tab(text: 'Issued'),
            Tab(text: 'Inventory'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/issue-book'),
        child: const Icon(Icons.qr_code_scanner),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _LibrarianList(table: 'books', icon: Icons.book, subtitleField: 'author', statusField: 'available', statusPrefix: 'Available: '),
          _LibrarianList(table: 'issued_books', icon: Icons.assignment_return, subtitleField: 'due_date', statusPrefix: 'Due: '),
          _LibrarianList(table: 'inventory', icon: Icons.inventory, subtitleField: 'quantity', statusPrefix: 'Qty: '),
        ],
      ),
    );
  }
}

class _LibrarianList extends StatefulWidget {
  final String table;
  final IconData icon;
  final String? subtitleField;
  final String? statusField;
  final String? statusPrefix;

  const _LibrarianList({required this.table, required this.icon, this.subtitleField, this.statusField, this.statusPrefix});

  @override
  State<_LibrarianList> createState() => _LibrarianListState();
}

class _LibrarianListState extends State<_LibrarianList> {
  List<Map<String, dynamic>> _data = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await Supabase.instance.client.from(widget.table).select().order('created_at', ascending: false).limit(10);
      if (mounted) setState(() { _data = result; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 8),
          Text('Error loading ${widget.table}'),
          const SizedBox(height: 8),
          FilledButton(onPressed: _load, child: const Text('Retry')),
        ],
      ),
    );
    }
    if (_data.isEmpty) {
      return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text('No ${widget.table} records'),
          const SizedBox(height: 8),
          FilledButton(onPressed: _load, child: const Text('Refresh')),
        ],
      ),
    );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: AppSpacing.paddingLg,
        itemCount: _data.length,
        itemBuilder: (context, index) {
          final item = _data[index];
          final title = item['title']?.toString() ?? item['name']?.toString() ?? '${widget.table} #${index + 1}';
          final subtitle = _buildSubtitle(item);
          return Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            child: ListTile(
              leading: CircleAvatar(child: Icon(widget.icon)),
              title: Text(title),
              subtitle: subtitle != null ? Text(subtitle) : null,
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            ),
          );
        },
      ),
    );
  }

  String? _buildSubtitle(Map<String, dynamic> item) {
    final parts = <String>[];
    if (widget.subtitleField != null && item[widget.subtitleField] != null) {
      parts.add('${widget.statusPrefix ?? ''}${item[widget.subtitleField]}');
    }
    if (widget.statusField != null && item[widget.statusField] != null) {
      final val = item[widget.statusField];
      parts.add('${widget.statusPrefix ?? ''}$val');
    }
    return parts.isNotEmpty ? parts.join(' Ã¢â‚¬Â¢ ') : null;
  }
}

// 4. HR Panel
class HRPanelScreen extends StatefulWidget {
  const HRPanelScreen({super.key});

  @override
  State<HRPanelScreen> createState() => _HRPanelScreenState();
}

class _HRPanelScreenState extends State<HRPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HR Manager'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Staff'),
            Tab(text: 'Attendance'),
            Tab(text: 'Leaves'),
            Tab(text: 'Payroll'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _HRList(table: 'staff', icon: Icons.person),
          _HRList(table: 'attendance', icon: Icons.event_available),
          _HRList(table: 'leaves', icon: Icons.event_busy),
          _HRList(table: 'payroll', icon: Icons.attach_money),
        ],
      ),
    );
  }
}

class _HRList extends StatefulWidget {
  final String table;
  final IconData icon;

  const _HRList({required this.table, required this.icon});

  @override
  State<_HRList> createState() => _HRListState();
}

class _HRListState extends State<_HRList> {
  List<Map<String, dynamic>> _data = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await Supabase.instance.client.from(widget.table).select().order('created_at', ascending: false).limit(10);
      if (mounted) setState(() { _data = result; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 8),
          Text('Error loading ${widget.table}'),
          const SizedBox(height: 8),
          FilledButton(onPressed: _load, child: const Text('Retry')),
        ],
      ),
    );
    }
    if (_data.isEmpty) {
      return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text('No ${widget.table} records'),
          const SizedBox(height: 8),
          FilledButton(onPressed: _load, child: const Text('Refresh')),
        ],
      ),
    );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: AppSpacing.paddingLg,
        itemCount: _data.length,
        itemBuilder: (context, index) {
          final item = _data[index];
          final title = item['name']?.toString() ?? item['title']?.toString() ?? '${widget.table} #${index + 1}';
          final status = item['status']?.toString();
          final subtitle = status != null ? 'Status: $status' : null;
          return Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            child: ListTile(
              leading: CircleAvatar(child: Icon(widget.icon)),
              title: Text(title),
              subtitle: subtitle != null ? Text(subtitle) : null,
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            ),
          );
        },
      ),
    );
  }
}

// 5. IT Support Panel
class ITSupportPanelScreen extends StatefulWidget {
  const ITSupportPanelScreen({super.key});

  @override
  State<ITSupportPanelScreen> createState() => _ITSupportPanelScreenState();
}

class _ITSupportPanelScreenState extends State<ITSupportPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IT Support'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Devices'),
            Tab(text: 'Tickets'),
            Tab(text: 'Updates'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ITList(table: 'devices', icon: Icons.devices),
          _ITList(table: 'tickets', icon: Icons.bug_report),
          _ITList(table: 'system_updates', icon: Icons.update),
        ],
      ),
    );
  }
}

class _ITList extends StatefulWidget {
  final String table;
  final IconData icon;

  const _ITList({required this.table, required this.icon});

  @override
  State<_ITList> createState() => _ITListState();
}

class _ITListState extends State<_ITList> {
  List<Map<String, dynamic>> _data = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await Supabase.instance.client.from(widget.table).select().order('created_at', ascending: false).limit(10);
      if (mounted) setState(() { _data = result; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 8),
          Text('Error loading ${widget.table}'),
          const SizedBox(height: 8),
          FilledButton(onPressed: _load, child: const Text('Retry')),
        ],
      ),
    );
    }
    if (_data.isEmpty) {
      return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text('No ${widget.table} records'),
          const SizedBox(height: 8),
          FilledButton(onPressed: _load, child: const Text('Refresh')),
        ],
      ),
    );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: AppSpacing.paddingLg,
        itemCount: _data.length,
        itemBuilder: (context, index) {
          final item = _data[index];
          final title = item['name']?.toString() ?? item['title']?.toString() ?? '${widget.table} #${index + 1}';
          final status = item['status']?.toString();
          final subtitle = status != null ? 'Status: $status' : null;
          return Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            child: ListTile(
              leading: CircleAvatar(child: Icon(widget.icon)),
              title: Text(title),
              subtitle: subtitle != null ? Text(subtitle) : null,
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            ),
          );
        },
      ),
    );
  }
}

// 6-12: Simplified panels with dynamic data
class MaintenancePanelScreen extends StatefulWidget {
  const MaintenancePanelScreen({super.key});

  @override
  State<MaintenancePanelScreen> createState() => _MaintenancePanelScreenState();
}

class _MaintenancePanelScreenState extends State<MaintenancePanelScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await Supabase.instance.client.from('maintenance_requests').select().order('created_at', ascending: false).limit(10);
      if (mounted) setState(() { _items = result; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => BasePanelLayout(
    title: 'Maintenance',
    isLoading: _loading,
    children: [
      if (_items.isEmpty)
        Consumer(builder: (context, ref, _) => Text(t(LStaff.noMaintenance, ref))),
      ..._items.map((item) => Card(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        child: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.build)),
          title: Text(item['title']?.toString() ?? 'Maintenance Item'),
          subtitle: Text('Status: ${item['status'] ?? 'Active'}'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        ),
      )),
    ],
  );
}

class StorePanelScreen extends StatefulWidget {
  const StorePanelScreen({super.key});

  @override
  State<StorePanelScreen> createState() => _StorePanelScreenState();
}

class _StorePanelScreenState extends State<StorePanelScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await Supabase.instance.client.from('inventory').select().order('created_at', ascending: false).limit(10);
      if (mounted) setState(() { _items = result; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => BasePanelLayout(
    title: 'Store',
    isLoading: _loading,
    children: [
      if (_items.isEmpty)
        Consumer(builder: (context, ref, _) => Text(t(LStaff.noInventory, ref))),
      ..._items.map((item) => Card(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        child: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.inventory)),
          title: Text(item['name']?.toString() ?? 'Store Item'),
          subtitle: Text('Qty: ${item['quantity'] ?? 'Ã¢â‚¬â€'}'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        ),
      )),
    ],
  );
}

class SupportPanelScreen extends StatefulWidget {
  const SupportPanelScreen({super.key});

  @override
  State<SupportPanelScreen> createState() => _SupportPanelScreenState();
}

class _SupportPanelScreenState extends State<SupportPanelScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await Supabase.instance.client.from('support_tickets').select().order('created_at', ascending: false).limit(10);
      if (mounted) setState(() { _items = result; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => BasePanelLayout(
    title: 'Support',
    isLoading: _loading,
    children: [
      if (_items.isEmpty)
        Consumer(builder: (context, ref, _) => Text(t(LStaff.noTickets, ref))),
      ..._items.map((item) => Card(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        child: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.support)),
          title: Text(item['subject']?.toString() ?? 'Support Item'),
          subtitle: Text('Status: ${item['status'] ?? 'Open'}'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        ),
      )),
    ],
  );
}

class EventsPanelScreen extends StatefulWidget {
  const EventsPanelScreen({super.key});

  @override
  State<EventsPanelScreen> createState() => _EventsPanelScreenState();
}

class _EventsPanelScreenState extends State<EventsPanelScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await Supabase.instance.client.from('events').select().order('created_at', ascending: false).limit(10);
      if (mounted) setState(() { _items = result; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => BasePanelLayout(
    title: 'Events',
    isLoading: _loading,
    children: [
      if (_items.isEmpty)
        Consumer(builder: (context, ref, _) => Text(t(LStaff.noEvents, ref))),
      ..._items.map((item) => Card(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        child: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.event)),
          title: Text(item['title']?.toString() ?? 'Event Item'),
          subtitle: Text('Date: ${item['date'] ?? item['event_date'] ?? 'TBD'}'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        ),
      )),
    ],
  );
}
