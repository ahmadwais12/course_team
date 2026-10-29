import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/models/book.dart';
import 'package:course_emis/providers/book_provider.dart';
import 'package:course_emis/theme.dart';
import 'package:course_emis/widgets/skeleton_loader.dart';
import 'package:course_emis/l10n/locale_keys.dart';

class BooksScreen extends ConsumerWidget {
  const BooksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(booksNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t(LNav.books, ref))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBookDialog(context, ref),
        icon: const Icon(Icons.menu_book_rounded),
        label: Text(t(LCrud.addBook, ref)),
      ),
      body: Padding(
        padding: AppSpacing.paddingLg,
        child: booksAsync.when(
          data: (books) => books.isEmpty
              ? Center(
                  child: Text(t(LCrud.noItemsFound, ref),
                      style: Theme.of(context).textTheme.bodyLarge))
              : ListView.separated(
                  itemCount: books.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) => _BookCard(
                    book: books[index],
                    onEdit: () =>
                        _showBookDialog(context, ref, book: books[index]),
                    onDelete: () =>
                        _confirmDelete(context, ref, books[index]),
                  ),
                ),
          loading: () => const ListSkeleton(itemCount: 6),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }

  Future<void> _showBookDialog(BuildContext context, WidgetRef ref,
      {Book? book}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _AddBookPage(book: book),
        fullscreenDialog: true,
      ),
    );
    if (result == true) ref.invalidate(booksNotifierProvider);
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Book book) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t(L.delete, ref)),
        content: Text(t(LCrud.confirmDeleteItem, ref)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(t(L.cancel, ref))),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(t(L.confirm, ref))),
        ],
      ),
    );
    if (confirm == true) {
      ref.read(booksNotifierProvider.notifier).deleteBook(book.id);
    }
  }
}

class _AddBookPage extends ConsumerStatefulWidget {
  final Book? book;
  const _AddBookPage({this.book});

  @override
  ConsumerState<_AddBookPage> createState() => _AddBookPageState();
}

class _AddBookPageState extends ConsumerState<_AddBookPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtl;
  late final TextEditingController _priceCtl;
  late final TextEditingController _stockCtl;

  bool get _isEdit => widget.book != null;

  @override
  void initState() {
    super.initState();
    _titleCtl = TextEditingController(text: _isEdit ? widget.book!.title : '');
    _priceCtl = TextEditingController(text: _isEdit ? widget.book!.price.toStringAsFixed(0) : '500');
    _stockCtl = TextEditingController(text: _isEdit ? widget.book!.stock.toString() : '50');
  }

  @override
  void dispose() {
    _titleCtl.dispose();
    _priceCtl.dispose();
    _stockCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? t(L.edit, ref) : t(LCrud.addBook, ref)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(t(L.cancel, ref))),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleCtl,
              decoration: InputDecoration(labelText: t(LCrud.bookTitle, ref)),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _priceCtl,
              decoration: InputDecoration(
                  labelText: t(LCourse.price, ref), prefixText: 'PKR '),
              keyboardType: TextInputType.number,
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _stockCtl,
              decoration: InputDecoration(labelText: t(LCrud.bookStock, ref)),
              keyboardType: TextInputType.number,
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () { debugPrint('[books_screen] Save button CLICKED'); _save(); },
              child: Text(_isEdit ? t(L.save, ref) : t(L.add, ref)),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final ref = this.ref;
    if (_isEdit) {
      final updated = widget.book!.copyWith(
        title: _titleCtl.text.trim(),
        price: double.parse(_priceCtl.text),
        stock: int.parse(_stockCtl.text),
        description: _titleCtl.text.trim(),
      );
      ref.read(booksNotifierProvider.notifier).updateBook(updated);
    } else {
      final now = DateTime.now();
      final newBook = Book(
        id: 'book_${now.millisecondsSinceEpoch}',
        programId: 'prog_default',
        title: _titleCtl.text.trim(),
        price: double.parse(_priceCtl.text),
        stock: int.parse(_stockCtl.text),
        description: _titleCtl.text.trim(),
        createdAt: now,
      );
      ref.read(booksNotifierProvider.notifier).addBook(newBook);
    }
    Navigator.pop(context, true);
  }
}

class _BookCard extends ConsumerWidget {
  final Book book;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BookCard({
    required this.book,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(child: Icon(Icons.menu_book)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(book.title, style: theme.textTheme.titleLarge),
                    Text(
                        'PKR ${book.price.toStringAsFixed(0)} â€¢ Stock: ${book.stock}',
                        style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit, size: 18),
                label: Text(t(L.edit, ref)),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton.outlined(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
