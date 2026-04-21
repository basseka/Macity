# Admin — gestion manuelle des comptes Pro

Intervenir manuellement sur les comptes Pro PUL'Z depuis le **Dashboard Supabase → SQL Editor**.

Le SQL Editor du dashboard tourne en `postgres` / `service_role`, donc les fonctions `admin_*` passent. En dehors du dashboard, ces fonctions sont verrouillées (anon/authenticated reçoivent HTTP 401).

Toutes les actions d'approbation / révocation sont automatiquement enregistrées dans `pro_audit_log` via trigger.

## ✅ Approuver un pro

```sql
SELECT * FROM admin_approve_pro('basseka@yahoo.fr');
```

Retourne `(user_id, nom, email, approved)`. Erreur si aucun profil pro avec cet email.

## ❌ Révoquer un pro

```sql
SELECT * FROM admin_revoke_pro('mauvais@email.com');
```

Passe `approved` à `FALSE`. L'utilisateur perd ses privilèges pro à la prochaine vérification.

## 📋 Lister les pros en attente d'approbation

```sql
SELECT * FROM admin_list_pending_pros();
```

Colonnes : `user_id, nom, type, email, telephone, created_at, email_confirmed` (bool).

## 🔍 Voir un pro précis (avec son claim éventuel)

```sql
SELECT
  pp.*,
  au.email_confirmed_at,
  vc.venue_name,
  vc.siret,
  vc.status AS claim_status
FROM pro_profiles pp
LEFT JOIN auth.users au ON au.id = pp.user_id
LEFT JOIN venue_claims vc ON vc.pro_id = pp.user_id::text
WHERE lower(pp.email) = lower('email@exemple.com');
```

## 🕵️ Audit trail d'un pro

```sql
SELECT
  action,
  table_name,
  record_id,
  old_data,
  new_data,
  created_at
FROM pro_audit_log
WHERE actor_id = (
  SELECT user_id FROM pro_profiles WHERE email = 'email@exemple.com'
)
ORDER BY created_at DESC;
```

## 🗑️ Supprimer un pro

```sql
-- 1. Récupérer user_id
SELECT user_id FROM pro_profiles WHERE email = 'email@exemple.com';

-- 2. Supprimer le profil pro
DELETE FROM pro_profiles WHERE email = 'email@exemple.com';

-- 3. (optionnel) Supprimer aussi le compte auth Supabase
-- via Dashboard → Authentication → Users → clic sur l'user → Delete
```

## 🔐 Pourquoi c'est sûr

- Les 3 fonctions `admin_approve_pro`, `admin_revoke_pro`, `admin_list_pending_pros` sont **scope service_role uniquement** (REVOKE public/anon/authenticated)
- Le trigger `protect_pro_sensitive_fields` empêche tout UPDATE du champ `approved` sauf par service_role
- Chaque passage par ces RPC est tracé dans `pro_audit_log` avec timestamp et rôle
- Test d'étanchéité : un appel anon via PostgREST retourne `HTTP 401 — permission denied for function admin_approve_pro`

## 📜 Contexte RLS en place (P1→P4)

| Protection | Mécanisme |
|---|---|
| RLS `pro_profiles` | `auth.uid()` scoped (SELECT/INSERT/UPDATE own only) |
| Champ `approved` immutable | Trigger `protect_pro_sensitive_fields` |
| Email confirmation | Trigger `require_email_confirmed_for_pro` avant INSERT |
| Validation SIRET/RNA | Edge function `validate-siret` (API gouv) |
| Audit log | `pro_audit_log` + triggers sur pro_profiles / venue_claims / venues |
| Tokens chiffrés | `flutter_secure_storage` (Android Keystore / iOS Keychain) |
| Password fort | Signup : ≥ 10 car + 1 maj + 1 chiffre |

## 🛠️ À configurer côté Dashboard (one-shot)

1. **Auth → Providers → Email** → cocher **"Confirm email"**
2. **Auth → Policies** → `Minimum password length = 10`
