  <?php
  $id = isset($_GET['id']) ? $_GET['id'] : '';
  if (!$id) { header('Location: /'); exit; }
  $encodedId = urlencode($id);
  $supabaseUrl = "https://dpqxefmwjfvoysacwgef.supabase.co";
  $apiKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRwcXhlZm13amZ2b3lzYWN3Z2VmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAyOTkxMTgsImV4cCI6MjA4NTg3NTExOH0.xzNidmrcNsUhpsTFcaaL_lXtHcx_MWzQHCPF7kY5i90";

  $title = "Evenement sur MaCity";
  $desc = "";
  $photo = "";
  $ch = curl_init("$supabaseUrl/rest/v1/scraped_events?identifiant=eq.$encodedId&select=nom_de_la_manifestation,date_debut,lieu_nom,photo_url&limit=1");
  curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
  curl_setopt($ch, CURLOPT_HTTPHEADER, ["apikey: $apiKey", "Authorization: Bearer $apiKey"]);
  $res = curl_exec($ch);
  curl_close($ch);
  if ($res) {
      $data = json_decode($res, true);
      if (!empty($data[0])) {
          $title = $data[0]['nom_de_la_manifestation'] ?? $title;
          $desc = implode(' - ', array_filter([$data[0]['date_debut'] ?? '', $data[0]['lieu_nom'] ?? '']));
          $photo = $data[0]['photo_url'] ?? '';
      }
  }
  $intentUri = "intent://event/$encodedId#Intent;scheme=pulzapp;package=com.macity.app;S.browser_fallback_url=" . urlencode('https://play.google.com/store/apps/details?id=com.macity.app') . ";end";
  ?>
  <!DOCTYPE html>
  <html lang="fr">
  <head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title><?= htmlspecialchars($title) ?> - MaCity</title>
  <meta property="og:title" content="<?= htmlspecialchars($title) ?>">
  <meta property="og:description" content="<?= htmlspecialchars($desc) ?>">
  <?php if ($photo): ?><meta property="og:image" content="<?= htmlspecialchars($photo) ?>"><?php endif; ?>
  <style>*{margin:0;padding:0;box-sizing:border-box}body{font-family:-apple-system,sans-serif;background:#1A0A2E;color:#fff;min-height:100vh;display:flex;flex-direction:column;align-items:center;justify-content:center;padding:2
  4px}.card{background:rgba(255,255,255,.08);border-radius:20px;padding:24px;max-width:360px;width:100%;text-align:center}.photo{width:100%;border-radius:12px;margin-bottom:16px}h1{font-size:20px;margin-bottom:8px}.info{color:r
  gba(255,255,255,.6);font-size:14px;margin-bottom:20px}.btn{display:block;width:100%;padding:14px;border-radius:14px;background:#E91E8C;color:#fff;text-decoration:none;font-weight:700;font-size:16px;margin-bottom:10px}.btn-sec
  {background:rgba(255,255,255,.1)}.logo{font-size:24px;font-weight:800;margin-bottom:24px;color:#E91E8C}</style>
  </head>
  <body>
  <div class="logo">MaCity</div>
  <div class="card">
  <?php if ($photo): ?><img class="photo" src="<?= htmlspecialchars($photo) ?>" alt=""><?php endif; ?>
  <h1><?= htmlspecialchars($title) ?></h1>                                                                                                                                                                                         
  <div class="info"><?= htmlspecialchars($desc) ?></div>
  <a class="btn" href="<?= $intentUri ?>">Ouvrir dans MaCity</a>                                                                                                                                                                   
  <a class="btn btn-sec" href="https://play.google.com/store/apps/details?id=com.macity.app">Telecharger l'app</a>                                                                                                                 
  </div>                                                                                                                                                                                                                           
  <script>                                                                                                                                                                                                                         
  setTimeout(function(){window.location.href="<?= $intentUri ?>";},300);                                                                                                                                                           
  </script>       
  </body>
  </html>    
