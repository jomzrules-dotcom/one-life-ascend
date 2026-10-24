$ErrorActionPreference = 'Continue'
$out = $PSScriptRoot
$S = 'pixel art for a top-down 16-bit SNES-style action RPG, three-quarter view, crisp pixel edges, limited palette, bold dark outline, soft light from the top-left, on a perfectly flat solid magenta (#FF00FF) background with no shadow on the background, no ground plane, no text, no numbers, no border, no grid lines.'
$jobs = [ordered]@{
  chests = "A sprite sheet of eight treasure chests in a neat grid of 4 columns and 2 rows, with very wide magenta gaps between every chest so none touch, all chests the same size and facing the viewer. Row 1, all closed: 1) a plain wooden chest with dark iron bands, 2) a sturdy iron-plated silver chest with blue steel trim and rivets, 3) an ornate golden chest with gems and a red jewel lock, 4) an ancient mythic chest of dark purple crystal and silver with glowing violet runes. Row 2: the same four chests in the same order with their lids open and treasure glowing inside (coins, a gem, light spilling out), the lid tilted back. $S"
}
$gen = "$env:USERPROFILE\.codex\generated_images"
$running = @()
foreach ($name in $jobs.Keys) {
  $p = 'Generate exactly one image with your image generation tool, then stop. Do not write code or files. Image: ' + $jobs[$name]
  $running += Start-Job -Name $name -ArgumentList $p, "$out\$name.log" -ScriptBlock { param($p, $log) codex exec --skip-git-repo-check $p *> $log }
}
$running | Wait-Job | Out-Null
$dirs = Get-ChildItem $gen -Directory
foreach ($name in $jobs.Keys) {
  $log = Get-Content "$out\$name.log" -Raw
  $d = $dirs | Where-Object { $log -match [regex]::Escape($_.Name) } | Select-Object -First 1
  if ($d) { $f = Get-ChildItem $d.FullName -File -Filter *.png | Sort-Object LastWriteTime -Descending | Select-Object -First 1; Copy-Item $f.FullName "$out\$name.png" -Force; "$name -> ok" }
  else { "$name -> no image found" }
}
