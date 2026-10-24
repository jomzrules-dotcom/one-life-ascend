$ErrorActionPreference = 'Continue'
$out = $PSScriptRoot
# Floor 1 monsters in the cozy-sim direction, matched to the floor 1 redesign art (trees_meadow.png as the style reference)
$S = 'high quality 16-bit pixel art for a top-down action RPG, three-quarter top-down view in the style of cozy farming sim games, warm saturated colours, soft dark-tinted outlines (never pure black), hue-shifted shading with cool shadows and warm highlights, cute but a little menacing, crisp hard pixel edges, no blur, no anti-aliasing, on a perfectly flat solid magenta (#FF00FF) background with no shadow on the background, no ground plane, no text, no numbers, no border, no grid lines.'
$F = 'An animation sprite sheet in ONE single row of 8 frames with very wide magenta gaps so no frames touch, every frame the same scale and bottom-aligned on the same baseline, the creature facing right in every frame.'
$jobs = [ordered]@{
  slime = @("$F A small round green jelly slime monster, glossy and translucent with a bright highlight on top, two dark oval eyes and a tiny mouth. Frames: 1) resting, round; 2) squashed flat gathering for a hop; 3) stretched tall leaping up; 4) landing, wide and wobbling; 5) wind-up: squashed very low and wide, eyes narrowed angrily, body shaking; 6) strike: lunging forward to the right, stretched long like a spring; 7) resting with eyes closed in a blink; 8) hurt: flattened and pale, eyes squeezed shut. $S", "$out\trees_meadow.png")
  rat   = @("$F A small brown field rat monster with grey-brown fur, a pink nose, pink ears, a long pink tail and red eyes, seen from the side in three-quarter view. Frames: 1-4) a scurrying run cycle, legs and tail in different positions each frame; 5) wind-up: reared back on its hind legs, teeth bared, fur bristling; 6) strike: lunging forward to the right with its jaws open in a bite; 7) standing still, sniffing the air with its nose up; 8) hurt: recoiling backwards, eyes squeezed shut. $S", "$out\trees_meadow.png")
  elder = @("$F The Slime Elder, a big ancient green jelly slime boss, about three times the size of a normal slime, glossy and translucent with a bright highlight on top, moss and tiny flowers growing on its crown, small pebbles and a bone visible floating inside its body, wise angry eyes with heavy brows and a wide mouth. Frames: 1) resting, a big dome; 2) resting, wobbling slightly taller; 3) wind-up for a slam: rising up very tall and narrow; 4) slam: splatted flat and very wide on the ground; 5) summoning: bulging with three small slime blobs budding off its sides; 6) charge: leaning hard to the right, stretched forward; 7) furious: puffed up with its mouth wide open roaring; 8) hurt: flattened and pale with eyes squeezed shut. $S", "$out\trees_meadow.png")
}
$gen = "$env:USERPROFILE\.codex\generated_images"
$running = @()
foreach ($name in $jobs.Keys) {
  $p = 'Generate exactly one image with your image generation tool, then stop. Do not write code or files. Use the attached image only as a style reference. Image: ' + $jobs[$name][0]
  $running += Start-Job -Name $name -ArgumentList $p, "$out\mob2_$name.log", $jobs[$name][1] -ScriptBlock { param($p, $log, $ref) codex exec --skip-git-repo-check $p --image $ref *> $log }
}
$running | Wait-Job | Out-Null
$dirs = Get-ChildItem $gen -Directory
foreach ($name in $jobs.Keys) {
  $log = Get-Content "$out\mob2_$name.log" -Raw
  $d = $dirs | Where-Object { $log -match [regex]::Escape($_.Name) } | Select-Object -First 1
  if ($d) { $f = Get-ChildItem $d.FullName -File -Filter *.png | Sort-Object LastWriteTime -Descending | Select-Object -First 1; Copy-Item $f.FullName "$out\mob2_$name.png" -Force; "$name -> ok" }
  else { "$name -> no image found" }
}
