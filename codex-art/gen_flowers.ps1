$ErrorActionPreference = 'Continue'
$out = $PSScriptRoot
$S = 'pixel art for a top-down 16-bit SNES-style action RPG, three-quarter view, crisp pixel edges, limited palette, soft light from the top-left, on a perfectly flat solid magenta (#FF00FF) background with no shadow on the background, no ground plane, no text, no border, no grid lines.'
$jobs = [ordered]@{
  flower_props = @("A sprite sheet in a neat grid of 4 columns and 3 rows with wide magenta gaps between every item. Row 1: four different round flowering bushes covered in blossoms, the same size and shape as the reference bushes: a pink rose bush, a purple lavender bush, a white and yellow flowering shrub, a blue hydrangea bush. Row 2: four small low flower patches on a little tuft of grass: red tulips, white daisies, blue bluebells, orange and yellow marigolds. Row 3: four more small flower patches: pink cosmos, purple violets, red poppies, a mix of small wildflowers. Soft natural colours that sit well in a green meadow, same style as the reference props. $S", "$out\props.png")
  critters     = @("A sprite sheet in one row of seven small flying insects with very wide magenta gaps between them, each seen from directly above with wings spread: an orange monarch butterfly, a pale blue butterfly, a yellow brimstone butterfly, a white butterfly with black wing tips, a pink butterfly, a round fuzzy yellow and black striped bumblebee with clear wings, a honeybee. Cute, bold outlines, readable at a very small size. $S", "$out\props.png")
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
