import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/api/api_exception.dart';
import 'ui.dart';

void _snack(
  BuildContext context,
  String message, {
  required IconData icon,
  Color? iconColor,
  Color? background,
  Color? foreground,
}) {
  final scheme = Theme.of(context).colorScheme;
  final fg = foreground ?? scheme.onInverseSurface;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: background,
        content: Row(
          children: [
            Icon(icon, color: iconColor ?? fg, size: 20),
            const SizedBox(width: Gap.md),
            Expanded(child: Text(message, style: TextStyle(color: fg))),
          ],
        ),
      ),
    );
}

void showSuccess(BuildContext context, String message) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  // Le fond est inversé : la teinte de succès est celle du mode opposé
  final c = AppColors.of(dark ? Brightness.light : Brightness.dark);
  _snack(
    context,
    message,
    icon: Icons.check_circle_rounded,
    iconColor: c.success,
  );
}

void showError(BuildContext context, Object error) {
  final scheme = Theme.of(context).colorScheme;
  _snack(
    context,
    errorMessage(error),
    icon: Icons.error_outline_rounded,
    background: scheme.errorContainer,
    foreground: scheme.onErrorContainer,
  );
}

/// Confirmation avant une action destructive.
Future<bool> confirmer(
  BuildContext context, {
  required String titre,
  required String message,
  String confirmer = 'Confirmer',
  bool danger = true,
}) async {
  final scheme = Theme.of(context).colorScheme;
  final ok = await showDialog<bool>(
    context: context,
    builder:
        (context) => AlertDialog(
          icon: IconBadge(
            danger ? Icons.warning_amber_rounded : Icons.help_outline_rounded,
            color: danger ? scheme.error : scheme.primary,
            size: 48,
          ),
          title: Text(titre, textAlign: TextAlign.center),
          content: Text(message, textAlign: TextAlign.center),
          actionsPadding: const EdgeInsets.fromLTRB(
            Gap.xxl,
            0,
            Gap.xxl,
            Gap.xxl,
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: Gap.md),
                Expanded(
                  child: FilledButton(
                    style:
                        danger
                            ? FilledButton.styleFrom(
                              backgroundColor: scheme.error,
                              foregroundColor: scheme.onError,
                              minimumSize: const Size(0, 50),
                            )
                            : FilledButton.styleFrom(
                              minimumSize: const Size(0, 50),
                            ),
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(
                      confirmer,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
  );
  return ok ?? false;
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.titre,
    this.message,
    this.action,
    this.color,
  });

  final IconData icon;
  final String titre;
  final String? message;
  final Widget? action;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? theme.colorScheme.primary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.withValues(alpha: 0.06),
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.withValues(alpha: 0.12),
                  ),
                  child: Icon(icon, size: 32, color: c),
                ),
              ),
              const SizedBox(height: Gap.lg),
              Text(
                titre,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              if (message != null) ...[
                const SizedBox(height: Gap.xs),
                Text(
                  message!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (action != null) ...[const SizedBox(height: Gap.xl), action!],
            ],
          ),
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => EmptyState(
    icon: Icons.cloud_off_rounded,
    color: Theme.of(context).colorScheme.error,
    titre: 'Chargement impossible',
    message: errorMessage(error),
    action: FilledButton.tonalIcon(
      onPressed: onRetry,
      icon: const Icon(Icons.refresh_rounded),
      label: const Text('Réessayer'),
    ),
  );
}

class LoadingState extends StatelessWidget {
  const LoadingState({super.key});

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: SizedBox(
        width: 32,
        height: 32,
        child: CircularProgressIndicator(strokeWidth: 3),
      ),
    ),
  );
}
