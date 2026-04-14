#!/usr/bin/env bash
# Test du badge_count de l'app MaCity/Pulz.
#
# Usage:
#   ./scripts/test_badge.sh               → envoie 1 notif au device le plus recent
#   ./scripts/test_badge.sh 3             → envoie 3 notifs au device le plus recent
#   ./scripts/test_badge.sh 2 <user_id>   → envoie 2 notifs a ce user precis
#   ./scripts/test_badge.sh reset         → reset badge_count=0 pour le device le plus recent
#   ./scripts/test_badge.sh status        → affiche le badge_count actuel des 5 devices les plus recents
#
# Prerequis:
#   - pulz_app/.env doit contenir SUPABASE_ANON_KEY
#   - macity-admin/.env.local doit contenir SUPABASE_SERVICE_ROLE_KEY
#   (ou exporter SUPABASE_ANON_KEY et SUPABASE_SERVICE_ROLE_KEY dans le shell)

set -euo pipefail

SUPABASE_URL="https://dpqxefmwjfvoysacwgef.supabase.co"

# ─── Chargement des cles ──────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

load_env_var() {
  local var_name="$1"
  local file="$2"
  [ -f "$file" ] || return 1
  local value
  value=$(grep -E "^${var_name}=" "$file" 2>/dev/null | head -1 | cut -d= -f2- || true)
  [ -n "$value" ] && echo "$value"
}

if [ -z "${SUPABASE_ANON_KEY:-}" ]; then
  SUPABASE_ANON_KEY=$(load_env_var SUPABASE_ANON_KEY "$SCRIPT_DIR/../.env" || true)
fi
if [ -z "${SUPABASE_SERVICE_ROLE_KEY:-}" ]; then
  SUPABASE_SERVICE_ROLE_KEY=$(load_env_var SUPABASE_SERVICE_ROLE_KEY "$REPO_ROOT/macity-admin/.env.local" || true)
fi

if [ -z "${SUPABASE_ANON_KEY:-}" ] || [ -z "${SUPABASE_SERVICE_ROLE_KEY:-}" ]; then
  echo "Erreur : SUPABASE_ANON_KEY et SUPABASE_SERVICE_ROLE_KEY requis." >&2
  echo "  Exporte-les dans le shell, ou place-les dans :" >&2
  echo "    pulz_app/.env  (SUPABASE_ANON_KEY)" >&2
  echo "    macity-admin/.env.local  (SUPABASE_SERVICE_ROLE_KEY)" >&2
  exit 1
fi

SR_AUTH=(-H "apikey: $SUPABASE_SERVICE_ROLE_KEY" -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY")
ANON_AUTH=(-H "apikey: $SUPABASE_ANON_KEY" -H "Authorization: Bearer $SUPABASE_ANON_KEY")

# ─── Helpers ──────────────────────────────────────────────────
get_latest_user() {
  curl -sS "${SUPABASE_URL}/rest/v1/user_fcm_tokens?select=user_id,device_id,platform,badge_count&order=updated_at.desc&limit=1" \
    "${SR_AUTH[@]}" | python3 -c 'import sys,json; r=json.load(sys.stdin); print(r[0]["user_id"]) if r else sys.exit(1)'
}

print_status() {
  echo ""
  echo "— devices actifs —"
  curl -sS "${SUPABASE_URL}/rest/v1/user_fcm_tokens?select=user_id,platform,badge_count,updated_at&order=updated_at.desc&limit=5" \
    "${SR_AUTH[@]}" \
    | python3 -c "$(cat <<'PY'
import sys, json
rows = json.load(sys.stdin)
if not rows:
    print("  (aucun device enregistre)")
else:
    for r in rows:
        uid = r["user_id"][:8]
        plat = r["platform"]
        badge = r["badge_count"]
        ts = r["updated_at"][:19]
        print("  [{:<8}] user={}...  badge={}  ({})".format(plat, uid, badge, ts))
PY
)"
  echo ""
}

insert_notification() {
  local user_id="$1"
  local idx="$2"
  local ts
  ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  curl -sS -o /dev/null -w "%{http_code}" -X POST \
    "${SUPABASE_URL}/rest/v1/notification_queue" \
    "${SR_AUTH[@]}" \
    -H "Content-Type: application/json" \
    -H "Prefer: return=minimal" \
    -d "{
      \"user_id\": \"$user_id\",
      \"event_id\": \"test_badge_$(date +%s)_$idx\",
      \"event_title\": \"Test badge #$idx\",
      \"event_date\": \"$(date +%Y-%m-%d)\",
      \"type\": \"new_event\",
      \"establishment_id\": \"test_Toulouse\",
      \"scheduled_for\": \"2020-01-01T00:00:00Z\",
      \"status\": \"pending\"
    }"
}

invoke_send_notifications() {
  echo -n "→ invoke send-notifications ... "
  local resp
  resp=$(curl -sS -X POST "${SUPABASE_URL}/functions/v1/send-notifications" \
    "${ANON_AUTH[@]}" --max-time 30 || echo '{"error":"network"}')
  echo "$resp"
}

reset_badge() {
  local user_id="$1"
  echo -n "→ reset badge_count=0 pour user_id=${user_id:0:8}… ... "
  curl -sS -o /dev/null -w "%{http_code}\n" -X PATCH \
    "${SUPABASE_URL}/rest/v1/user_fcm_tokens?user_id=eq.${user_id}" \
    "${SR_AUTH[@]}" \
    -H "Content-Type: application/json" \
    -H "Prefer: return=minimal" \
    -d '{"badge_count": 0}'
}

# ─── Dispatch ─────────────────────────────────────────────────
CMD="${1:-1}"

case "$CMD" in
  status)
    print_status
    ;;

  reset)
    USER_ID="${2:-$(get_latest_user)}"
    reset_badge "$USER_ID"
    print_status
    ;;

  *)
    # Default: envoyer N notifs
    COUNT="$CMD"
    if ! [[ "$COUNT" =~ ^[0-9]+$ ]]; then
      echo "Usage: $0 [N|reset|status] [user_id]" >&2
      exit 1
    fi
    USER_ID="${2:-$(get_latest_user)}"
    echo "→ cible : user_id=${USER_ID:0:8}…  |  $COUNT notif(s) a envoyer"
    print_status

    for i in $(seq 1 "$COUNT"); do
      echo -n "  [$i/$COUNT] insert pending ... "
      http=$(insert_notification "$USER_ID" "$i")
      echo "$http"
    done

    invoke_send_notifications
    sleep 2
    print_status

    echo "✅ Verifie l'icone MaCity sur le home screen de ton device."
    echo "   Ouvre l'app → le badge doit repasser a 0 (./scripts/test_badge.sh status pour verifier)."
    ;;
esac
