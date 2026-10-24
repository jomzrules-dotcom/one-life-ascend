$ErrorActionPreference = 'Continue'
$out = $PSScriptRoot
$S = 'pixel art for a top-down 16-bit SNES-style action RPG, three-quarter view, crisp pixel edges, limited palette, soft light from the top-left, on a perfectly flat solid magenta (#FF00FF) background with no shadow on the background, no ground plane, no text, no border, no grid lines.'
$jobs = [ordered]@{
  wheat_props = @("A sprite sheet in a neat grid of 4 columns and 2 rows with wide magenta gaps between every item. Row 1: four different dense round clumps of tall ripe golden wheat, many stalks with heavy drooping ears, warm gold and straw colours with a few green-gold stems at the base, the same size and shape as the reference bushes. Row 2: a dense clump of golden wheat with a few red poppies and blue cornflowers in it, a small round apple tree with red apples, a tall clump of green corn stalks with yellow cobs, a cluster of tall sunflowers. Same style and scale as the reference props. $S", "$out\props.png")
}
$gen = "$env:USERPROFILE\.codex\generated_images"
$running = @()
foreach ($name in $jobs.Keys) {
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
