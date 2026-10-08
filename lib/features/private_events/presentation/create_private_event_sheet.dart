import 'dart:io';
import 'package:pulz_app/core/l10n/labels.dart';
import 'package:pulz_app/core/l10n/locale_provider.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pulz_app/core/services/user_identity_service.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:pulz_app/features/day/data/user_event_supabase_service.dart';
import 'package:pulz_app/features/private_events/data/private_event_service.dart';
import 'package:pulz_app/features/private_events/domain/models/private_event.dart';
import 'package:share_plus/share_plus.dart';

/// Sheet en 2 etapes : 1) form de creation, 2) confirmation + bouton partager.
/// Avec [initial] : mode modification (form pre-rempli, lien et code
/// inchanges, fermeture directe apres enregistrement).
class CreatePrivateEventSheet extends StatefulWidget {
  final VoidCallback? onCreated;
  final PrivateEvent? initial;

  const CreatePrivateEventSheet({super.key, this.onCreated, this.initial});

  static Future<void> show(BuildContext context, {VoidCallback? onCreated}) {
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreatePrivateEventSheet(onCreated: onCreated),
    );
  }

  static Future<void> showEdit(
    BuildContext context,
    PrivateEvent event, {
    VoidCallback? onSaved,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          CreatePrivateEventSheet(initial: event, onCreated: onSaved),
    );
  }

  @override
  State<CreatePrivateEventSheet> createState() =>
      _CreatePrivateEventSheetState();
}

class _CreatePrivateEventSheetState extends State<CreatePrivateEventSheet> {
  final _titleCtrl = TextEditingController();
  final _lieuCtrl = TextEditingController();
  final _adresseCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _heureCtrl = TextEditingController();
  final _passcodeCtrl = TextEditingController();
  /// Nombre maximum de participants ; vide = illimite.
  final _maxCtrl = TextEditingController();
  DateTime? _date;
  String? _localPhotoPath;
  String? _photoUrl; // upload Storage
  bool _uploadingPhoto = false;
  bool _busy = false;
  String? _error;
  /// Demander aux participants de confirmer leur venue (nom, prenom, e-mail,
  /// age, telephone). Enregistre par set_private_event_confirmation apres la
  /// creation / modification (RPC separee : create/update restent inchanges).
  bool _confirmation = false;

  PrivateEvent? _created; // step 2 si non null

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final e = widget.initial;
    if (e != null) {
      _titleCtrl.text = e.title;
      _lieuCtrl.text = e.lieu;
      _adresseCtrl.text = e.adresse;
      _descriptionCtrl.text = e.description;
      _heureCtrl.text = e.heure;
      _passcodeCtrl.text = e.passcode;
      _date = DateTime.tryParse(e.date);
      _photoUrl = e.photoUrl;
      _confirmation = e.confirmationRequise;
      _maxCtrl.text = e.maxParticipants?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _lieuCtrl.dispose();
    _adresseCtrl.dispose();
    _descriptionCtrl.dispose();
    _heureCtrl.dispose();
    _passcodeCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _localPhotoPath = picked.path;
      _uploadingPhoto = true;
      _error = null;
    });
    try {
      final url = await UserEventSupabaseService().uploadPhoto(picked.path);
      if (!mounted) return;
      setState(() {
        _photoUrl = url;
        _uploadingPhoto = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _uploadingPhoto = false;
        _error = context.l10n.pvPhotoUploadFailed;
      });
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // En modification, un event deja passe garde sa date comme borne basse.
    final firstDate =
        _date != null && _date!.isBefore(today) ? _date! : today;
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: firstDate,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) {
      setState(() => _error = context.l10n.pvErrTitle);
      return;
    }
    if (_date == null) {
      setState(() => _error = context.l10n.pvErrDate);
      return;
    }
    final code = _passcodeCtrl.text.trim();
    if (!_isEdit && (code.length != 4 || int.tryParse(code) == null)) {
      setState(() => _error = context.l10n.pvErrCode);
      return;
    }
    final maxText = _maxCtrl.text.trim();
    final int? maxParticipants = maxText.isEmpty ? null : int.tryParse(maxText);
    if (maxText.isNotEmpty &&
        (maxParticipants == null || maxParticipants < 1 || maxParticipants > 1000)) {
      setState(() => _error = context.l10n.pvErrSeats);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final hostUuid = await UserIdentityService.getUserId();
      if (_isEdit) {
        await PrivateEventService().updatePrivateEvent(
          token: widget.initial!.accessToken,
          hostDeviceUuid: hostUuid,
          title: _titleCtrl.text.trim(),
          date: _date!,
          heure: _heureCtrl.text.trim(),
          lieu: _lieuCtrl.text.trim(),
          adresse: _adresseCtrl.text.trim(),
          description: _descriptionCtrl.text.trim(),
          photoUrl: _photoUrl,
        );
        if (maxParticipants != widget.initial!.maxParticipants) {
          await PrivateEventService().setMaxParticipants(
            token: widget.initial!.accessToken,
            hostDeviceUuid: hostUuid,
            max: maxParticipants,
          );
        }
        if (_confirmation != widget.initial!.confirmationRequise) {
          await PrivateEventService().setConfirmationRequired(
            token: widget.initial!.accessToken,
            hostDeviceUuid: hostUuid,
            enabled: _confirmation,
          );
        }
        if (!mounted) return;
        widget.onCreated?.call();
        Navigator.of(context).pop();
        return;
      }
      final created = await PrivateEventService().createPrivateEvent(
        hostDeviceUuid: hostUuid,
        title: _titleCtrl.text.trim(),
        passcode: code,
        date: _date!,
        heure: _heureCtrl.text.trim(),
        lieu: _lieuCtrl.text.trim(),
        adresse: _adresseCtrl.text.trim(),
        description: _descriptionCtrl.text.trim(),
        photoUrl: _photoUrl,
      );
      var result = created;
      if (maxParticipants != null) {
        try {
          await PrivateEventService().setMaxParticipants(
            token: created.accessToken,
            hostDeviceUuid: hostUuid,
            max: maxParticipants,
          );
          result = result.copyWith(maxParticipants: maxParticipants);
        } catch (_) {}
      }
      if (_confirmation) {
        // Event deja cree : un echec ici ne doit pas faire croire a l'hote
        // que rien n'a ete enregistre (il pourra l'activer via Modifier).
        try {
          await PrivateEventService().setConfirmationRequired(
            token: created.accessToken,
            hostDeviceUuid: hostUuid,
            enabled: true,
          );
          result = result.copyWith(confirmationRequise: true);
        } catch (_) {}
      }
      if (!mounted) return;
      widget.onCreated?.call();
      setState(() {
        _busy = false;
        _created = result;
      });
    } on PrivateEventException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.code == PrivateEventError.invalidInput
            ? (e.message ?? context.l10n.pvErrInvalidField)
            : _isEdit
                ? context.l10n.pvErrEditFailed
                : context.l10n.pvErrCreateFailed;
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
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: SafeArea(
          top: false,
          child: _created != null
              ? _SuccessView(
                  event: _created!,
                  onClose: () => Navigator.of(context).pop(),
                )
              : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
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
          Row(
            children: [
              const Icon(
                Icons.lock_outline,
                size: 20,
                color: AppColors.magenta,
              ),
              const SizedBox(width: 8),
              Text(
                _isEdit ? context.l10n.pvEditTitle : context.l10n.pvCreateTitle,
                style: GoogleFonts.geist(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _isEdit
                ? context.l10n.pvEditSubtitle
                : context.l10n.pvCreateSubtitle,
            style: GoogleFonts.geist(fontSize: 12, color: AppColors.textDim),
          ),
          const SizedBox(height: 18),

          // Photo
          GestureDetector(
            onTap: _uploadingPhoto ? null : _pickPhoto,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.surfaceHi,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(
                  color: AppColors.line,
                  style: BorderStyle.solid,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: _localPhotoPath != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(File(_localPhotoPath!), fit: BoxFit.cover),
                        if (_uploadingPhoto)
                          const ColoredBox(
                            color: Colors.black54,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                      ],
                    )
                  : _photoUrl != null && _photoUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: _photoUrl!,
                          fit: BoxFit.cover,
                        )
                  : Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            color: AppColors.textFaint,
                            size: 28,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            context.l10n.pvAddPoster,
                            style: GoogleFonts.geist(
                              fontSize: 12,
                              color: AppColors.textFaint,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 14),

          _input(context.l10n.pvTitle, _titleCtrl, hint: context.l10n.pvTitleHint),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _dateField()),
              const SizedBox(width: 10),
              SizedBox(
                width: 110,
                child: _input(
                  context.l10n.commonTime,
                  _heureCtrl,
                  hint: '21h00',
                  keyboard: TextInputType.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _input(context.l10n.storyPlace, _lieuCtrl, hint: context.l10n.pvPlaceHint),
          const SizedBox(height: 12),
          _input(context.l10n.pvAddress, _adresseCtrl,
              hint: context.l10n.pvAddressHint),
          const SizedBox(height: 12),
          _input(
            context.l10n.ceDescription,
            _descriptionCtrl,
            hint: context.l10n.pvDescriptionHint,
            maxLines: 2,
          ),
          const SizedBox(height: 16),

          // Passcode mis en avant (non modifiable apres creation : il est
          // deja dans les invitations envoyees).
          if (!_isEdit) Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.magenta.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.card),
              border:
                  Border.all(color: AppColors.magenta.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.key, size: 16, color: AppColors.magenta),
                    const SizedBox(width: 6),
                    Text(
                      context.l10n.pvSecretCode,
                      style: GoogleFonts.geist(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _passcodeCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  maxLength: 4,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.geistMono(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 8,
                    color: AppColors.text,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '••••',
                    hintStyle: GoogleFonts.geistMono(
                      fontSize: 22,
                      letterSpacing: 8,
                      color: AppColors.textFaint,
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceHi,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceHi,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              children: [
                const Icon(Icons.group, size: 18, color: AppColors.magenta),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.pvSeats,
                        style: GoogleFonts.geist(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                      ),
                      Text(
                        _isEdit && (widget.initial!.rsvpCount > 0)
                            ? context.l10n
                                .pvSeatsAlready(widget.initial!.rsvpCount)
                            : context.l10n.pvSeatsHint,
                        style: GoogleFonts.geist(fontSize: 11, color: AppColors.textDim),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 72,
                  child: TextField(
                    controller: _maxCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    textAlign: TextAlign.center,
                    style: GoogleFonts.geist(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: '∞',
                      hintStyle: GoogleFonts.geist(fontSize: 15, color: AppColors.textFaint),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceHi,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.line),
            ),
            child: SwitchListTile(
              value: _confirmation,
              onChanged: _busy ? null : (v) => setState(() => _confirmation = v),
              activeColor: AppColors.magenta,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14),
              title: Text(
                context.l10n.pvEnableConfirmation,
                style: GoogleFonts.geist(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
              subtitle: Text(
                context.l10n.pvEnableConfirmationHint,
                style: GoogleFonts.geist(
                  fontSize: 11,
                  color: AppColors.textDim,
                ),
              ),
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: GoogleFonts.geist(
                fontSize: 12,
                color: const Color(0xFFFF6B6B),
              ),
            ),
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
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                elevation: 0,
              ),
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _isEdit ? context.l10n.commonSave : context.l10n.pvCreateMine,
                      style: GoogleFonts.geist(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _input(
    String label,
    TextEditingController ctrl, {
    String? hint,
    int maxLines = 1,
    TextInputType? keyboard,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.geist(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textDim,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: keyboard,
          textCapitalization: maxLines > 1
              ? TextCapitalization.sentences
              : TextCapitalization.words,
          style: GoogleFonts.geist(fontSize: 13, color: AppColors.text),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.geist(
              fontSize: 13,
              color: AppColors.textFaint,
            ),
            filled: true,
            fillColor: AppColors.surfaceHi,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
              borderSide: BorderSide(color: AppColors.line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
              borderSide: BorderSide(color: AppColors.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
              borderSide: const BorderSide(
                color: AppColors.magenta,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dateField() {
    final label = _date == null
        ? context.l10n.pvPickDate
        : DateFormat('EEE d MMM yyyy', context.dateLocale).format(_date!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.commonDate,
          style: GoogleFonts.geist(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textDim,
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceHi,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.line),
            ),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: AppColors.textFaint,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.geist(
                      fontSize: 13,
                      color:
                          _date == null ? AppColors.textFaint : AppColors.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Texte d'invitation "teaser" : volontairement enigmatique. On ne devoile NI
/// le titre, NI le lieu, NI l'adresse, NI la date — l'invite les decouvre en
/// ouvrant le coffre. L'invitation embarque surtout la PHOTO de l'event
/// (cf [sharePrivateEventInvite]). Public pour reutilisation depuis la liste
/// "Mes soirees privees".
String buildPrivateEventShareText(PrivateEvent event, [BuildContext? context]) {
  final l10n = context?.l10n;
  final buf = StringBuffer();
  buf.writeln(l10n?.pvShareOnList ?? '🤫 Tu es sur la liste.');
  buf.writeln(
    l10n?.pvShareTeaser ??
        "Un événement privé t'attend… Ouvre le coffre pour découvrir où, quand et tous les détails 👀",
  );
  buf.writeln('');
  buf.writeln('👉 https://macity.app/coffre/${event.accessToken}');
  buf.writeln(l10n?.pvShareCode(event.passcode) ?? '🔑 Code : ${event.passcode}');
  return buf.toString();
}

/// Partage l'invitation : la PHOTO de l'event (si dispo) + un texte minimal.
/// WhatsApp/Insta affichent alors l'affiche en grand avec juste le lien + le
/// code ; le lieu/la date restent caches jusqu'a l'ouverture du coffre. Si la
/// photo n'est pas dispo (pas d'URL ou download KO), on partage le texte seul.
///
/// [context] = celui du BOUTON : sert d'ancrage a la feuille de partage iOS
/// (`sharePositionOrigin`, obligatoire sur iPad et exige par certaines
/// versions d'iOS ; sans lui la feuille ne s'ouvre pas et l'erreur etait
/// avalee -> « le bouton partager ne marche pas » sur iPhone).
/// Si le partage avec photo echoue, on retente en texte seul ; si tout
/// echoue, l'utilisateur voit un message au lieu de rien.
Future<void> sharePrivateEventInvite(BuildContext context, PrivateEvent event) async {
  final origin = _shareOrigin(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  final text = buildPrivateEventShareText(event, context);

  // Le telechargement de l'affiche peut prendre quelques secondes.
  messenger?.showSnackBar(SnackBar(
    content: Text(context.l10n.pvSharePreparing),
    duration: Duration(seconds: 10),
  ));
  final photo = await _resolveInvitePhoto(event.photoUrl);
  messenger?.hideCurrentSnackBar();

  if (photo != null) {
    try {
      await Share.shareXFiles([photo], text: text, sharePositionOrigin: origin);
      return;
    } catch (e) {
      debugPrint('[private-share] partage avec photo KO, repli texte : $e');
    }
  }
  try {
    await Share.share(text, sharePositionOrigin: origin);
  } catch (e) {
    debugPrint('[private-share] partage texte KO : $e');
    messenger?.showSnackBar(
      SnackBar(content: Text(context.l10n.pvShareFailed)),
    );
  }
}

/// Rectangle du bouton a l'ecran (ancrage de la feuille de partage iOS).
Rect? _shareOrigin(BuildContext context) {
  final box = context.findRenderObject();
  if (box is! RenderBox || !box.hasSize) return null;
  return box.localToGlobal(Offset.zero) & box.size;
}

/// Telecharge la photo de l'event vers un fichier partageable. Renvoie null si
/// pas d'URL http ou si le download echoue/timeout (-> partage texte seul).
Future<XFile?> _resolveInvitePhoto(String? url) async {
  if (url == null || !url.startsWith('http')) return null;
  try {
    final file = await DefaultCacheManager()
        .getSingleFile(url)
        .timeout(const Duration(seconds: 9));
    if (await file.exists() && await file.length() > 0) {
      return XFile(file.path);
    }
  } catch (e) {
    debugPrint('[private-share] photo download failed: $e');
  }
  return null;
}

/// Vue de confirmation : montre le token + passcode et permet de partager.
class _SuccessView extends StatelessWidget {
  final PrivateEvent event;
  final VoidCallback onClose;

  const _SuccessView({required this.event, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
          const SizedBox(height: 18),
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: AppGradients.primary,
                shape: BoxShape.circle,
                boxShadow: AppShadows.neon(AppColors.magenta, blur: 16, y: 4),
              ),
              child: const Icon(Icons.lock, color: Colors.white, size: 30),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              context.l10n.pvVaultCreated,
              style: GoogleFonts.geist(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              event.title,
              style: GoogleFonts.geist(
                fontSize: 13,
                color: AppColors.textDim,
              ),
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 22),
          _CredsBox(label: 'Token', value: event.accessToken, mono: true),
          const SizedBox(height: 10),
          _CredsBox(label: 'Code', value: event.passcode, mono: true, big: true),
          const SizedBox(height: 18),
          Text(
            context.l10n.pvShareSeparately,
            style: GoogleFonts.geist(
              fontSize: 12,
              color: AppColors.textDim,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: Builder(builder: (btnCtx) => ElevatedButton.icon(
              onPressed: () => sharePrivateEventInvite(btnCtx, event),
              icon: const Icon(Icons.share, size: 18),
              label: Text(
                context.l10n.commonShare,
                style: GoogleFonts.geist(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.magenta,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                elevation: 0,
              ),
            )),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: onClose,
              child: Text(
                context.l10n.commonClose,
                style: GoogleFonts.geist(
                  fontSize: 13,
                  color: AppColors.textDim,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CredsBox extends StatelessWidget {
  final String label;
  final String value;
  final bool mono;
  final bool big;

  const _CredsBox({
    required this.label,
    required this.value,
    this.mono = false,
    this.big = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceHi,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.geistMono(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: AppColors.textFaint,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: mono
                      ? GoogleFonts.geistMono(
                          fontSize: big ? 22 : 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: big ? 6 : 0.5,
                          color: AppColors.text,
                        )
                      : GoogleFonts.geist(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.l10n.commonCopied),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            icon: Icon(
              Icons.copy,
              size: 18,
              color: AppColors.textFaint,
            ),
            tooltip: context.l10n.commonCopy,
          ),
        ],
      ),
    );
  }
}
