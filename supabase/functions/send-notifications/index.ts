// supabase functions deploy send-notifications --no-verify-jwt
//
// Secrets requis (Supabase Dashboard > Edge Functions > Secrets):
//   SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, FCM_SERVER_KEY

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const FCM_SERVER_KEY = Deno.env.get("FCM_SERVER_KEY")!;
const BATCH_SIZE = 500;

const headers = {
  apikey: SERVICE_ROLE_KEY,
  Authorization: `Bearer ${SERVICE_ROLE_KEY}`,
  "Content-Type": "application/json",
};

interface QueueRow {
  id: number;
  user_id: string;
  event_id: number;
  type: string;
  batch_key: string;
  event_title: string;
  event_starts_at: string;
  establishment_id: string;
}

Deno.serve(async (_req) => {
  try {
    // 1. Claim les notifications dues (via fonction SQL avec lock)
    const claimRes = await fetch(
      `${SUPABASE_URL}/rest/v1/rpc/claim_pending_notifications`,
      {
        method: "POST",
        headers,
        body: JSON.stringify({ batch_size: BATCH_SIZE }),
      },
    );

    if (!claimRes.ok) {
      const err = await claimRes.text();
      throw new Error(`claim failed: ${err}`);
    }

    const pending: QueueRow[] = await claimRes.json();
    if (!pending.length) {
      return json({ sent: 0, failed: 0 });
    }

    // 2. Grouper par user_id
    const byUser = new Map<string, QueueRow[]>();
    for (const row of pending) {
      const list = byUser.get(row.user_id) ?? [];
      list.push(row);
      byUser.set(row.user_id, list);
    }

    const sentIds: number[] = [];
    const failedIds: number[] = [];

    // 3. Pour chaque user, recuperer ses tokens et envoyer
    for (const [userId, notifications] of byUser) {
      // Recuperer les tokens FCM
      const tokensRes = await fetch(
        `${SUPABASE_URL}/rest/v1/user_fcm_tokens?user_id=eq.${userId}&select=token`,
        { headers },
      );
      const tokens: { token: string }[] = tokensRes.ok
        ? await tokensRes.json()
        : [];

      if (!tokens.length) {
        for (const n of notifications) failedIds.push(n.id);
        continue;
      }

      // Grouper par batch_key pour eviter le spam
      const byBatch = new Map<string, QueueRow[]>();
      for (const n of notifications) {
        const key = n.batch_key ?? `${n.event_id}`;
        const list = byBatch.get(key) ?? [];
        list.push(n);
        byBatch.set(key, list);
      }

      for (const [_, group] of byBatch) {
        const title =
          group.length === 1
            ? `Rappel : ${group[0].event_title}`
            : `${group.length} evenements a venir`;

        const body =
          group.length === 1
            ? formatBody(group[0])
            : group.map((g) => g.event_title).join(", ");

        // Envoyer a chaque device du user
        for (const { token } of tokens) {
          try {
            const fcmRes = await fetch(
              "https://fcm.googleapis.com/fcm/send",
              {
                method: "POST",
                headers: {
                  Authorization: `key=${FCM_SERVER_KEY}`,
                  "Content-Type": "application/json",
                },
                body: JSON.stringify({
                  to: token,
                  notification: { title, body },
                  data: {
                    type: "event_reminder",
                    event_ids: group.map((g) => g.event_id).join(","),
                    click_action: "FLUTTER_NOTIFICATION_CLICK",
                  },
                }),
              },
            );

            if (!fcmRes.ok) {
              const errText = await fcmRes.text();
              // Token invalide → supprimer
              if (errText.includes("NotRegistered") || errText.includes("InvalidRegistration")) {
                await fetch(
                  `${SUPABASE_URL}/rest/v1/user_fcm_tokens?token=eq.${encodeURIComponent(token)}`,
                  { method: "DELETE", headers },
                );
              }
            }
          } catch {
            // Erreur reseau FCM, on continue avec le token suivant
          }
        }

        for (const n of group) sentIds.push(n.id);
      }
    }

    // 4. Mettre a jour les statuts dans la queue
    if (sentIds.length) {
      await fetch(`${SUPABASE_URL}/rest/v1/notification_queue`, {
        method: "PATCH",
        headers: { ...headers, Prefer: "return=minimal" },
        body: JSON.stringify({
          status: "sent",
          sent_at: new Date().toISOString(),
        }),
        // PostgREST: filter par ids
        // On doit passer par query params
      });
      // Utiliser RPC ou boucle pour les updates batch
      for (const id of sentIds) {
        await fetch(
          `${SUPABASE_URL}/rest/v1/notification_queue?id=eq.${id}`,
          {
            method: "PATCH",
            headers: { ...headers, Prefer: "return=minimal" },
            body: JSON.stringify({
              status: "sent",
              sent_at: new Date().toISOString(),
            }),
          },
        );
      }
    }

    if (failedIds.length) {
      for (const id of failedIds) {
        await fetch(
          `${SUPABASE_URL}/rest/v1/notification_queue?id=eq.${id}`,
          {
            method: "PATCH",
            headers: { ...headers, Prefer: "return=minimal" },
            body: JSON.stringify({ status: "failed" }),
          },
        );
      }
    }

    return json({ sent: sentIds.length, failed: failedIds.length });
  } catch (err) {
    return json({ error: String(err) }, 500);
  }
});

function formatBody(n: QueueRow): string {
  const date = new Date(n.event_starts_at);
  const formatted = date.toLocaleDateString("fr-FR", {
    weekday: "long",
    day: "numeric",
    month: "long",
    hour: "2-digit",
    minute: "2-digit",
  });
  switch (n.type) {
    case "2_days":
      return `Dans 2 jours — ${formatted}`;
    case "1_day":
      return `Demain — ${formatted}`;
    case "1_hour":
      return `Dans 1 heure !`;
    default:
      return formatted;
  }
}

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
