import 'package:flutter/material.dart';
import 'package:pulz_app/core/l10n/locale_provider.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/services/user_identity_service.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:pulz_app/features/private_events/data/private_event_service.dart';
import 'package:pulz_app/features/private_events/domain/models/private_event.dart';

/// Formulaire de confirmation de venue d'un participant (event prive dont
/// l'hote a active « Activer la confirmation ») : prenom, nom, e-mail, age,
/// telephone. Envoye a l'hote seul (RPC confirm_private_event_attendance).
///
/// Pre-rempli avec les infos deja envoyees : re-confirmer = corriger, sans
/// perdre sa place dans la liste de l'hote (ordre de 1re confirmation).
///
/// Renvoie la liste a jour des participants si l'envoi a reussi, null sinon.
class ConfirmAttendanceSheet extends StatefulWidget {
  final String token;
  final String eventTitle;

  const ConfirmAttendanceSheet({
    super.key,
    required this.token,
    required this.eventTitle,
  });

  static Future<List<PrivateEventRsvp>?> show(
    BuildContext context, {
    required String token,
    required String eventTitle,
  }) {
    return showModalBottomSheet<List<PrivateEventRsvp>>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          ConfirmAttendanceSheet(token: token, eventTitle: eventTitle),
    );
  }

  @override
  State<ConfirmAttendanceSheet> createState() => _ConfirmAttendanceSheetState();
}

class _ConfirmAttendanceSheetState extends State<ConfirmAttendanceSheet> {
  final _service = PrivateEventService();
  final _prenomCtrl = TextEditingController();
  final _nomCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  bool _loading = true;
  bool _busy = false;
  bool _alreadyConfirmed = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  Future<void> _prefill() async {
    final uuid = await UserIdentityService.getUserId();
    final mine =
        await _service.getMyConfirmation(token: widget.token, userId: uuid);
    if (!mounted) return;
    setState(() {
      if (mine != null) {
        _alreadyConfirmed = true;
        _prenomCtrl.text = mine.prenom;
        _nomCtrl.text = mine.nom;
        _emailCtrl.text = mine.email;
        _ageCtrl.text = mine.age?.toString() ?? '';
        _telCtrl.text = mine.tel;
      }
      _loading = false;
    });
  }

  @override
  void dispose() {
    _prenomCtrl.dispose();
    _nomCtrl.dispose();
    _emailCtrl.dispose();
    _ageCtrl.dispose();
    _telCtrl.dispose();
    super.dispose();
  }

  /// Memes regles que la RPC, pour un message immediat sans aller-retour.
  String? _validate() {
    if (_prenomCtrl.text.trim().isEmpty || _nomCtrl.text.trim().isEmpty) {
      return context.l10n.cfErrName;
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
        .hasMatch(_emailCtrl.text.trim())) {
      return context.l10n.cfErrEmail;
    }
    final age = int.tryParse(_ageCtrl.text.trim());
    if (age == null || age < 1 || age > 120) return context.l10n.cfErrAge;
    if (_telCtrl.text.replaceAll(RegExp(r'\D'), '').length < 6) {
      return context.l10n.cfErrPhone;
    }
    return null;
  }

  Future<void> _submit() async {
    final err = _validate();
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final uuid = await UserIdentityService.getUserId();
      final rsvps = await _service.confirmAttendance(
        token: widget.token,
        userId: uuid,
        nom: _nomCtrl.text.trim(),
        prenom: _prenomCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        age: int.parse(_ageCtrl.text.trim()),
        tel: _telCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(rsvps);
    } on PrivateEventException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.code == PrivateEventError.network
            ? context.l10n.cfSendFailed
            : (e.message ?? context.l10n.cfSendFailed);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: Container(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.92),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: SafeArea(
          top: false,
          child: _loading
              ? const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                      child:
                          CircularProgressIndicator(color: AppColors.magenta)),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.lineStrong,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _alreadyConfirmed
                            ? context.l10n.cfEditMine
                            : context.l10n.vaultConfirmMine,
                        style: GoogleFonts.geist(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.cfPrivacy(widget.eventTitle),
                        style: GoogleFonts.geist(
                            fontSize: 12, color: AppColors.textDim),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                              child: _input(context.l10n.cfFirstName, _prenomCtrl,
                                  autofill: AutofillHints.givenName)),
                          const SizedBox(width: 10),
                          Expanded(
                              child: _input(context.l10n.cfLastName, _nomCtrl,
                                  autofill: AutofillHints.familyName)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _input(context.l10n.cfEmail, _emailCtrl,
                          keyboard: TextInputType.emailAddress,
                          autofill: AutofillHints.email),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          SizedBox(
                            width: 96,
                            child: _input(context.l10n.cfAge, _ageCtrl,
                                keyboard: TextInputType.number,
                                formatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(3),
                                ]),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _input(context.l10n.onboardingFieldPhone, _telCtrl,
                                keyboard: TextInputType.phone,
                                autofill: AutofillHints.telephoneNumber),
                          ),
                        ],
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        Text(_error!,
                            style: GoogleFonts.geist(
                                fontSize: 12, color: const Color(0xFFFF6B6B))),
                      ],
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: _busy ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.magenta,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.chip),
                            ),
                            elevation: 0,
                          ),
                          child: _busy
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : Text(
                                  _alreadyConfirmed
                                      ? context.l10n.commonSave
                                      : context.l10n.vaultConfirmMine,
                                  style: GoogleFonts.geist(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _input(
    String label,
    TextEditingController ctrl, {
    TextInputType? keyboard,
    List<TextInputFormatter>? formatters,
    String? autofill,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.geist(fontSize: 12, color: AppColors.textDim)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboard,
          inputFormatters: formatters,
          autofillHints: autofill == null ? null : [autofill],
          textCapitalization: keyboard == null
              ? TextCapitalization.words
              : TextCapitalization.none,
          style: GoogleFonts.geist(fontSize: 14, color: AppColors.text),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: AppColors.surfaceHi,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
