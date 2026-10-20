import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/config.dart';
import '../features/entreprise/domain/entreprise.dart';
import '../shared/widgets/ui.dart';
import 'providers.dart';
import 'theme.dart';

/// Version publiée (`GET /app-version`) ; null si le serveur ne répond pas (on ne bloque pas).
final versionInfoProvider = FutureProvider<VersionInfo?>((ref) async {
  try {
    return await ref.read(entrepriseRepositoryProvider).version();
  } catch (_) {
    return null;
  }
});

/// Mise à jour imposée sous `min_version`, proposée quand une version plus récente existe.
/// Sur le Web, la page se met à jour d'elle-même : rien à faire.
class UpdateGate extends ConsumerStatefulWidget {
  const UpdateGate({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<UpdateGate> createState() => _UpdateGateState();
}

class _UpdateGateState extends ConsumerState<UpdateGate> {
  bool _ignoree = false;

  @override
  Widget build(BuildContext context) {
    final info = kIsWeb ? null : ref.watch(versionInfoProvider).value;
    if (info == null) return widget.child;

    if (compareVersions(appVersion, info.min) < 0) {
      return _MiseAJour(info: info, imposee: true);
    }
    if (!_ignoree && compareVersions(appVersion, info.latest) < 0) {
      return Column(
        children: [
          Material(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: SafeArea(
              bottom: false,
              child: ListTile(
                leading: Icon(
                  Icons.system_update_rounded,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                textColor: Theme.of(context).colorScheme.onPrimaryContainer,
                title: Text('Nouvelle version ${info.latest} disponible'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => setState(() => _ignoree = true),
                      child: const Text('Plus tard'),
                    ),
                    if (info.androidUrl != null)
                      FilledButton(
                        onPressed:
                            () => launchUrl(
                              Uri.parse(info.androidUrl!),
                              mode: LaunchMode.externalApplication,
                            ),
                        child: const Text('Mettre à jour'),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: widget.child,
            ),
          ),
        ],
      );
    }
    return widget.child;
  }
}

class _MiseAJour extends StatelessWidget {
  const _MiseAJour({required this.info, required this.imposee});
  final VersionInfo info;
  final bool imposee;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const IconBadge(Icons.system_update_rounded, size: 80),
              const SizedBox(height: Gap.xl),
              Text(
                'Mise à jour nécessaire',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: Gap.sm),
              Text(
                'Votre version ($appVersion) n\'est plus prise en charge. Installez la version ${info.latest} pour continuer.',
                textAlign: TextAlign.center,
              ),
              if (info.releaseNotes != null) ...[
                const SizedBox(height: 8),
                Text(info.releaseNotes!, textAlign: TextAlign.center),
              ],
              const SizedBox(height: 24),
              if (info.androidUrl != null)
                FilledButton.icon(
                  onPressed:
                      () => launchUrl(
                        Uri.parse(info.androidUrl!),
                        mode: LaunchMode.externalApplication,
                      ),
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Télécharger la mise à jour'),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
