import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';
import '../../core/utils/format.dart';

/// Champ téléphone sénégalais (préfixe +221 affiché).
class PhoneField extends StatelessWidget {
  const PhoneField({
    super.key,
    required this.controller,
    this.label = 'Numéro WhatsApp',
    this.required = true,
    this.errorText,
    this.helper,
    this.textInputAction = TextInputAction.next,
  });

  final TextEditingController controller;
  final String label;
  final bool required;
  final String? errorText;
  final String? helper;
  final TextInputAction textInputAction;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    keyboardType: TextInputType.phone,
    textInputAction: textInputAction,
    autofillHints: const [AutofillHints.telephoneNumberNational],
    inputFormatters: [
      FilteringTextInputFormatter.allow(RegExp(r'[\d\s+]')),
      LengthLimitingTextInputFormatter(17),
    ],
    decoration: InputDecoration(
      labelText: label,
      prefixText: '+221 ',
      hintText: '77 123 45 67',
      helperText: helper,
      errorText: errorText,
      prefixIcon: const Icon(Icons.phone_iphone_rounded),
    ),
    validator: (v) => validateTelephone(v, required: required),
  );
}

/// Champ montant en FCFA.
class MontantField extends StatelessWidget {
  const MontantField({
    super.key,
    required this.controller,
    this.label = 'Montant',
    this.max,
    this.errorText,
    this.autofocus = false,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;

  /// Plafond (reste dû)
  final double? max;
  final String? errorText;
  final bool autofocus;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    autofocus: autofocus,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d\s]'))],
    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.w800,
      fontFeatures: const [FontFeature.tabularFigures()],
    ),
    decoration: InputDecoration(
      labelText: label,
      hintText: '0',
      prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
      suffixText: 'FCFA',
      suffixStyle: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(color: context.scheme.onSurfaceVariant),
      errorText: errorText,
      helperText: max == null ? null : 'Maximum : ${fcfa(max)}',
    ),
    onChanged: onChanged,
    validator: (v) {
      final montant = parseMontant(v);
      if (montant == null || montant <= 0) {
        return 'Saisissez un montant supérieur à 0.';
      }
      if (max != null && montant > max! + 0.001) {
        return 'Le montant dépasse le reste dû (${fcfa(max)}).';
      }
      return null;
    },
  );
}

/// Champ mot de passe avec affichage optionnel.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    this.label = 'Mot de passe',
    this.validator,
    this.errorText,
    this.newPassword = false,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final FormFieldValidator<String>? validator;
  final String? errorText;
  final bool newPassword;
  final ValueChanged<String>? onSubmitted;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: widget.controller,
    obscureText: !_visible,
    autofillHints: [
      widget.newPassword ? AutofillHints.newPassword : AutofillHints.password,
    ],
    onFieldSubmitted: widget.onSubmitted,
    decoration: InputDecoration(
      labelText: widget.label,
      errorText: widget.errorText,
      prefixIcon: const Icon(Icons.lock_outline_rounded),
      suffixIcon: IconButton(
        tooltip:
            _visible ? 'Masquer le mot de passe' : 'Afficher le mot de passe',
        icon: Icon(
          _visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        ),
        onPressed: () => setState(() => _visible = !_visible),
      ),
    ),
    validator:
        widget.validator ??
        (v) =>
            (v == null || v.isEmpty)
                ? 'Le mot de passe est obligatoire.'
                : null,
  );
}

/// Mot de passe d'au moins 8 caractères (règle Laravel).
String? validateNewPassword(String? value) =>
    (value == null || value.length < 8) ? 'Au moins 8 caractères.' : null;

/// Sélecteur de date.
class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
    this.clearable = false,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool clearable;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: Radii.mdAll,
    onTap: () async {
      final now = DateTime.now();
      final picked = await showDatePicker(
        context: context,
        initialDate: value ?? now,
        firstDate: firstDate ?? DateTime(now.year - 5),
        lastDate: lastDate ?? DateTime(now.year + 5),
      );
      if (picked != null) onChanged(picked);
    },
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.calendar_today_rounded),
        suffixIcon:
            clearable && value != null
                ? IconButton(
                  tooltip: 'Effacer',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => onChanged(null),
                )
                : const Icon(Icons.expand_more_rounded),
      ),
      child: Text(
        value == null ? 'Aucune' : dateLongue(value),
        style:
            value == null
                ? TextStyle(color: context.scheme.onSurfaceVariant)
                : null,
      ),
    ),
  );
}
