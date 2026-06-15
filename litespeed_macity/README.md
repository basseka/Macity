# Fichiers hébergés sur macity.app (hébergeur LiteSpeed, hors Firebase)

`macity.app` n'est **pas** servi par Firebase Hosting (qui ne sert que
`pulz-app-5c24b.web.app` pour le coffre). Il est servi par un hébergeur
**LiteSpeed** (cPanel). Le contenu y est déposé à la main (FTP/cPanel).
Ce dossier est une **copie de référence versionnée** de ce qui doit y vivre.

## À héberger dans `/.well-known/`

| Fichier | URL publique attendue | Content-Type |
|---|---|---|
| `apple-app-site-association` | `https://macity.app/.well-known/apple-app-site-association` | `application/json` |
| `assetlinks.json` | `https://macity.app/.well-known/assetlinks.json` | `application/json` |
| `.htaccess` | (non public) `public_html/.well-known/.htaccess` | — |

⚠️ `apple-app-site-association` n'a **pas d'extension** → Hostinger/LiteSpeed le sert en
`text/plain` par défaut. Le `.htaccess` (ForceType application/json) corrige ça. Sans lui,
iOS ignore le fichier et les Universal Links ne marchent pas.

### Règles strictes
- **Pas d'extension** sur `apple-app-site-association` (ni `.json`).
- Servi en **HTTPS**, **HTTP 200 direct**, **aucune redirection**.
- `Content-Type: application/json`.
- `assetlinks.json` est **déjà en ligne** (2 empreintes, validé Google) — ce fichier
  n'est qu'une copie de référence. L'AASA, lui, renvoie actuellement **404** → à déposer.

## Valeurs
- Apple Team ID : `BG2AU3T74F`
- Bundle / package : `com.macity.app`
- App Store ID : `6778110272`
- appID Universal Links : `BG2AU3T74F.com.macity.app`
- Chemins pris en charge : `/event/*`

## Vérification après dépôt
```
curl -sS https://macity.app/.well-known/apple-app-site-association
# doit renvoyer le JSON en application/json, HTTP 200, sans redirection
```
La page `/event/{id}` (template LiteSpeed) ne gère aujourd'hui que `intent://`
(Android). À compléter avec un fallback **App Store** pour iOS :
`https://apps.apple.com/app/macity-app/id6778110272`.
