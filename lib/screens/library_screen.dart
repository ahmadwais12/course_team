import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/l10n/locale_keys.dart';
import 'package:course_emis/theme.dart';
import 'package:course_emis/widgets/skeleton_loader.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
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
        title: Text(t(LNav.books, ref)),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: t(LNav.books, ref)),
            Tab(text: t(LModule.library, ref)),
            Tab(text: t(LCrud.status, ref)),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: TabBarView(
            controller: _tabController,
            children: const [
              _BookStore(),
              _MyBooks(),
              _BorrowedBooks(),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookStore extends ConsumerStatefulWidget {
  const _BookStore();

  @override
  ConsumerState<_BookStore> createState() => _BookStoreState();
}

class _BookStoreState extends ConsumerState<_BookStore> {
  List<Map<String, dynamic>> _books = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    try {
      final data = await Supabase.instance.client
          .from('library_books')
          .select()
          .order('created_at', ascending: false);
      if (mounted) setState(() => _books = List<Map<String, dynamic>>.from(data));
    } catch (_) {
      if (mounted) setState(() => _books = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const ListSkeleton(itemCount: 6);

    if (_books.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.book, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(t(LAll.all_no_books_available, ref),
                style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBooks,
      child: ListView(
        padding: AppSpacing.paddingLg,
        children: _books.map<Widget>((b) {
          return _BookCard(
            title: b['title']?.toString() ?? 'Untitled',
            author: b['author']?.toString() ?? 'Unknown',
            price: b['price']?.toString() ?? '\$0',
            rating: (b['rating'] ?? 0.0).toDouble(),
            isPurchased: b['is_purchased'] == true,
            availableCopies: b['available_copies'] ?? 0,
          );
        }).toList(),
      ),
    );
  }
}

class _MyBooks extends ConsumerStatefulWidget {
  const _MyBooks();

  @override
  ConsumerState<_MyBooks> createState() => _MyBooksState();
}

class _MyBooksState extends ConsumerState<_MyBooks> {
  List<Map<String, dynamic>> _myBooks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMyBooks();
  }

  Future<void> _loadMyBooks() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        if (mounted) setState(() => _myBooks = []);
        return;
      }
      final data = await Supabase.instance.client
          .from('purchased_books')
          .select('*, library_books(*)')
          .eq('user_id', userId)
          .order('purchased_at', ascending: false);
      if (mounted) setState(() => _myBooks = List<Map<String, dynamic>>.from(data));
    } catch (_) {
      if (mounted) setState(() => _myBooks = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const ListSkeleton(itemCount: 3);

    if (_myBooks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.library_books, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(t(LAll.all_no_purchased_books_yet, ref),
                style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMyBooks,
      child: ListView(
        padding: AppSpacing.paddingLg,
        children: _myBooks.map((pb) {
          final book = pb['library_books'] as Map<String, dynamic>? ?? {};
          return _BookCard(
            title: book['title']?.toString() ?? 'Untitled',
            author: book['author']?.toString() ?? 'Unknown',
            price: 'Purchased',
            rating: (book['rating'] ?? 0.0).toDouble(),
            isPurchased: true,
            showDownload: true,
          );
        }).toList(),
      ),
    );
  }
}

class _BorrowedBooks extends ConsumerStatefulWidget {
  const _BorrowedBooks();

  @override
  ConsumerState<_BorrowedBooks> createState() => _BorrowedBooksState();
}

class _BorrowedBooksState extends ConsumerState<_BorrowedBooks> {
  List<Map<String, dynamic>> _borrowed = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBorrowed();
  }

  Future<void> _loadBorrowed() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        if (mounted) setState(() => _borrowed = []);
        return;
      }
      final data = await Supabase.instance.client
          .from('borrowed_books')
          .select('*, library_books(*)')
          .eq('user_id', userId)
          .order('borrow_date', ascending: false);
      if (mounted) setState(() => _borrowed = List<Map<String, dynamic>>.from(data));
    } catch (_) {
      if (mounted) setState(() => _borrowed = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const ListSkeleton(itemCount: 3);

    if (_borrowed.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(t(LAll.all_no_borrowed_books, ref),
                style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBorrowed,
      child: ListView(
        padding: AppSpacing.paddingLg,
        children: _borrowed.map((bb) {
          final book = bb['library_books'] as Map<String, dynamic>? ?? {};
          final borrowDate = bb['borrow_date']?.toString() ?? '';
          final returnDate = bb['return_date']?.toString() ?? '';
          final daysLeft = bb['days_left'] ?? 0;
          return _BorrowCard(
            title: book['title']?.toString() ?? 'Untitled',
            author: book['author']?.toString() ?? 'Unknown',
            borrowDate: borrowDate.length >= 10 ? borrowDate.substring(0, 10) : borrowDate,
            returnDate: returnDate.length >= 10 ? returnDate.substring(0, 10) : returnDate,
            daysLeft: daysLeft is int ? daysLeft : int.tryParse(daysLeft.toString()) ?? 0,
          );
        }).toList(),
      ),
    );
  }
}

class _BookCard extends ConsumerWidget {
  final String title;
  final String author;
  final String price;
  final double rating;
  final bool isPurchased;
  final bool showDownload;
  final int availableCopies;

  const _BookCard({
    required this.title,
    required this.author,
    required this.price,
    required this.rating,
    required this.isPurchased,
    this.showDownload = false,
    this.availableCopies = 0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF38BDF8), Color(0xFF67E8F9)]),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(Icons.book, color: Colors.white, size: 40),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text(author, style: theme.textTheme.bodySmall),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    Text(' $rating', style: theme.textTheme.bodySmall),
                    const SizedBox(width: 12),
                    Icon(Icons.copy, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                        tt(LAll.all_x_available, ref, ['$availableCopies']),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.grey[600])),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                if (showDownload)
                  FilledButton.icon(
                    onPressed: () => context.go('/digital-library'),
                    icon: const Icon(Icons.download, size: 18),
                    label: Text(t(LAll.all_download_pdf, ref)),
                  )
                else
                  Row(
                    children: [
                      Text(price,
                          style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold)),
                      const Spacer(),
                      FilledButton(
                        onPressed: isPurchased ? null : () => context.go('/payments'),
                        child: Text(isPurchased ? 'Purchased' : 'Buy'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BorrowCard extends ConsumerWidget {
  final String title;
  final String author;
  final String borrowDate;
  final String returnDate;
  final int daysLeft;

  const _BorrowCard({
    required this.title,
    required this.author,
    required this.borrowDate,
    required this.returnDate,
    required this.daysLeft,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          Text(author, style: theme.textTheme.bodySmall),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t(LAll.all_borrowed, ref),
                        style: theme.textTheme.labelSmall),
                    Text(borrowDate, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t(LAll.all_return_by, ref),
                        style: theme.textTheme.labelSmall),
                    Text(returnDate, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, color: Colors.orange, size: 16),
                const SizedBox(width: 4),
                Text(tt(LAll.all_x_days_left, ref, ['$daysLeft']),
                    style: const TextStyle(
                        color: Colors.orange, fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton(
                    onPressed: () => context.go('/digital-library'),
                    child: Text(t(LAll.all_renew, ref))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}




