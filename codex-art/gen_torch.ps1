$ErrorActionPreference = 'Continue'
$out = $PSScriptRoot
$S = 'pixel art for a top-down 16-bit SNES-style action RPG, three-quarter view, crisp pixel edges, limited palette, bold dark outline, on a perfectly flat solid magenta (#FF00FF) background with no shadow on the background, no ground plane, no text, no numbers, no border, no grid lines.'
$jobs = [ordered]@{
  flames    = @("An animation sprite sheet of one small torch flame in one row of 6 frames with very wide magenta gaps so no frames touch, all frames the same scale and bottom-aligned, a flickering loop: frame 1 tall and straight, frame 2 leaning a little left with a lick of fire splitting off, frame 3 short and wide, frame 4 leaning a little right, frame 5 tall with two tongues of flame, frame 6 settling. A bright pale-yellow core, an orange body and deep red-orange tips, glowing. Only the flame, no torch, no stick. $S", "$out\props.png")
  torchpost = @("Two sprites in one row with very wide magenta gaps: 1) a standing wooden torch post: a tall rough wooden stake planted in the ground with a few stones round its base, its top wrapped in dark cloth soaked in pitch inside a small iron cup, unlit, the cloth charred black, no fire, no smoke; 2) the same post, identical, unlit. Same style and scale as the reference props, taller than wide. $S", "$out\props.png")
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
