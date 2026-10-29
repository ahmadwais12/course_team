import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/components/skeleton_widgets.dart';
import 'package:course_emis/widgets/adaptive/adaptive_widgets.dart';

class AsyncWidget<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final Widget? loading;
  final Widget Function(Object error, StackTrace? stack)? error;
  final bool shimmer;
  final Widget? skeleton;

  const AsyncWidget({
    super.key,
    required this.value,
    required this.builder,
    this.loading,
    this.error,
    this.shimmer = false,
    this.skeleton,
  });

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: builder,
      loading: () => loading ?? (shimmer
          ? (skeleton ?? const SkeletonDashboard())
          : const Center(child: AdaptiveProgress())),
      error: (err, stack) => error?.call(err, stack) ?? Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48,
                  color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text(err.toString(), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class FutureWidget<T> extends StatelessWidget {
  final Future<T> future;
  final Widget Function(T data) builder;
  final Widget? loading;
  final Widget Function(Object error)? error;
  final Widget? empty;
  final bool shimmer;
  final Widget? skeleton;

  const FutureWidget({
    super.key,
    required this.future,
    required this.builder,
    this.loading,
    this.error,
    this.empty,
    this.shimmer = false,
    this.skeleton,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loading ?? (shimmer
              ? (skeleton ?? const SkeletonDashboard())
              : const Center(child: AdaptiveProgress()));
        }
        if (snapshot.hasError) {
          return error?.call(snapshot.error!) ?? Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48,
                      color: Theme.of(context).colorScheme.error),
                  const SizedBox(height: 16),
                  Text(snapshot.error.toString(), textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }
        final data = snapshot.data;
        if (data == null || (data is List && data.isEmpty)) {
          return empty ?? Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_outlined, size: 64,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text('No data available',
                      style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
          );
        }
        return builder(data);
      },
    );
  }
}
