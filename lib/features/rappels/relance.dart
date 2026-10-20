import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/api/api_exception.dart';
import '../../core/utils/format.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/widgets/ui.dart';

/// Rappel d'un client : message poli envoyé sur WhatsApp par le serveur (WAHA),
/// pour le total qu'il doit encore. Aperçu du message avant l'envoi.
Future<void> relancerClient(
  BuildContext context, {
  required int clientId,
  required String clientNom,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (_) => _RelanceSheet(clientId: clientId, clientNom: clientNom),
);

class _RelanceSheet extends ConsumerStatefulWidget {
  const _RelanceSheet({required this.clientId, required this.clientNom});

  final int clientId;
  final String clientNom;

  @override
  ConsumerState<_RelanceSheet> createState() => _RelanceSheetState();
}

class _RelanceSheetState extends ConsumerState<_RelanceSheet> {
  late Future<({String message, String telephone, double totalDu})> _apercu =
      _charger();
  bool _pending = false;
  String? _error;

  Future<({String message, String telephone, double totalDu})> _charger() =>
      ref.read(clientRepositoryProvider).apercuRappel(widget.clientId);

  Future<void> _envoyer() async {
    setState(() {
      _pending = true;
      _error = null;
    });
    try {
      await ref.read(clientRepositoryProvider).envoyerRappel(widget.clientId);
      if (!mounted) return;
      showSuccess(context, 'Rappel envoyé à ${widget.clientNom} sur WhatsApp.');
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = errorMessage(e));
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final bulle = dark ? const Color(0xFF144D37) : const Color(0xFFDCF8C6);
    final surBulle = dark ? const Color(0xFFE7F5EE) : const Color(0xFF14321F);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Gap.xxl, 0, Gap.xxl, Gap.xxl),
        child: FutureBuilder(
          future: _apercu,
          builder: (context, snapshot) {
            final apercu = snapshot.data;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SheetHeader(
                  leading: InitialsAvatar(widget.clientNom, size: 48),
                  title: 'Relancer ${widget.clientNom}',
                  subtitle:
                      apercu == null
                          ? 'Rappel sur WhatsApp'
                          : 'WhatsApp · ${formatTelephone(apercu.telephone)}',
                ),
                if (_error != null) ErrorBanner(_error!),
                if (snapshot.hasError)
                  ErrorBanner(errorMessage(snapshot.error!))
                else if (apercu == null)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: Gap.xxl),
                    child: LoadingState(),
                  )
                else ...[
                  Text('Message envoyé', style: theme.textTheme.titleSmall),
                  const SizedBox(height: Gap.sm),
                  Container(
                    padding: const EdgeInsets.all(Gap.lg),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainer,
                      borderRadius: Radii.lgAll,
                    ),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                        decoration: BoxDecoration(
                          color: bulle,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(Radii.md),
                            topRight: Radius.circular(Radii.md),
                            bottomLeft: Radius.circular(Radii.md),
                            bottomRight: Radius.circular(4),
                          ),
                        ),
                        child: Text(
                          apercu.message,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: surBulle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: Gap.xl),
                if (snapshot.hasError)
                  FilledButton.tonalIcon(
                    onPressed: () => setState(() => _apercu = _charger()),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Réessayer'),
                  )
                else
                  FilledButton.icon(
                    onPressed: apercu == null || _pending ? null : _envoyer,
                    icon:
                        _pending
                            ? const ButtonSpinner()
                            : const Icon(Icons.send_rounded),
                    label: const Text('Envoyer sur WhatsApp'),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Appel téléphonique.
Future<void> appeler(BuildContext context, String? telephone) async {
  final national = nationalNumber(telephone);
  if (national == null) return;
  final ok = await launchUrl(Uri(scheme: 'tel', path: '+221$national'));
  if (!ok && context.mounted) {
    showError(context, 'Impossible de lancer l\'appel sur cet appareil.');
  }
}
