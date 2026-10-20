import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/api/api_client.dart';
import 'feedback.dart';
import 'ui.dart';

/// Liste paginée de l'API : défilement infini et « tirer pour rafraîchir ».
/// Se recharge depuis la première page quand [resetKey] change (filtres, données modifiées).
class PagedList<T> extends StatefulWidget {
  const PagedList({
    super.key,
    required this.fetch,
    required this.itemBuilder,
    required this.resetKey,
    required this.empty,
    this.header,
    this.padding = const EdgeInsets.only(bottom: 96),
    this.divider,
  });

  final Future<Paged<T>> Function(int page) fetch;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final Object resetKey;
  final Widget empty;
  final Widget? header;
  final EdgeInsets padding;

  /// Séparateur affiché entre deux éléments.
  final Widget? divider;

  @override
  State<PagedList<T>> createState() => _PagedListState<T>();
}

class _PagedListState<T> extends State<PagedList<T>> {
  final _items = <T>[];
  int _page = 0;
  bool _hasMore = true;
  bool _loading = false;
  Object? _error;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(covariant PagedList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resetKey != widget.resetKey) _reload();
  }

  Future<void> _reload() async {
    _generation++;
    setState(() {
      _items.clear();
      _page = 0;
      _hasMore = true;
      _error = null;
      _loading = false;
    });
    await _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    final generation = _generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await widget.fetch(_page + 1);
      if (!mounted || generation != _generation) return;
      setState(() {
        _items.addAll(page.items);
        _page = page.currentPage;
        _hasMore = page.hasMore;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final header = widget.header;
    if (_items.isEmpty) {
      final Widget body =
          _error != null
              ? Padding(
                key: const ValueKey('erreur'),
                padding: const EdgeInsets.only(top: 48),
                child: ErrorState(error: _error!, onRetry: _reload),
              )
              : _loading
              ? const Padding(
                key: ValueKey('chargement'),
                padding: EdgeInsets.only(top: Gap.sm),
                child: SkeletonList(),
              )
              : Padding(
                key: const ValueKey('vide'),
                padding: const EdgeInsets.only(top: 48),
                child: widget.empty,
              );
      return RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            if (header != null) header,
            AnimatedSwitcher(duration: Motion.medium, child: body),
          ],
        ),
      );
    }

    final offset = header == null ? 0 : 1;
    return RefreshIndicator(
      onRefresh: _reload,
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.pixels >= n.metrics.maxScrollExtent - 300) _loadMore();
          return false;
        },
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: widget.padding,
          itemCount: _items.length + offset + 1,
          itemBuilder: (context, index) {
            if (header != null && index == 0) return header;
            final i = index - offset;
            if (i < _items.length) {
              final item = widget.itemBuilder(context, _items[i]);
              final divider = widget.divider;
              if (divider == null || i == _items.length - 1) return item;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [item, divider],
              );
            }
            if (_error != null) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: TextButton.icon(
                    onPressed: _loadMore,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Réessayer'),
                  ),
                ),
              );
            }
            if (_hasMore) {
              WidgetsBinding.instance.addPostFrameCallback((_) => _loadMore());
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
              );
            }
            return const SizedBox(height: 8);
          },
        ),
      ),
    );
  }
}
