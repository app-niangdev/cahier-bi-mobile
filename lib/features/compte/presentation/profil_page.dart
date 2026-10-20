import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/utils/format.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../app/theme.dart';
import '../../../shared/widgets/fields.dart';
import '../../../shared/widgets/ui.dart';
import '../../auth/presentation/session_controller.dart';

/// Coordonnées secondaires (`PUT /auth/me`). Nom et numéro principal : modifiés par le propriétaire ou l'administrateur.
class ProfilPage extends ConsumerStatefulWidget {
  const ProfilPage({super.key});

  @override
  ConsumerState<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends ConsumerState<ProfilPage> {
  final _form = GlobalKey<FormState>();
  late final _phoneTwo = TextEditingController(
    text: _national(ref.read(profilProvider)?.phoneTwo),
  );
  late final _address = TextEditingController(
    text: ref.read(profilProvider)?.address,
  );
  bool _pending = false;
  ApiException? _error;

  static String _national(String? phone) =>
      phone == null ? '' : formatTelephone(phone).replaceFirst('+221 ', '');

  @override
  void dispose() {
    _phoneTwo.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;
    setState(() => _pending = true);
    try {
      final profil = await ref
          .read(authRepositoryProvider)
          .updateMe(phoneTwo: _phoneTwo.text, address: _address.text);
      ref.read(sessionProvider.notifier).updateProfil(profil);
      if (!mounted) return;
      showSuccess(context, 'Profil mis à jour.');
      context.pop();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profil = ref.watch(profilProvider);
    final error = _error;
    return Scaffold(
      appBar: AppBar(title: const Text('Mes informations')),
      bottomNavigationBar: BottomActionBar(
        child: FilledButton(
          onPressed: _pending ? null : _submit,
          child: _pending ? const ButtonSpinner() : const Text('Enregistrer'),
        ),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Gap.page,
            Gap.sm,
            Gap.page,
            Gap.xxl,
          ),
          children: [
            ContentWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (error != null && error.fieldErrors.isEmpty)
                    ErrorBanner(error.message),
                  FormSection(
                    title: 'Identité',
                    icon: Icons.person_outline_rounded,
                    children: [
                      AppCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Gap.lg,
                          vertical: Gap.xs,
                        ),
                        child: Column(
                          children: [
                            InfoRow(
                              icon: Icons.badge_outlined,
                              label: 'Nom',
                              value: Text(
                                profil?.nomAffiche ?? '',
                                textAlign: TextAlign.end,
                              ),
                            ),
                            const Divider(),
                            InfoRow(
                              icon: Icons.phone_iphone_rounded,
                              label: 'WhatsApp (identifiant)',
                              value: Text(formatTelephone(profil?.phone)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: Gap.sm),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: Gap.xs),
                        child: Text(
                          'Le nom et le numéro principal sont modifiés par le propriétaire ou l\'administrateur.',
                          style: context.text.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  FormSection(
                    title: 'Coordonnées',
                    icon: Icons.contact_phone_outlined,
                    children: [
                      PhoneField(
                        controller: _phoneTwo,
                        label: 'Téléphone secondaire',
                        required: false,
                        errorText: error?.fieldError('phone_two'),
                      ),
                      fieldGap,
                      TextFormField(
                        controller: _address,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          labelText: 'Adresse',
                          prefixIcon: const Icon(Icons.place_outlined),
                          errorText: error?.fieldError('address'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
