$ErrorActionPreference = 'Stop'
$d = $PSScriptRoot
Add-Type -Path "$d\ArtTool.cs" -ReferencedAssemblies System.Drawing
$o = "$d\out17"; New-Item -ItemType Directory -Force $o | Out-Null
"trees:  " + [ArtTool]::Sheet("$d\trees_meadow.png", "$o\tree", 0.085, 40)
"props:  " + [ArtTool]::Sheet("$d\meadow_props.png", "$o\mprop", 0.085, 32)
"camp:   " + [ArtTool]::Sheet("$d\camp_props.png", "$o\camp", 0.08, 32)
"meadow: " + [ArtTool]::Texture("$d\tex_meadow.png", "$o\tex_meadow.png", 160, 24)
"trail:  " + [ArtTool]::Texture("$d\tex_trail.png", "$o\tex_trail.png", 160, 24)
"canopy: " + [ArtTool]::Texture("$d\tex_canopy.png", "$o\tex_canopy.png", 160, 24)
"slime:  " + [ArtTool]::Frames("$d\mob2_slime.png", "$o\slime", 8, 16, 24)
"rat:    " + [ArtTool]::Frames("$d\mob2_rat.png", "$o\rat", 8, 22, 24)
"elder:  " + [ArtTool]::Frames("$d\mob2_elder.png", "$o\elder", 8, 50, 32)
