import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart' show BuildContext, Offset, Rect, RenderBox, ScaffoldMessenger, SnackBar, Text, debugPrint;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pulz_app/features/private_events/domain/models/private_event.dart';
import 'package:share_plus/share_plus.dart';

/// Export PDF de la liste des invites d'un event prive, pour l'organisateur
/// (partage WhatsApp, impression pour l'entree...).
///
///  - confirmation activee : tableau des CONFIRMES (ordre de confirmation)
///    avec nom, prenom, age, telephone, e-mail, pseudo ; puis les inscrits
///    pas encore confirmes ;
///  - sinon : tableau des inscrits (pseudo, date d'inscription).
///
/// Polices standard PDF (Helvetica) : pas d'emoji, caracteres hors Latin-1
/// retires (sinon glyphes manquants).
class GuestListPdf {
  GuestListPdf._();

  static final _magenta = PdfColor.fromInt(0xFFE91E63);
  static final _grey = PdfColor.fromInt(0xFF6B6B7B);

  /// Garde le texte imprimable avec Helvetica (Latin-1 + ponctuation usuelle).
  static String _clean(String? s) {
    if (s == null) return '';
    const extra = '’‘“”–…€';
    final b = StringBuffer();
    // Tiret long (U+2014) remplace par un tiret simple (absent de Helvetica).
    // Ligatures absentes de Helvetica : œ / Œ ecrits en deux lettres.
    final src = s
        .replaceAll('\u2014', '-')
        .replaceAll('\u0153', 'oe')
        .replaceAll('\u0152', 'OE');
    for (final r in src.runes) {
      final ch = String.fromCharCode(r);
      if ((r >= 0x20 && r <= 0xFF) || extra.contains(ch)) b.write(ch);
    }
    // Un emoji retire laisse un double espace : on le resserre.
    return b.toString().replaceAll(RegExp(r'\s{2,}'), ' ').trim();
  }

  static String _eventLine(PrivateEvent e) {
    final d = DateTime.tryParse(e.date);
    final parts = <String>[
      if (d != null) DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(d) else e.date,
      if (e.heure.isNotEmpty) e.heure,
      if (e.lieu.isNotEmpty) e.lieu,
    ];
    return _clean(parts.join('  ·  '));
  }

  /// Construit le PDF et renvoie le fichier (dossier temporaire).
  static Future<File> build({
    required PrivateEvent event,
    required List<PrivateEventRsvp> rsvps,
    required List<PrivateEventConfirmation> confirmations,
  }) async {
    final bytes = await buildBytes(event: event, rsvps: rsvps, confirmations: confirmations);
    final dir = await getTemporaryDirectory();
    final slug = _clean(event.title)
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final file = File('${dir.path}/invites-${slug.isEmpty ? 'event' : slug}.pdf');
    await file.writeAsBytes(bytes);
    return file;
  }

  /// Contenu du PDF (sans fichier : testable).
  static Future<Uint8List> buildBytes({
    required PrivateEvent event,
    required List<PrivateEventRsvp> rsvps,
    required List<PrivateEventConfirmation> confirmations,
  }) async {
    final doc = pw.Document(
      title: 'Liste des invités - ${_clean(event.title)}',
      author: 'MaCity',
    );
    final withConfirmation = event.confirmationRequise;
    final confirmedIds = confirmations.map((c) => c.userId).toSet();
    final pending = rsvps.where((r) => !confirmedIds.contains(r.userId)).toList();
    final fmtDate = DateFormat("dd/MM/yyyy 'à' HH'h'mm", 'fr_FR');

    final summary = [
      event.maxParticipants != null
          ? '${rsvps.length} inscrit${rsvps.length > 1 ? 's' : ''} / ${event.maxParticipants} places'
          : '${rsvps.length} inscrit${rsvps.length > 1 ? 's' : ''}',
      if (withConfirmation)
        '${confirmations.length} confirmé${confirmations.length > 1 ? 's' : ''}',
    ].join('  ·  ');

    pw.Widget sectionTitle(String t) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 16, bottom: 6),
          child: pw.Text(
            t,
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _magenta),
          ),
        );

    pw.Widget table(List<String> headers, List<List<String>> rows) =>
        pw.TableHelper.fromTextArray(
          headers: headers,
          data: rows,
          headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          headerDecoration: pw.BoxDecoration(color: _magenta),
          cellStyle: const pw.TextStyle(fontSize: 9),
          cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
          oddRowDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF6F2F8)),
          border: pw.TableBorder.all(color: PdfColor.fromInt(0xFFDDD6E3), width: 0.5),
          cellAlignment: pw.Alignment.centerLeft,
        );

    final pseudoOf = {for (final r in rsvps) r.userId: r.prenom ?? ''};

    doc.addPage(
      pw.MultiPage(
        pageFormat: withConfirmation ? PdfPageFormat.a4.landscape : PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 36),
        header: (ctx) => ctx.pageNumber == 1
            ? pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Liste des invités',
                      style: pw.TextStyle(fontSize: 11, color: _grey)),
                  pw.SizedBox(height: 2),
                  pw.Text(_clean(event.title),
                      style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text(_eventLine(event), style: const pw.TextStyle(fontSize: 11)),
                  pw.SizedBox(height: 4),
                  pw.Text(summary,
                      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _magenta)),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Généré le ${fmtDate.format(DateTime.now())} avec MaCity',
                    style: pw.TextStyle(fontSize: 8, color: _grey),
                  ),
                  pw.Divider(color: PdfColor.fromInt(0xFFDDD6E3)),
                ],
              )
            : pw.SizedBox(),
        footer: (ctx) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Document confidentiel : données personnelles, à ne pas diffuser au-delà de l\'organisation de la soirée.',
              style: pw.TextStyle(fontSize: 7, color: _grey),
            ),
            pw.Text('${ctx.pageNumber} / ${ctx.pagesCount}',
                style: pw.TextStyle(fontSize: 8, color: _grey)),
          ],
        ),
        build: (ctx) => [
          if (withConfirmation) ...[
            sectionTitle('Confirmés (${confirmations.length})  ·  ordre de confirmation'),
            if (confirmations.isEmpty)
              pw.Text('Aucune confirmation pour le moment.',
                  style: pw.TextStyle(fontSize: 10, color: _grey))
            else
              table(
                ['N°', 'Nom', 'Prénom', 'Âge', 'Téléphone', 'E-mail', 'Pseudo', 'Confirmé le'],
                [
                  for (var i = 0; i < confirmations.length; i++)
                    [
                      '${i + 1}',
                      _clean(confirmations[i].nom.toUpperCase()),
                      _clean(confirmations[i].prenom),
                      confirmations[i].age?.toString() ?? '',
                      _clean(confirmations[i].tel),
                      _clean(confirmations[i].email),
                      _clean(confirmations[i].pseudo ?? pseudoOf[confirmations[i].userId]),
                      confirmations[i].confirmedAt == null
                          ? ''
                          : fmtDate.format(confirmations[i].confirmedAt!.toLocal()),
                    ],
                ],
              ),
            if (pending.isNotEmpty) ...[
              sectionTitle('Inscrits non confirmés (${pending.length})'),
              table(
                ['N°', 'Pseudo', 'Inscrit le'],
                [
                  for (var i = 0; i < pending.length; i++)
                    ['${i + 1}', _clean(pending[i].prenom ?? 'Anonyme'), fmtDate.format(pending[i].createdAt.toLocal())],
                ],
              ),
            ],
          ] else ...[
            sectionTitle('Inscrits (${rsvps.length})'),
            if (rsvps.isEmpty)
              pw.Text('Personne pour le moment.',
                  style: pw.TextStyle(fontSize: 10, color: _grey))
            else
              table(
                ['N°', 'Pseudo', 'Inscrit le'],
                [
                  for (var i = 0; i < rsvps.length; i++)
                    ['${i + 1}', _clean(rsvps[i].prenom ?? 'Anonyme'), fmtDate.format(rsvps[i].createdAt.toLocal())],
                ],
              ),
          ],
        ],
      ),
    );

    return doc.save();
  }

  /// Genere puis ouvre la feuille de partage (WhatsApp, e-mail...).
  /// [buttonContext] : ancrage de la feuille de partage iOS.
  static Future<void> share(
    BuildContext buttonContext, {
    required PrivateEvent event,
    required List<PrivateEventRsvp> rsvps,
    required List<PrivateEventConfirmation> confirmations,
  }) async {
    final messenger = ScaffoldMessenger.maybeOf(buttonContext);
    Rect? origin;
    final box = buttonContext.findRenderObject();
    if (box is RenderBox && box.hasSize) {
      origin = box.localToGlobal(Offset.zero) & box.size;
    }
    try {
      final file = await build(event: event, rsvps: rsvps, confirmations: confirmations);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        text: 'Liste des invités : ${event.title}',
        sharePositionOrigin: origin,
      );
    } catch (e) {
      debugPrint('[guest-list-pdf] $e');
      messenger?.showSnackBar(
        const SnackBar(content: Text('Export PDF impossible, réessaie')),
      );
    }
  }
}
