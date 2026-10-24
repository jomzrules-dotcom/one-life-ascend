$ErrorActionPreference = 'Continue'
$out = $PSScriptRoot
# Back views: the same boss seen from behind, for when it heads up the screen away from the camera.
# Frame 1 repeats the reference's front pose only so the frames can be scaled to match; frames 2-5 are the back views.
$S = 'Keep it exactly the same character as the attached reference images: same design, same colours, same proportions, same pixel art style, same scale. Draw exactly five frames side by side in one horizontal row, evenly spaced, each frame centred in its fifth of the image, with wide gaps of empty background between them so no frames touch or overlap. Frame 1 is the plain neutral front pose from the reference, at exactly the reference size. Frames 2 to 5 show the character from BEHIND, facing away from the viewer towards the top of the screen, in a top-down three-quarter view from behind, at the same size as frame 1. Perfectly flat solid magenta (#FF00FF) background, no shadows on the background, no ground, no text, no numbers, no borders, no grid lines.'
$jobs = [ordered]@{
  gnawbelly = "Back-view animation frames for this giant mole boss. Frame 2: seen from behind, standing, the back of its furry body and the strap of its miner's helmet visible, weight on the left foot. Frame 3: seen from behind, standing, weight on the right foot. Frame 4: seen from behind, both iron claws raised high above its head. Frame 5: seen from behind, claws slammed down in front of it, dirt flying. $S"
  snapjaw   = "Back-view animation frames for this giant snapping turtle boss. Frame 2: seen from behind crawling away, the back of its spiked mossy shell and its tail towards the viewer, front left leg forward. Frame 3: seen from behind crawling away, front right leg forward. Frame 4: seen from behind, rearing back with its head pulled in, about to strike. Frame 5: seen from behind, neck shot far forward away from the viewer in a snapping bite. $S"
  harvest   = "Back-view animation frames for this floating scarecrow boss. Frame 2: seen from behind floating away, the back of its tattered patchwork coat and the back of its pumpkin head, coat swaying left. Frame 3: seen from behind, coat swaying right, slightly higher. Frame 4: seen from behind, the scythe raised high overhead with both hands. Frame 5: seen from behind, the scythe swung down low in a wide arc. $S"
  vespa     = "Back-view animation frames for this hornet queen boss flying away from the viewer. Frame 2: seen from behind and slightly above, the striped abdomen and stinger towards the viewer, wings raised high. Frame 3: seen from behind, wings swept low. Frame 4: seen from behind, abdomen curled under her body with the stinger aimed forward. Frame 5: seen from behind, stinger jabbed forward and down away from the viewer. $S"
  grimfang  = "Back-view animation frames for this black direwolf boss. Frame 2: seen from behind running away, its bushy tail and hind legs towards the viewer, legs stretched apart. Frame 3: seen from behind running away, legs gathered under the body. Frame 4: seen from behind, crouched low ready to pounce, ears back. Frame 5: seen from behind, leaping forward away from the viewer through the air, claws out. $S"
  oakheart  = "Back-view animation frames for this walking tree guardian boss. Frame 2: seen from behind walking away, the back of its gnarled trunk, its leafy canopy and mossy stone crown, left root leg stepping forward. Frame 3: seen from behind walking away, right root leg stepping forward. Frame 4: seen from behind, both branch arms raised high overhead. Frame 5: seen from behind, both branch arms slammed down into the ground in front of it. $S"
}
$gen = "$env:USERPROFILE\.codex\generated_images"
$running = @()
foreach ($name in $jobs.Keys) {
  while (($running | Where-Object { $_.State -eq 'Running' }).Count -ge 3) { Start-Sleep -Seconds 3 }
  $p = 'Generate exactly one image with your image generation tool, using the attached images as the character reference, then stop. Do not write code or files. Image: ' + $jobs[$name]
  $running += Start-Job -Name $name -ArgumentList $p, "$out\back_$name.log", "$out\boss_$name.png", "$out\frames_$name.png" -ScriptBlock { param($p, $log, $ref, $ref2) codex exec --skip-git-repo-check $p --image $ref --image $ref2 *> $log }
}
$running | Wait-Job | Out-Null
$dirs = Get-ChildItem $gen -Directory
foreach ($name in $jobs.Keys) {
  $log = Get-Content "$out\back_$name.log" -Raw
  $d = $dirs | Where-Object { $log -match [regex]::Escape($_.Name) } | Select-Object -First 1
  if ($d) { $f = Get-ChildItem $d.FullName -File -Filter *.png | Sort-Object LastWriteTime -Descending | Select-Object -First 1; Copy-Item $f.FullName "$out\back_$name.png" -Force; "$name -> ok" }
  else { "$name -> no image found" }
}
