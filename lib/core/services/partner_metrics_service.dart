import 'package:flutter/foundation.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';
import 'package:pulz_app/core/services/user_identity_service.dart';

/// KPI partenaires : consultations de fiche et clics sur le lien.
///
/// Alimente `partner_metrics` via la RPC `record_partner_metric`, qui **filtre
/// elle-même les non-partenaires**. Le client peut donc appeler sans se soucier
/// du statut de la fiche : rien ne sera écrit pour les 4 876 adresses non
/// partenaires (garde-fou volume, cf. l'incident pro_audit_log).
///
/// Ces chiffres sont contractuels : ils alimentent le relevé mensuel promis aux
/// partenaires Premium (consultations, clics, visiteurs distincts).
class PartnerMetricsService {
  PartnerMetricsService._();

  /// Dernière fiche comptée, pour ne pas enregistrer deux vues quand un widget
  /// se reconstruit ou qu'un utilisateur revient d'un aller-retour immédiat.
  static String? _derniereVue;

  /// Consultation d'une fiche partenaire.
  ///
  /// [sourceTable] / [sourceId] viennent de `CommerceModel` ; s'ils sont nuls,
  /// la fiche n'est pas identifiable en base (fiche construite en dur, asset
  /// local) et il n'y a rien à compter.
  static void ficheVue(String? sourceTable, int? sourceId) {
    if (sourceTable == null || sourceId == null) return;
    final cle = '$sourceTable#$sourceId';
    if (cle == _derniereVue) return;
    _derniereVue = cle;
    _envoyer(sourceTable, sourceId, 'fiche_view');
  }

  /// Clic sur le lien du partenaire (site web, Instagram).
  ///
  /// Volontairement PAS déclenché sur « Maps » ni « Appeler » : le contrat parle
  /// du clic vers le site du partenaire. Mélanger les trois gonflerait un
  /// chiffre facturé.
  static void lienClique(String? sourceTable, int? sourceId) {
    if (sourceTable == null || sourceId == null) return;
    // Pas de déduplication ici : deux clics sur le lien sont deux intentions.
    _envoyer(sourceTable, sourceId, 'link_click');
  }

  /// Tir-et-oublie : aucun `await` côté appelant, aucune exception propagée.
  /// L'ouverture d'une fiche ne doit jamais attendre — ni échouer à cause — d'un
  /// enjeu statistique.
  static Future<void> _envoyer(String table, int id, String kind) async {
    try {
      final deviceId = await UserIdentityService.getUserId();
      final dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl)
        ..interceptors.add(SupabaseInterceptor());
      await dio.post(
        'rpc/record_partner_metric',
        data: {
          'p_source_table': table,
          'p_source_id': id,
          'p_kind': kind,
          'p_device_id': deviceId,
        },
      );
    } catch (e) {
      debugPrint('[PartnerMetrics] $kind $table#$id echoue: $e');
    }
  }
}
