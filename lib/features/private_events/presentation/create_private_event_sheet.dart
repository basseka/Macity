import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
class CreatePrivateEventSheet extends StatefulWidget {
  final VoidCallback? onCreated;

  const CreatePrivateEventSheet({super.key, this.onCreated});

  static Future<void> show(BuildContext context, {VoidCallback? onCreated}) {
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreatePrivateEventSheet(onCreated: onCreated),
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
  DateTime? _date;
  String? _localPhotoPath;
  String? _photoUrl; // upload Storage
  bool _uploadingPhoto = false;
  bool _busy = false;
  String? _error;

  PrivateEvent? _created; // step 2 si non null

  @override
  void dispose() {
    _titleCtrl.dispose();
    _lieuCtrl.dispose();
    _adresseCtrl.dispose();
    _descriptionCtrl.dispose();
    _heureCtrl.dispose();
    _passcodeCtrl.dispose();
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
        _error = 'Echec upload photo';
      });
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Donne un titre a ton event');
      return;
    }
    if (_date == null) {
      setState(() => _error = 'Choisis une date');
      return;
    }
    final code = _passcodeCtrl.text.trim();
    if (code.length != 4 || int.tryParse(code) == null) {
      setState(() => _error = 'Le code doit faire 4 chiffres');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final hostUuid = await UserIdentityService.getUserId();
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
      if (!mounted) return;
      widget.onCreated?.call();
      setState(() {
        _busy = false;
        _created = created;
      });
    } on PrivateEventException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.code == PrivateEventError.invalidInput
            ? (e.message ?? 'Champ invalide')
            : 'Echec creation, reessaie';
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
                'Creer un event privé',
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
            'Coffre secret partage par lien + code',
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
                            'Ajouter une affiche (optionnel)',
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

          _input('Titre', _titleCtrl, hint: 'Anniv de ...'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _dateField()),
              const SizedBox(width: 10),
              SizedBox(
                width: 110,
                child: _input(
                  'Heure',
                  _heureCtrl,
                  hint: '21h00',
                  keyboard: TextInputType.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _input('Lieu', _lieuCtrl, hint: 'Chez moi, club...'),
          const SizedBox(height: 12),
          _input('Adresse', _adresseCtrl, hint: '5 rue X, Toulouse'),
          const SizedBox(height: 12),
          _input(
            'Description',
            _descriptionCtrl,
            hint: 'BYOB, dress code...',
            maxLines: 2,
          ),
          const SizedBox(height: 16),

          // Passcode mis en avant
          Container(
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
                      'Code secret a partager (4 chiffres)',
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
                      'Creer mon event',
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
        ? 'Choisir une date'
        : DateFormat('EEE d MMM yyyy', 'fr_FR').format(_date!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date',
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

/// Construit le texte d'invitation a partager (Share.share). Public pour
/// reutilisation depuis la liste "Mes soirees privees".
String buildPrivateEventShareText(PrivateEvent event) {
  final buf = StringBuffer();
  buf.writeln('Tu es invite(e) a mon event privé 🎉');
  buf.writeln(event.title);
  if (event.lieu.isNotEmpty) buf.writeln('📍 ${event.lieu}');
  if (event.adresse.isNotEmpty) buf.writeln('   ${event.adresse}');
  final d = DateTime.tryParse(event.date);
  final friendly =
      d != null ? DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(d) : event.date;
  buf.writeln('📅 $friendly'
      '${event.heure.isNotEmpty ? " - ${event.heure}" : ""}');
  buf.writeln('');
  buf.writeln('👉 Ouvre le coffre (clique, le token se remplit tout seul) :');
  buf.writeln('https://macity.app/coffre/${event.accessToken}');
  buf.writeln('');
  buf.writeln('Code a taper : ${event.passcode}');
  return buf.toString();
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
              'Coffre cree !',
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
            'Partage le lien et le code separement, par message ou whatsapp.',
            style: GoogleFonts.geist(
              fontSize: 12,
              color: AppColors.textDim,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: () =>
                  Share.share(buildPrivateEventShareText(event)),
              icon: const Icon(Icons.share, size: 18),
              label: Text(
                'Partager',
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
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: onClose,
              child: Text(
                'Fermer',
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
                const SnackBar(
                  content: Text('Copie dans le presse-papiers'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            icon: Icon(
              Icons.copy,
              size: 18,
              color: AppColors.textFaint,
            ),
            tooltip: 'Copier',
          ),
        ],
      ),
    );
  }
}
