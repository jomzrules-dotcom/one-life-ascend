$ErrorActionPreference = 'Continue'
$out = $PSScriptRoot
# Second set of boss frames. The boss's painting and its first frame sheet are attached as references.
# Frame 1 repeats the reference pose only so the frames can be scaled to match; frames 2-5 are the new poses.
$S = 'Keep it exactly the same character as the attached reference images: same design, same colours, same proportions, same pixel art style, same scale, three-quarter view facing the viewer. Draw exactly five frames side by side in one horizontal row, evenly spaced, each frame centred in its fifth of the image, with wide gaps of empty background between them so no frames touch or overlap. Frame 1 is the plain neutral standing pose from the reference, at exactly the reference size. Perfectly flat solid magenta (#FF00FF) background, no shadows on the background, no ground, no text, no numbers, no borders, no grid lines.'
$jobs = [ordered]@{
  gnawbelly = "Animation frames for this giant mole boss digging into the ground and bursting back out. Frame 2: crouched low, both claws tearing into the ground, dirt flying up. Frame 3: half sunk into a hole in a mound of brown dirt, only the upper body and claws above the dirt. Frame 4: almost gone, only the top of the helmet and the claw tips poking out of a dirt mound. Frame 5: bursting up out of the ground with arms thrown wide, a spray of dirt and rocks around it. $S"
  mycelia   = "Animation frames for this rooted giant mushroom boss. Frame 2: in-between breathing pose, cap tilted slightly left, tendrils swaying left. Frame 3: in-between breathing pose, cap tilted slightly right, tendrils swaying right. Frame 4: tendrils lashing out wide to the left and right, cap low. Frame 5: tendrils plunging down into the ground around it, cap raised. $S"
  snapjaw   = "Animation frames for this giant snapping turtle boss. Frame 2: crawling in-between pose, back left leg pushing. Frame 3: crawling in-between pose, back right leg pushing. Frame 4: head, legs and tail fully pulled into its shell, only the spiked mossy shell, spinning. Frame 5: swimming, only the head and the top of the shell visible as if half underwater, no legs. $S"
  harvest   = "Animation frames for this floating scarecrow boss. Frame 2: floating in-between pose, coat drifting left, scythe low. Frame 3: floating in-between pose, coat drifting right, scythe raised a little. Frame 4: arms flung wide, a flock of black crows bursting out of its coat. Frame 5: scythe held diagonally across its body ready for a cross-shaped cut, pumpkin eyes blazing. $S"
  vespa     = "Animation frames for this hornet queen boss. Frame 2: flying, wings halfway up. Frame 3: flying, wings halfway down, slight tilt. Frame 4: landing, legs stretched down, wings braking. Frame 5: resting on the ground, wings folded back along her body, legs planted. $S"
  grimfang  = "Animation frames for this black direwolf boss, side three-quarter view. Frame 2: galloping in-between, front legs reaching forward. Frame 3: galloping in-between, back legs pushing off. Frame 4: howling, head thrown back, muzzle pointed up, glowing eyes. Frame 5: landing from a leap, paws skidding, head low, recovering. $S"
  nyxwing   = "Animation frames for this giant moth boss, hovering, seen from the front. Frame 2: wings halfway up. Frame 3: wings halfway down. Frame 4: wings swept forward in a powerful gust, scales blowing ahead. Frame 5: channelling magic, wings raised in a tall V, eyes and wing markings glowing bright violet. $S"
  oakheart  = "Animation frames for this walking tree guardian boss. Frame 2: walking in-between, weight on the left root leg. Frame 3: walking in-between, weight on the right root leg. Frame 4: rooted in place, thick roots spreading from its base deep into the ground, arms at its sides. Frame 5: tearing itself free from the ground, roots ripping up with clods of dirt flying, arms raised. $S"
}
$gen = "$env:USERPROFILE\.codex\generated_images"
$running = @()
foreach ($name in $jobs.Keys) {
  while (($running | Where-Object { $_.State -eq 'Running' }).Count -ge 3) { Start-Sleep -Seconds 3 }
  $p = 'Generate exactly one image with your image generation tool, using the attached images as the character reference, then stop. Do not write code or files. Image: ' + $jobs[$name]
  $running += Start-Job -Name $name -ArgumentList $p, "$out\frames2_$name.log", "$out\boss_$name.png", "$out\frames_$name.png" -ScriptBlock { param($p, $log, $ref, $ref2) codex exec --skip-git-repo-check $p --image $ref --image $ref2 *> $log }
}
$running | Wait-Job | Out-Null
$dirs = Get-ChildItem $gen -Directory
foreach ($name in $jobs.Keys) {
  $log = Get-Content "$out\frames2_$name.log" -Raw
  $d = $dirs | Where-Object { $log -match [regex]::Escape($_.Name) } | Select-Object -First 1
  if ($d) { $f = Get-ChildItem $d.FullName -File -Filter *.png | Sort-Object LastWriteTime -Descending | Select-Object -First 1; Copy-Item $f.FullName "$out\frames2_$name.png" -Force; "$name -> ok" }
  else { "$name -> no image found" }
}
