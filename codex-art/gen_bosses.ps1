$ErrorActionPreference = 'Continue'
$out = $PSScriptRoot
$S = 'pixel art for a top-down 16-bit SNES-style action RPG boss, three-quarter view facing the viewer, crisp pixel edges, limited palette, bold dark outline, soft light from the top-left, centered, filling most of the frame, on a perfectly flat solid magenta (#FF00FF) background with no shadow on the background, no ground plane, no text, no border, no grid lines.'
$jobs = [ordered]@{
  boss_gnawbelly = "A giant angry mole boss named Gnawbelly the Mole Tyrant: a round dark brown furry body, huge pink digging claws tipped with iron, a cracked old miner's helmet with a dim lamp, tiny squinting red eyes, big buck teeth, standing upright. $S"
  boss_mycelia   = "A giant pulsing mushroom boss named Mycelia the Rotcap Heart: a huge sickly purple and green spotted cap with glowing gills underneath, a thick pale stalk with a grim face of folds and glowing yellow eyes, writhing mycelium tendrils spreading from its base. $S"
  boss_snapjaw   = "A giant ancient snapping turtle boss named Old Snapjaw: a massive mossy green-brown spiked shell with barnacles, a hooked beak like a bear trap, scaly thick legs, small fierce orange eyes, water dripping. $S"
  boss_harvest   = "A living scarecrow boss named The Hollow Harvest: a glowing carved jack-o-lantern pumpkin head with fire in its eyes, a tattered patchwork coat stuffed with straw, a long rusty scythe held in both hands, black crows perched on its shoulders, floating slightly. $S"
  boss_vespa     = "A giant hornet queen boss named Queen Vespa, seen from slightly above while flying: glassy veined wings spread wide, a golden and black striped body, a crown-like golden carapace on her head, large red compound eyes, a long sharp stinger. $S"
  boss_grimfang  = "A huge black direwolf boss named Grimfang the Briar Stalker: shaggy black fur with thorny bramble vines growing through it, glowing yellow eyes, bared white fangs, crouched ready to pounce, side three-quarter view. $S"
  boss_nyxwing   = "A giant moth boss named Nyxwing the Dusk Moth: enormous wings spread wide with glowing eye-pattern markings in violet and sunset orange, a fluffy pale body, feathery antennae, shimmering scales, seen from the front while hovering. $S"
  boss_oakheart  = "A giant walking oak tree boss named Oakheart the Forest Guardian: a thick gnarled trunk with an ancient wise angry face carved in the bark, glowing green eyes, massive branch arms, a mossy stone crown grown into its leafy canopy, root legs, lush green leaves. $S"
  boss_props     = "A sprite sheet of four separate boss arena props in one neat row with wide magenta gaps between them: 1) a lit jack-o-lantern on a short wooden post, 2) a gnarled glowing green tree root knot sticking out of the ground, 3) a giant brown acorn, 4) a mound of freshly dug brown dirt. $S"
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
