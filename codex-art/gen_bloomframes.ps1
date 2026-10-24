$ErrorActionPreference = 'Continue'
$out = $PSScriptRoot
Add-Type -AssemblyName System.Drawing
# reference crops: each giant flower from the original sheet on its own
$src = [System.Drawing.Image]::FromFile("$out\flower_giants.png")
$w3 = [int]($src.Width / 3)
for ($i = 0; $i -lt 3; $i++) {
  $b = New-Object System.Drawing.Bitmap $w3, $src.Height; $g = [System.Drawing.Graphics]::FromImage($b)
  $g.DrawImage($src, (New-Object System.Drawing.Rectangle 0, 0, $w3, $src.Height), (New-Object System.Drawing.Rectangle ($i * $w3), 0, $w3, $src.Height), [System.Drawing.GraphicsUnit]::Pixel)
  $b.Save("$out\bloom_ref$i.png"); $g.Dispose(); $b.Dispose()
}
$src.Dispose()
$S = 'pixel art for a top-down 16-bit SNES-style action RPG, three-quarter view, crisp pixel edges, limited palette, soft light from the top-left, on a perfectly flat solid magenta (#FF00FF) background with no shadow on the background, no ground plane, no text, no numbers, no border, no grid lines.'
$A = 'in one row of 8 frames with very wide magenta gaps between them so no frames touch, showing one full gentle sway in the breeze that loops: frame 1 upright, frame 2 leaning slightly to the right, frame 3 leaning further to the right, frame 4 leaning slightly to the right, frame 5 upright, frame 6 leaning slightly to the left, frame 7 leaning further to the left, frame 8 leaning slightly to the left. Only the stems and blossoms bend, bending more towards the top; the leaves and the base at the bottom stay in exactly the same place in every frame. All 8 frames the same scale, bottom-aligned on one line, same colours and design as the reference in every frame.'
$jobs = [ordered]@{
  bloomf0 = @("An animation sprite sheet of exactly the plant in the attached reference image (tall spires of dusty pink foxglove bell flowers with broad leaves at the base), $A $S", "$out\bloom_ref0.png")
  bloomf1 = @("An animation sprite sheet of exactly the plant in the attached reference image (a leafy mound of stems topped with many white and pale yellow daisies), $A $S", "$out\bloom_ref1.png")
  bloomf2 = @("An animation sprite sheet of exactly the plant in the attached reference image (tall stems of soft lilac lupin flowers rising from a clump of broad leaves), $A $S", "$out\bloom_ref2.png")
}
$gen = "$env:USERPROFILE\.codex\generated_images"
$running = @()
foreach ($name in $jobs.Keys) {
  $p = 'Generate exactly one image with your image generation tool, then stop. Do not write code or files. Match the attached reference image exactly. Image: ' + $jobs[$name][0]
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
