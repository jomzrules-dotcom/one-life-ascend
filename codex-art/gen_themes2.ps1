$ErrorActionPreference = 'Continue'
$out = $PSScriptRoot
$S = 'pixel art for a top-down 16-bit SNES-style action RPG, three-quarter view, crisp pixel edges, limited palette, soft light from the top-left, on a perfectly flat solid magenta (#FF00FF) background with no shadow on the background, no ground plane, no text, no border, no grid lines.'
$T = 'for a 16-bit SNES-style pixel art RPG, flat even lighting, crisp pixel edges, filling the whole image edge to edge, no border, no text. Match the pixel scale, outline style and painting style of the reference grass texture.'
$props = "$out\props.png"; $grass = "$out\ground_grass.png"
$jobs = [ordered]@{
  burrow_props   = @("A sprite sheet in a neat grid of 4 columns and 2 rows with wide magenta gaps between every item. Row 1: two different rat burrows (a low mound of loose brown earth around a dark round hole, scattered dirt clods and a few grass tufts), a caved-in collapsed burrow (the mound flattened, the hole filled with rubble), a small pile of fresh dirt. Row 2: a big hollow fallen log lying left to right with a dark opening at one end, moss and fungus on top (as wide as two items), a pile of gnawed bones, a half-eaten turnip and carrot tops. Same style and scale as the reference props. $S", $props)
  ground_burrow  = @("A seamless tileable square texture of top-down trampled meadow ground: short grass worn down to patches of bare brown earth, scattered dirt clods, tiny pebbles, a few small dug holes, natural greens and browns $T", $grass)
  shroom_props   = @("A sprite sheet in a neat grid of 4 columns and 2 rows with wide magenta gaps between every item. Row 1: four different giant mushrooms as tall as small trees, each on a thick pale stalk: a red cap with white spots, a broad flat brown cap, a violet cap with softly glowing spots, a clump of three tall tan mushrooms. Row 2: a small cluster of glowing blue mushrooms, a single small white mushroom for a fairy ring, a mossy tree stump with orange shelf fungus, a cluster of round spore puffballs. Same style as the reference props. $S", $props)
  ground_moss    = @("A seamless tileable square texture of top-down shady forest floor: soft deep green moss with patches of dark soil, fallen brown leaves, tiny pebbles and a few very small mushrooms, slightly cooler and darker greens than the reference grass $T", $grass)
  bramble_props  = @("A sprite sheet in a neat grid of 4 columns and 2 rows with wide magenta gaps between every item. Row 1: four different round bramble bushes, dense dark green leaves tangled with long thorny reddish-brown vines and a few dark purple blackberries, the same size and shape as the reference bushes. Row 2: two low tangles of thorny vines lying on the ground, a broken mossy stone pillar, a toppled stone block with ivy. $S", $props)
  tower          = @("A single ruined round stone watchtower seen from a top-down three-quarter view: only the base remains, a broken ring of mossy grey stone walls about waist high with a wide gap for a doorway at the bottom, a cracked flagstone floor inside with grass growing between the stones, one taller broken section of wall at the back, fallen stones and ivy around it. Wider than tall. $S", $props)
  tex_thorn      = @("A seamless tileable square texture of top-down dense bramble thicket on dark soil: a tangle of thin thorny reddish-brown and dark green vines with sharp pale thorns, small dark leaves and a few purple berries, dark and dense $T", $grass)
  stones         = @("A sprite sheet in one row of five items with very wide magenta gaps: three different tall standing stones (ancient grey menhirs, taller than wide, with moss at the base and faint carved spiral runes), a flat low stone altar slab with a carved circle on top, a small cairn of stacked stones. Same stone style as the reference boulders. $S", $props)
  root_props     = @("A sprite sheet in a neat grid of 4 columns and 2 rows with wide magenta gaps between every item. Row 1: four different clumps of giant gnarled tree roots, thick twisting brown roots knotted together with green moss and a few small leaves, the same size and shape as the reference bushes. Row 2: a cluster of glowing yellow-green spore pods on short stalks, a low arch of roots, a young sapling with heart-shaped leaves, a low tangle of roots lying on the ground. $S", $props)
  ground_heart   = @("A seamless tileable square texture of top-down ancient overgrown grove floor: deep green moss with thin brown roots snaking across it, fallen leaves, small ferns and a few tiny softly glowing yellow-green spores $T", $grass)
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
