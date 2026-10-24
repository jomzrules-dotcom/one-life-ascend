$ErrorActionPreference = 'Continue'
$out = $PSScriptRoot
# Floor 1 redesign, cozy-sim direction: warm saturated colour, soft tinted outlines, hue-shifted shading, big readable shapes
$S = 'high quality 16-bit pixel art for a top-down action RPG, three-quarter top-down view in the style of cozy farming sim games, warm saturated colours, soft dark-tinted outlines (deep green or brown, never pure black), hue-shifted shading with cool blue-green shadows and warm yellow highlights, clean readable shapes, crisp hard pixel edges, no blur, no anti-aliasing, on a perfectly flat solid magenta (#FF00FF) background with no shadow on the background, no ground plane, no text, no numbers, no border, no grid lines.'
$T = 'high quality 16-bit pixel art, seen straight from above, warm saturated colours, hue-shifted shading, crisp hard pixel edges, no blur, no anti-aliasing. It must tile seamlessly: the left edge continues the right edge and the top edge continues the bottom edge. Even coverage with no focal point, no vignette, no lighting gradient, no objects, no border, no text, no grid lines. Fill the whole square image edge to edge.'
$jobs = [ordered]@{
  tex_meadow  = @("A square seamless ground texture of a lush sunny meadow lawn: an even mid-green base with soft patches of slightly lighter and darker green, small scattered grass tufts drawn as three or four short blades, a few clover leaves and tiny pebbles. Calm and low in contrast so characters stand out on it. $T", $null)
  tex_trail   = @("A square seamless ground texture of a well-trodden earthen footpath: warm light-brown packed dirt with gentle darker patches, small rounded pebbles and a few cracks, faint footprint wear. Calm and low in contrast. $T", $null)
  tex_canopy  = @("A square seamless texture of a dense forest canopy seen from high above: many overlapping rounded clumps of leaves in deep and mid greens, each clump lit warm yellow-green on its top-left and falling into cool blue-green shade at the bottom-right, dark gaps between clumps. $T", $null)
  trees_meadow = @("Four separate trees in one row with very wide magenta gaps so nothing touches, all at the same scale and bottom-aligned: 1) a broad oak with a big round billowing canopy made of several leaf clumps, a thick brown trunk and roots spreading at its foot; 2) a second oak, taller and narrower, its canopy a different shape; 3) a young birch with a white trunk and a lighter, airier canopy; 4) a dark green pine tree. Each tree about twice as tall as wide, the trunk visible below the canopy. $S", $null)
  meadow_props = @("A sprite sheet of meadow props laid out in a loose grid with very wide magenta gaps so no two items touch, all at the same scale: a round green bush, a bush with red berries, a cut tree stump with rings, a mossy fallen log, a big grey boulder with moss on top, two small rocks, a clump of white daisies, a clump of yellow buttercups, a clump of purple lavender, a tall grass clump, a ring of three small brown mushrooms, a wooden signpost with an arrow board, a short wooden fence section with two posts. $S", $null)
  camp_props  = @("A sprite sheet of the props of a small abandoned travellers' camp, laid out in a loose grid with very wide magenta gaps so no two items touch, all at the same scale: an unlit campfire ring of stones with charred logs, a rolled-up bedroll, a wooden crate, a wooden barrel, a lantern hanging from a short wooden post, a log used as a bench, a small canvas lean-to tent. $S", $null)
}
$gen = "$env:USERPROFILE\.codex\generated_images"
$running = @()
foreach ($name in $jobs.Keys) {
  $p = 'Generate exactly one image with your image generation tool, then stop. Do not write code or files. Image: ' + $jobs[$name][0]
  $ref = $jobs[$name][1]
  $running += Start-Job -Name $name -ArgumentList $p, "$out\$name.log", $ref -ScriptBlock {
    param($p, $log, $ref)
    if ($ref) { codex exec --skip-git-repo-check $p --image $ref *> $log } else { codex exec --skip-git-repo-check $p *> $log }
  }
}
$running | Wait-Job | Out-Null
$dirs = Get-ChildItem $gen -Directory
foreach ($name in $jobs.Keys) {
  $log = Get-Content "$out\$name.log" -Raw
  $d = $dirs | Where-Object { $log -match [regex]::Escape($_.Name) } | Select-Object -First 1
  if ($d) { $f = Get-ChildItem $d.FullName -File -Filter *.png | Sort-Object LastWriteTime -Descending | Select-Object -First 1; Copy-Item $f.FullName "$out\$name.png" -Force; "$name -> ok" }
  else { "$name -> no image found" }
}
