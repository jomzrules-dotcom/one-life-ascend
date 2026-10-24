$ErrorActionPreference = 'Continue'
$out = $PSScriptRoot
$S = 'pixel art for a top-down 16-bit SNES-style action RPG, three-quarter view, crisp pixel edges, limited palette, soft light from the top-left, on a perfectly flat solid magenta (#FF00FF) background with no shadow on the background, no ground plane, no text, no border, no grid lines.'
$T = 'for a 16-bit SNES-style pixel art RPG, flat even lighting, crisp pixel edges, filling the whole image edge to edge, no border, no text. Match the pixel scale, outline style and painting style of the reference grass texture.'
$props = "$out\props.png"; $grass = "$out\ground_grass.png"
$jobs = [ordered]@{
  bridge_stone_h = @("A single old stone bridge seen from a top-down three-quarter view, running from left to right, about two and a half times wider than tall. A flat grey cobbled walking deck, low stone parapet walls along its top and bottom edges, a square stone post at each of the four corners, and below the deck the near side face of the bridge with two round arches. Weathered grey stone with a little moss, matching the stone of the reference boulders. Only the bridge: no water, no river banks, no ground. $S", $props)
  bridge_stone_v = @("A single old stone bridge seen from a top-down three-quarter view, running from the top of the image to the bottom, about two and a half times taller than wide. A flat grey cobbled walking deck seen from above, low stone parapet walls along its left and right edges, a square stone post at each of the four corners, and at the bottom end a short glimpse of the stone front face. Weathered grey stone with a little moss, matching the stone of the reference boulders. Only the bridge: no water, no river banks, no ground. $S", $props)
  bridge_wood_h  = @("A single rustic wooden footbridge seen from a top-down three-quarter view, running from left to right, about two times wider than tall. Brown wooden planks laid across the bridge, simple wooden rails along its top and bottom edges held by round posts, and thick log supports visible on the near side below the deck. Only the bridge: no water, no river banks, no ground. $S", $props)
  bridge_wood_v  = @("A single rustic wooden footbridge seen from a top-down three-quarter view, running from the top of the image to the bottom, about two times taller than wide. Brown wooden planks laid across it from left to right, simple wooden rails along its left and right edges held by round posts. Only the bridge: no water, no river banks, no ground. $S", $props)
  wheat          = @("A seamless tileable square texture of a top-down ripe wheat field: dense golden wheat stalks with heavy ears, planted in neat horizontal rows with thin darker furrows between them, warm gold, straw and ochre tones with a few green-gold stems $T", $grass)
  farm_props     = @("A sprite sheet of farm props in a neat grid of 4 columns and 2 rows with wide magenta gaps between every item. Row 1: a horizontal section of a rustic wooden split-rail fence running left to right (two posts with two horizontal rails between them), a vertical section of the same fence running away from the viewer (two posts one above the other, the rails seen from above as two parallel lines between them), a single wooden fence post, an open wooden farm gate. Row 2: a round golden hay bale, a stack of square hay bales, a scarecrow with a straw hat and patched clothes on a wooden pole, a small wooden hand cart full of wheat sheaves. $S", $props)
  flower_giants  = @("A sprite sheet of three giant wildflower plants in one row with very wide magenta gaps, each as tall as a small tree and drawn in the same style and the same leaf greens as the reference bushes, in soft natural colours that blend into a green meadow: 1) a tall clump of foxglove-like spires of dusty pink bell flowers with broad leaves at the base, 2) a big mound of leafy stems topped with many white and pale yellow daisies, 3) tall stems of soft lilac lupin flowers rising from a clump of broad leaves. $S", $props)
  meadow         = @("A seamless tileable square texture of top-down tall lush meadow grass: dense long grass blades in the same greens as the reference grass texture, slightly taller and fuller, with a light sprinkle of tiny soft wildflowers (white, pale yellow, dusty pink) $T", $grass)
  ground_dry     = @("A seamless tileable square texture of top-down barren dried-up ground: pale cracked dry earth with a network of fine cracks, patches of dead straw-coloured grass, small pebbles and dry twigs, dusty desaturated brown, beige and grey-olive tones, nothing green or alive $T", $grass)
  dead_props     = @("A sprite sheet in a neat grid of 4 columns and 3 rows with wide magenta gaps between every item. Row 1: four different round clumps of dead leafless shrubs with dry twisted grey-brown branches and a few withered brown leaves, the same size and shape as the reference bushes but dead and dried up. Row 2: two small dead leafless trees with gnarled bare branches, a broken hollow dead tree stump, a dry cracked pale boulder. Row 3: a dead straw-coloured grass tuft, a withered thorny weed, a sun-bleached animal skull, a small pile of dry twigs. $S", $props)
}
$gen = "$env:USERPROFILE\.codex\generated_images"
$running = @()
foreach ($name in $jobs.Keys) {
  while (($running | Where-Object { $_.State -eq 'Running' }).Count -ge 5) { Start-Sleep -Seconds 3 }
  $p = 'Generate exactly one image with your image generation tool, then stop. Do not write code or files. Use the attached image only as a style reference. Image: ' + $jobs[$name][0]
  $running += Start-Job -Name $name -ArgumentList $p, "$out\$name.log", $jobs[$name][1] -ScriptBlock { param($p, $log, $ref) codex exec --skip-git-repo-check $p --image $ref *> $log }
}
$running | Wait-Job | Out-Null
$dirs = Get-ChildItem $gen -Directory
foreach ($name in $jobs.Keys) {
  $log = Get-Content "$out\$name.log" -Raw
  $d = $dirs | Where-Object { $log -match [regex]::Escape($_.Name) } | Select-Object -First 1
  if ($d) { $f = Get-ChildItem $d.FullName -File -Filter *.png | Sort-Object LastWriteTime -Descending | Select-Object -First 1; Copy-Item $f.FullName "$out\$name.png" -Force; "$name -> ok" }
  else { "$name -> no image found" }
}
