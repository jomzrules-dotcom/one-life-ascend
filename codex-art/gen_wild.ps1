$ErrorActionPreference = 'Continue'
$out = $PSScriptRoot
$S = 'pixel art for a top-down 16-bit SNES-style action RPG, three-quarter view, crisp pixel edges, limited palette, bold dark outline, soft light from the top-left, on a perfectly flat solid magenta (#FF00FF) background with no shadow on the background, no ground plane, no text, no numbers, no border, no grid lines.'
$jobs = [ordered]@{
  crow   = @("An animation sprite sheet of one small black crow seen from the side facing right, in one row of 5 frames with very wide magenta gaps so no frames touch, all frames the same scale: frame 1 standing upright looking around, frame 2 pecking the ground with its head down, frame 3 crouched with wings half open about to take off, frame 4 flying with both wings raised high, frame 5 flying with both wings swept down. Glossy black feathers with a blue sheen, a dark grey beak, a bright eye. Same style as the reference props. $S", "$out\props.png")
  rabbit = @("An animation sprite sheet of one small brown wild rabbit seen from the side facing right, in one row of 4 frames with very wide magenta gaps so no frames touch, all frames the same scale: frame 1 sitting upright with ears up, frame 2 nibbling grass with its head down and ears back, frame 3 mid-hop stretched out in the air, frame 4 landing crouched with its back legs tucked. Soft brown fur, a white cotton tail, a cream belly. Same style as the reference props. $S", "$out\props.png")
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
