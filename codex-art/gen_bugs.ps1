$ErrorActionPreference = 'Continue'
$out = $PSScriptRoot
$S = 'pixel art for a top-down 16-bit SNES-style action RPG monster, three-quarter view, crisp pixel edges, limited palette, bold dark outline, soft light from the top-left, on a perfectly flat solid magenta (#FF00FF) background with no shadow on the background, no ground plane, no text, no numbers, no border, no grid lines.'
$R = 'in one row with very wide magenta gaps between frames so no frames touch, every frame the same scale and the same design, bottom-aligned on one line.'
$jobs = [ordered]@{
  caterpillar = @("An animation sprite sheet of one fat dusk caterpillar monster seen from the side facing right, $R 8 frames: frames 1 to 4 a crawl cycle (body flat, front half arching up, whole body arched in an inchworm loop, body stretching forward flat again), frame 5 rearing its head up high ready to strike with jaws open, frame 6 lunging forward biting with its jaws snapping, frame 7 spitting a glob of sticky silk from its mouth, frame 8 curled up flinching as if hit. Soft violet and indigo segments with glowing pale yellow spots along its side, little stubby legs, two short antennae, cute but menacing. $S", "$out\props.png")
  pupa        = @("An animation sprite sheet of one moth chrysalis (pupa) monster standing upright on the ground, front view, $R 6 frames: frame 1 still and closed, frame 2 wriggling and leaning left, frame 3 wriggling and leaning right, frame 4 a glowing crack opening down its front with pale light inside, frame 5 split wide open with a wing tip pushing out, frame 6 the empty broken husk. Silky grey-violet shell with darker ridged bands and faint glowing violet veins, held in a tuft of silk at the base. $S", "$out\props.png")
  moth        = @("An animation sprite sheet of one dusk moth monster seen from the side facing right while flying, $R 8 frames: frames 1 to 4 a full wingbeat cycle (wings raised high, wings level, wings swept down, wings level again), frame 5 hovering with wings spread wide and its body glowing as it gathers power, frame 6 lunging forward with wings swept back in a swooping dive, frame 7 beating its wings hard releasing a burst of sparkling glowing dust, frame 8 tumbling as if hit. Fuzzy body, broad soft wings in dusky violet and indigo with large pale moon-white eye spots, feathery antennae, glowing pale yellow eyes. $S", "$out\props.png")
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
