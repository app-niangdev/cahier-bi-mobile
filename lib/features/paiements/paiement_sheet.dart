import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/api/api_exception.dart';
import '../../core/domain/enums.dart';
import '../../core/utils/format.dart';
import '../../shared/widgets/fields.dart';
import '../../shared/widgets/montant.dart';
import '../../shared/widgets/ui.dart';
import '../dettes/domain/dette.dart';

/// Saisie d'un versement global : le client paie sur sa dette totale, un seul paiement
/// est enregistré (le serveur l'impute lui-même sur ses achats, du plus ancien au plus récent).
/// Renvoie le montant encaissé, ou null si la saisie est abandonnée.
Future<double?> encaisser(
  BuildContext context, {
  required String titre,
  required double resteDu,
  required Future<void> Function(PaiementPayload paiement) enregistrer,
}) async {
  return showModalBottomSheet<double>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder:
        (context) => _PaiementSheet(
          titre: titre,
          resteDu: resteDu,
          enregistrer: enregistrer,
        ),
  );
}

class _PaiementSheet extends StatefulWidget {
  const _PaiementSheet({
    required this.titre,
    required this.resteDu,
    required this.enregistrer,
  });

  final String titre;
  final double resteDu;
  final Future<void> Function(PaiementPayload paiement) enregistrer;

  @override
  State<_PaiementSheet> createState() => _PaiementSheetState();
}

class _PaiementSheetState extends State<_PaiementSheet> {
  final _form = GlobalKey<FormState>();
  final _montant = TextEditingController();
  final _reference = TextEditingController();
  MethodePaiement _methode = MethodePaiement.especes;
  DateTime _date = DateTime.now();
  bool _pending = false;
  ApiException? _error;

  @override
  void dispose() {
    _montant.dispose();
    _reference.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _pending = true;
      _error = null;
    });
    final montant = parseMontant(_montant.text)!;
    try {
      await widget.enregistrer(
        PaiementPayload(
          montant: montant,
          methode: _methode,
          datePaiement: _date,
          reference: _reference.text.trim(),
        ),
      );
      if (mounted) Navigator.pop(context, montant);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final montant = parseMontant(_montant.text) ?? 0;
    final reste = (widget.resteDu - montant).clamp(0, widget.resteDu);
    final error = _error;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(Gap.xxl, 0, Gap.xxl, Gap.xxl),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SheetHeader(
                  leading: IconBadge(
                    Icons.payments_rounded,
                    color: colors.success,
                    background: colors.successContainer,
                    size: 48,
                  ),
                  title: widget.titre,
                  subtitle: 'Dette totale : ${fcfa(widget.resteDu)}',
                ),
                if (error != null && error.fieldErrors.isEmpty)
                  ErrorBanner(error.message),
                MontantField(
                  controller: _montant,
                  autofocus: true,
                  max: widget.resteDu,
                  errorText: error?.fieldError('montant'),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: Gap.sm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ActionChip(
                    avatar: const Icon(Icons.done_all_rounded, size: 18),
                    label: Text('Tout régler · ${fcfa(widget.resteDu)}'),
                    onPressed:
                        () => setState(
                          () =>
                              _montant.text = fcfa(
                                widget.resteDu,
                                suffix: false,
                              ),
                        ),
                  ),
                ),
                const SizedBox(height: Gap.xl),
                Text('Moyen de paiement', style: theme.textTheme.titleSmall),
                const SizedBox(height: Gap.sm),
                Wrap(
                  spacing: Gap.sm,
                  runSpacing: Gap.sm,
                  children: [
                    for (final m in MethodePaiement.values)
                      ChoiceChip(
                        avatar: Icon(
                          m.icone,
                          size: 18,
                          color:
                              _methode == m
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onSurfaceVariant,
                        ),
                        label: Text(m.label),
                        selected: _methode == m,
                        onSelected: (_) => setState(() => _methode = m),
                      ),
                  ],
                ),
                const SizedBox(height: Gap.xl),
                DateField(
                  label: 'Date du paiement',
                  value: _date,
                  lastDate: DateTime.now(),
                  onChanged: (d) => setState(() => _date = d ?? DateTime.now()),
                ),
                fieldGap,
                TextFormField(
                  controller: _reference,
                  decoration: const InputDecoration(
                    labelText: 'Référence (facultatif)',
                    hintText: 'N° de transaction Wave, Orange Money…',
                    prefixIcon: Icon(Icons.tag_rounded),
                  ),
                ),
                AnimatedSize(
                  duration: Motion.medium,
                  curve: Motion.curve,
                  alignment: Alignment.topCenter,
                  child:
                      montant <= 0 || montant > widget.resteDu + 0.001
                          ? const SizedBox(width: double.infinity)
                          : Padding(
                            padding: const EdgeInsets.only(top: Gap.xl),
                            child: _Bilan(
                              total: widget.resteDu,
                              verse: montant,
                              reste: reste.toDouble(),
                            ),
                          ),
                ),
                const SizedBox(height: Gap.xxl),
                FilledButton.icon(
                  onPressed: _pending ? null : _submit,
                  icon:
                      _pending
                          ? const ButtonSpinner()
                          : const Icon(Icons.check_rounded),
                  label: Text(
                    montant > 0 ? 'Encaisser ${fcfa(montant)}' : 'Encaisser',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dette totale, versement et reste après le versement.
class _Bilan extends StatelessWidget {
  const _Bilan({required this.total, required this.verse, required this.reste});

  final double total;
  final double verse;
  final double reste;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final solde = reste <= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Gap.lg, vertical: Gap.sm),
      decoration: BoxDecoration(
        color: context.scheme.surfaceContainer,
        borderRadius: Radii.mdAll,
      ),
      child: Column(
        children: [
          InfoRow(label: 'Dette totale', value: MontantText(total)),
          InfoRow(
            label: 'Versement',
            value: MontantText(-verse, color: colors.success),
          ),
          const Divider(),
          InfoRow(
            label: solde ? 'Dette soldée' : 'Reste à payer',
            value:
                solde
                    ? Icon(Icons.verified_rounded, color: colors.success)
                    : MontantText(
                      reste,
                      style: context.text.titleMedium,
                      color: colors.danger,
                    ),
          ),
        ],
      ),
    );
  }
}
