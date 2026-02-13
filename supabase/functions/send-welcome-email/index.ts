// supabase functions deploy send-welcome-email --no-verify-jwt
//
// Secrets requis (supabase secrets set):
//   BREVO_API_KEY

const BREVO_API_KEY = Deno.env.get("BREVO_API_KEY")!;

const WELCOME_SUBJECT =
  "Bienvenue sur Macity ! Créez vos événements dès maintenant 🎉";

function buildHtmlContent(): string {
  return `
<!DOCTYPE html>
<html lang="fr">
<head><meta charset="UTF-8"></head>
<body style="font-family: Arial, sans-serif; color: #333; line-height: 1.7; max-width: 600px; margin: 0 auto; padding: 20px;">

  <h2 style="color: #7B2D8E;">Bienvenue sur Macity !</h2>

  <p>Bonjour,</p>

  <p>Merci pour votre inscription sur <strong>Macity</strong> !</p>

  <p>Grâce à votre compte Macity, vous pouvez désormais créer et publier vos événements en quelques clics en précisant :</p>

  <ul style="list-style: none; padding-left: 0;">
    <li>📌 Le type d'événement</li>
    <li>📍 Le lieu</li>
    <li>📅 La date</li>
    <li>⏰ L'heure</li>
  </ul>

  <p>Avec Macity, dès qu'un événement est publié, toutes les personnes intéressées par ce type d'événement recevront automatiquement une notification.</p>

  <p>Cela permet à Macity de :</p>

  <ul style="list-style: none; padding-left: 0;">
    <li>🚀 Accélérer la diffusion de votre information</li>
    <li>📣 Toucher directement un public ciblé</li>
    <li>🤝 Faciliter l'organisation et la participation</li>
    <li>⏳ Simplifier et dynamiser la communication de vos événements</li>
  </ul>

  <p>L'objectif de Macity est simple : vous aider à promouvoir vos événements plus efficacement et à connecter rapidement les bonnes personnes au bon moment.</p>

  <p>Vous pouvez dès maintenant créer votre premier événement sur Macity depuis votre espace personnel.</p>

  <p>Nous vous souhaitons beaucoup de succès avec Macity !</p>

  <p>À très bientôt,<br><strong>L'équipe Macity</strong></p>

</body>
</html>`;
}

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

Deno.serve(async (req) => {
  try {
    const { email } = await req.json();

    if (!email) {
      return json({ error: "email is required" }, 400);
    }

    // Envoi via Brevo (ex-Sendinblue) Transactional Email API
    const brevoRes = await fetch("https://api.brevo.com/v3/smtp/email", {
      method: "POST",
      headers: {
        "api-key": BREVO_API_KEY,
        "Content-Type": "application/json",
        Accept: "application/json",
      },
      body: JSON.stringify({
        sender: { name: "Macity", email: "noreply@macity.fr" },
        to: [{ email }],
        subject: WELCOME_SUBJECT,
        htmlContent: buildHtmlContent(),
      }),
    });

    if (!brevoRes.ok) {
      const err = await brevoRes.text();
      console.error(`Brevo error: ${err}`);
      return json({ error: "email_send_failed", details: err }, 502);
    }

    const result = await brevoRes.json();
    console.log(`Welcome email sent to ${email}`, result);
    return json({ success: true, messageId: result.messageId });
  } catch (err) {
    console.error("send-welcome-email error:", err);
    return json({ error: String(err) }, 500);
  }
});
