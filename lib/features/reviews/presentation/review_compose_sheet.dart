import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/services/user_identity_service.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:pulz_app/core/widgets/star_rating.dart';
import 'package:pulz_app/features/reviews/data/commerce_review_service.dart';
import 'package:pulz_app/features/reviews/domain/models/commerce_review.dart';

/// Bottom sheet "Donner mon avis" / "Modifier mon avis" pour un commerce.
///
/// Si [existing] est fourni, le sheet pre-remplit la note et le commentaire,
/// affiche un bouton "Supprimer mon avis" en plus du submit "Modifier".
class ReviewComposeSheet extends StatefulWidget {
  final String targetKind;
  final int targetId;
  final String commerceName;
  final CommerceReview? existing;
  final VoidCallback? onSubmitted;

  const ReviewComposeSheet({
    super.key,
    required this.targetKind,
    required this.targetId,
    required this.commerceName,
    this.existing,
    this.onSubmitted,
  });

  /// Helper pour ouvrir le sheet.
  static Future<void> show(
    BuildContext context, {
    required String targetKind,
    required int targetId,
    required String commerceName,
    CommerceReview? existing,
    VoidCallback? onSubmitted,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReviewComposeSheet(
        targetKind: targetKind,
        targetId: targetId,
        commerceName: commerceName,
        existing: existing,
        onSubmitted: onSubmitted,
      ),
    );
  }

  @override
  State<ReviewComposeSheet> createState() => _ReviewComposeSheetState();
}

class _ReviewComposeSheetState extends State<ReviewComposeSheet> {
  late int _rating;
  late TextEditingController _commentCtrl;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _rating = widget.existing?.rating ?? 0;
    _commentCtrl = TextEditingController(text: widget.existing?.comment ?? '');
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating < 1) {
      setState(() => _error = 'Choisis une note avant de publier');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final deviceUuid = await UserIdentityService.getUserId();
      await CommerceReviewService().upsertReview(
        targetKind: widget.targetKind,
        targetId: widget.targetId,
        deviceUuid: deviceUuid,
        rating: _rating,
        comment: _commentCtrl.text.trim(),
      );
      if (!mounted) return;
      widget.onSubmitted?.call();
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Echec : reessaye dans un instant';
      });
    }
  }

  Future<void> _delete() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final deviceUuid = await UserIdentityService.getUserId();
      await CommerceReviewService().deleteMyReview(
        targetKind: widget.targetKind,
        targetId: widget.targetId,
        deviceUuid: deviceUuid,
      );
      if (!mounted) return;
      widget.onSubmitted?.call();
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Echec de la suppression';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                  isEdit ? 'Modifier mon avis' : 'Donner mon avis',
                  style: GoogleFonts.geist(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.commerceName,
                  style: GoogleFonts.geist(
                    fontSize: 13,
                    color: AppColors.textDim,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 18),
                Center(
                  child: StarRating(
                    value: _rating.toDouble(),
                    size: 38,
                    interactive: true,
                    onChanged: (v) => setState(() {
                      _rating = v;
                      _error = null;
                    }),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _commentCtrl,
                  maxLines: 5,
                  maxLength: 500,
                  textCapitalization: TextCapitalization.sentences,
                  style: GoogleFonts.geist(
                    fontSize: 13,
                    color: AppColors.text,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Ton ressenti, en quelques mots...',
                    hintStyle: GoogleFonts.geist(
                      fontSize: 13,
                      color: AppColors.textFaint,
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceHi,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      borderSide: const BorderSide(color: AppColors.line),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      borderSide: const BorderSide(color: AppColors.line),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      borderSide:
                          const BorderSide(color: AppColors.magenta, width: 1.5),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: GoogleFonts.geist(
                      fontSize: 12,
                      color: const Color(0xFFFF6B6B),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (isEdit) ...[
                      OutlinedButton.icon(
                        onPressed: _busy ? null : _delete,
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 16,
                          color: Color(0xFFFF6B6B),
                        ),
                        label: Text(
                          'Supprimer',
                          style: GoogleFonts.geist(
                            fontSize: 12,
                            color: const Color(0xFFFF6B6B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFFF6B6B)),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.chip),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _busy ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.magenta,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.chip),
                          ),
                        ),
                        child: _busy
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                isEdit ? 'Modifier' : 'Publier',
                                style: GoogleFonts.geist(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
