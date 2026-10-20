import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/ui.dart';
import 'session_controller.dart';

/// Démarrage : restauration de la session, ou serveur injoignable avec « Réessayer ».
class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    return Scaffold(
      body: SafeArea(
        child:
            session.status == SessionStatus.offline
                ? ErrorState(
                  error: session.error!,
                  onRetry: () => ref.read(sessionProvider.notifier).restore(),
                )
                : const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      BrandMark(size: 56),
                      SizedBox(height: Gap.xxxl),
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}
