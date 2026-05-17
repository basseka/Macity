import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/services/user_identity_service.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:pulz_app/features/engagement/domain/models/device_pseudonym.dart';
import 'package:pulz_app/features/engagement/presentation/widgets/engagement_avatar.dart';
import 'package:pulz_app/features/engagement/state/event_engagement_provider.dart';

/// Dialog "Mon pseudo" — modifie le nom + genre affichés dans les commentaires.
/// L'avatar pravatar reste auto (déterministe par device_uuid).
class EditPseudonymDialog extends ConsumerStatefulWidget {
  final DevicePseudonym current;

  const EditPseudonymDialog({super.key, required this.current});

  static Future<void> show(BuildContext context, DevicePseudonym current) {
    return showDialog(
      context: context,
      builder: (_) => EditPseudonymDialog(current: current),
    );
  }

  @override
  ConsumerState<EditPseudonymDialog> createState() =>
      _EditPseudonymDialogState();
}

class _EditPseudonymDialogState extends ConsumerState<EditPseudonymDialog> {
  late final TextEditingController _controller;
  late String _gender;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.current.displayName);
    _gender = widget.current.gender;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                EngagementAvatar(
                  displayName: _controller.text.isEmpty
                      ? widget.current.displayName
                      : _controller.text,
                  gender: _gender,
                  avatarUrl: widget.current.avatarUrl,
                  size: 44,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Mon pseudo',
                    style: GoogleFonts.geist(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLength: 30,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              style: GoogleFonts.geist(fontSize: 14, color: AppColors.text),
              decoration: InputDecoration(
                labelText: 'Nom affiché',
                labelStyle: GoogleFonts.geist(color: AppColors.textDim),
                counterStyle: GoogleFonts.geistMono(
                  fontSize: 10,
                  color: AppColors.textFaint,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.magenta),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _genderChip('F', 'Femme')),
                const SizedBox(width: 8),
                Expanded(child: _genderChip('M', 'Homme')),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _saving ? null : () => Navigator.of(context).pop(),
                  child: Text(
                    'Annuler',
                    style: GoogleFonts.geist(color: AppColors.textDim),
                  ),
                ),
                const SizedBox(width: 4),
                FilledButton(
                  onPressed: _saving ? null : _onSave,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.magenta,
                    foregroundColor: Colors.white,
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Enregistrer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _genderChip(String value, String label) {
    final selected = _gender == value;
    return GestureDetector(
      onTap: () => setState(() => _gender = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.magenta : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.magenta : AppColors.line,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.geist(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.text,
          ),
        ),
      ),
    );
  }

  Future<void> _onSave() async {
    final newName = _controller.text.trim();
    if (newName.isEmpty) return;
    setState(() => _saving = true);
    try {
      final deviceUuid = await UserIdentityService.getUserId();
      final service = ref.read(engagementServiceProvider);
      await service.updatePseudonym(
        deviceUuid: deviceUuid,
        displayName: newName,
        gender: _gender,
        avatarUrl: widget.current.avatarUrl,
      );
      // Met à jour aussi tous les anciens commentaires de ce device
      await service.updatePastCommentsPseudonym(
        deviceUuid: deviceUuid,
        displayName: newName,
        gender: _gender,
        avatarUrl: widget.current.avatarUrl,
      );
      ref.invalidate(devicePseudonymProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur, réessaie')),
        );
      }
    }
  }
}
