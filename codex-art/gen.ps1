$ErrorActionPreference = 'Continue'
$out = $PSScriptRoot
$S = 'pixel art for a top-down 16-bit SNES-style action RPG, three-quarter view, crisp pixel edges, limited palette, soft light from the top-left, on a perfectly flat solid magenta (#FF00FF) background with no shadow on the background, no ground plane, no text, no border, no grid lines.'
$jobs = [ordered]@{
  ground_grass = 'A seamless tileable square texture of top-down grassy meadow ground for a 16-bit SNES-style pixel art RPG: short grass in varied green tones, a few tiny flowers and pebbles, flat even lighting, no large objects, crisp pixel edges, filling the whole image edge to edge, no border, no text.'
  ground_stone = 'A seamless tileable square texture of a top-down dungeon floor of grey flagstones with dark mortar, small cracks and a little moss, for a 16-bit SNES-style pixel art RPG, flat even lighting, crisp pixel edges, filling the whole image edge to edge, no border, no text.'
  props = "A sprite sheet of nature props arranged in a neat 4 by 3 grid with wide magenta gaps between every item: row 1 four different round leafy green bushes, row 2 four mossy grey boulders of different shapes, row 3 a small flower patch, a red mushroom cluster, a tall grass tuft and a short fallen mossy log. $S"
  gate = "A dungeon entrance: a stone archway with a skull keystone, two burning torches on the pillars, and a pitch-dark doorway with two glowing red eyes inside, front view, slightly wider than tall. $S"
  door_frame = "An empty stone door frame for the exit of a boss arena: thick carved stone pillars and a heavy lintel with a red rune keystone, the opening is pitch black, front view, wider than tall. $S"
  door_leaves = "A pair of closed heavy wooden double doors with black iron bands and rivets and a glowing red rune seal across the middle seam, front view, no stone frame, the doors fill most of the image. $S"
  merchant = "A friendly hooded traveling merchant with a long white beard, a purple robe, a huge overstuffed backpack, holding a glowing lantern, chibi proportions, standing, facing the viewer, full body. $S"
  icons = "A sprite sheet of RPG item icons in a neat grid of 5 columns and 4 rows with wide magenta gaps between every icon. Each row is one item in five quality tiers from left to right: broken (dull grey, cracked), normal (plain), rare (blue accents), epic (purple accents, faint glow), legendary (gold accents, radiant). Row 1: a simple wooden stick weapon, drawn diagonally. Row 2: a leather vest. Row 3: a copper ring. Row 4: a bone charm on a cord. $S"
  slime_king = "A pixel art sprite of a giant teal slime king boss wearing a small golden crown, glossy jelly body with a bright highlight, angry glowing eyes, a few bubbles inside, centered, filling most of the frame. $S"
}
$gen = "$env:USERPROFILE\.codex\generated_images"
$running = @()
foreach ($name in $jobs.Keys) {
  while (($running | Where-Object { $_.State -eq 'Running' }).Count -ge 3) { Start-Sleep -Seconds 3 }
  $p = 'Generate exactly one image with your image generation tool, then stop. Do not write code or files. Image: ' + $jobs[$name]
  $running += Start-Job -Name $name -ArgumentList $p, "$out\$name.log" -ScriptBlock { param($p, $log) codex exec --skip-git-repo-check $p *> $log }
}
$running | Wait-Job | Out-Null
# match each log to its image folder by the session id the log mentions
$dirs = Get-ChildItem $gen -Directory
foreach ($name in $jobs.Keys) {
  $log = Get-Content "$out\$name.log" -Raw
  $d = $dirs | Where-Object { $log -match [regex]::Escape($_.Name) } | Select-Object -First 1
  if ($d) { $f = Get-ChildItem $d.FullName -File -Filter *.png | Sort-Object LastWriteTime -Descending | Select-Object -First 1; Copy-Item $f.FullName "$out\$name.png" -Force; "$name -> ok" }
  else { "$name -> no image found" }
}
