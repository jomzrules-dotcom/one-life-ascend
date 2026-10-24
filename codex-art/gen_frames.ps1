$ErrorActionPreference = 'Continue'
$out = $PSScriptRoot
# Each boss's existing painting is attached as the reference; Codex draws a 4-frame sheet of the same character.
$S = 'Keep it exactly the same character as the attached reference image: same design, same colours, same proportions, same pixel art style, same size in every frame, three-quarter view facing the viewer. Draw exactly four frames side by side in one horizontal row, evenly spaced, with very wide gaps of empty background between them so no frames touch or overlap. Perfectly flat solid magenta (#FF00FF) background, no shadows on the background, no ground, no text, no numbers, no borders, no grid lines.'
$jobs = [ordered]@{
  gnawbelly = "Animation sprite sheet for this giant mole boss. Frame 1: walking, left foot forward. Frame 2: walking, right foot forward, body bobbed slightly. Frame 3: attack wind-up, both iron claws raised high above its head. Frame 4: attack strike, claws slammed down in front of it, dirt flying. $S"
  mycelia   = "Animation sprite sheet for this giant mushroom boss (it stays rooted in place). Frame 1: idle, cap raised, tendrils relaxed. Frame 2: idle, cap squashed lower, tendrils curled. Frame 3: attack wind-up, cap puffed up wide, gills glowing brightly, tendrils drawn in. Frame 4: attack, cap thrown open with a burst of glowing spores spraying out, tendrils lashing. $S"
  snapjaw   = "Animation sprite sheet for this giant snapping turtle boss. Frame 1: crawling, front left leg forward. Frame 2: crawling, front right leg forward. Frame 3: attack wind-up, head pulled back into the shell with the beak wide open. Frame 4: attack strike, neck shot far forward in a snapping bite. $S"
  harvest   = "Animation sprite sheet for this scarecrow boss. Frame 1: floating, coat swaying left. Frame 2: floating, coat swaying right, slightly higher. Frame 3: attack wind-up, the scythe raised high overhead with both hands, pumpkin eyes blazing. Frame 4: attack strike, the scythe swung down low in a wide arc. $S"
  vespa     = "Animation sprite sheet for this hornet queen boss, flying. Frame 1: wings raised high. Frame 2: wings swept low. Frame 3: attack wind-up, abdomen curled forward under the body with the stinger aimed ahead. Frame 4: attack strike, stinger jabbed forward and down. $S"
  grimfang  = "Animation sprite sheet for this black direwolf boss, side three-quarter view. Frame 1: running, legs stretched apart. Frame 2: running, legs gathered under the body. Frame 3: attack wind-up, crouched low and snarling, ready to pounce. Frame 4: attack, leaping forward through the air with claws out and jaws open. $S"
  nyxwing   = "Animation sprite sheet for this giant moth boss, hovering, seen from the front. Frame 1: wings spread up high. Frame 2: wings swept down. Frame 3: attack wind-up, wings folded in close with the eye markings glowing brightly. Frame 4: attack, wings flung wide open releasing a burst of glowing scales. $S"
  oakheart  = "Animation sprite sheet for this walking tree guardian boss. Frame 1: walking, left root leg stepping forward. Frame 2: walking, right root leg stepping forward. Frame 3: attack wind-up, both branch arms raised high overhead. Frame 4: attack strike, both branch arms slammed down into the ground. $S"
}
$gen = "$env:USERPROFILE\.codex\generated_images"
$running = @()
foreach ($name in $jobs.Keys) {
  while (($running | Where-Object { $_.State -eq 'Running' }).Count -ge 3) { Start-Sleep -Seconds 3 }
  $p = 'Generate exactly one image with your image generation tool, using the attached image as the character reference, then stop. Do not write code or files. Image: ' + $jobs[$name]
  $running += Start-Job -Name $name -ArgumentList $p, "$out\frames_$name.log", "$out\boss_$name.png" -ScriptBlock { param($p, $log, $ref) codex exec --skip-git-repo-check $p --image $ref *> $log }
}
$running | Wait-Job | Out-Null
$dirs = Get-ChildItem $gen -Directory
foreach ($name in $jobs.Keys) {
  $log = Get-Content "$out\frames_$name.log" -Raw
  $d = $dirs | Where-Object { $log -match [regex]::Escape($_.Name) } | Select-Object -First 1
  if ($d) { $f = Get-ChildItem $d.FullName -File -Filter *.png | Sort-Object LastWriteTime -Descending | Select-Object -First 1; Copy-Item $f.FullName "$out\frames_$name.png" -Force; "$name -> ok" }
  else { "$name -> no image found" }
}
