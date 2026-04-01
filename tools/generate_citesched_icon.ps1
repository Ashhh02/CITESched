Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$flutterRoot = Join-Path $repoRoot 'citesched_flutter'
$serverRoot = Join-Path $repoRoot 'citesched_server'
$sourcePath = Join-Path $serverRoot 'assets\img\citesched_icon.png'
$flutterSourceOutput = Join-Path $flutterRoot 'assets\app_icon_source.png'
$flutterLogoOutput = Join-Path $flutterRoot 'assets\jmclogo.png'
$serverBuiltLogoOutput = Join-Path $serverRoot 'web\app\assets\assets\jmclogo.png'

if (-not (Test-Path $sourcePath)) {
    throw "Source icon not found: $sourcePath"
}

function Save-ResizedPng {
    param(
        [System.Drawing.Image]$Source,
        [int]$Size,
        [string]$Path
    )

    $dir = Split-Path -Parent $Path
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir | Out-Null
    }

    $bitmap = New-Object System.Drawing.Bitmap $Size, $Size
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.Clear([System.Drawing.Color]::Transparent)
    $graphics.DrawImage($Source, 0, 0, $Size, $Size)
    $bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    $graphics.Dispose()
    $bitmap.Dispose()
}

$source = [System.Drawing.Image]::FromFile($sourcePath)
$source.Save($flutterSourceOutput, [System.Drawing.Imaging.ImageFormat]::Png)
$source.Save($flutterLogoOutput, [System.Drawing.Imaging.ImageFormat]::Png)

if (Test-Path (Split-Path -Parent $serverBuiltLogoOutput)) {
    $source.Save($serverBuiltLogoOutput, [System.Drawing.Imaging.ImageFormat]::Png)
}

$iconTargets = @{
    'android\app\src\main\res\mipmap-mdpi\ic_launcher.png' = 48
    'android\app\src\main\res\mipmap-hdpi\ic_launcher.png' = 72
    'android\app\src\main\res\mipmap-xhdpi\ic_launcher.png' = 96
    'android\app\src\main\res\mipmap-xxhdpi\ic_launcher.png' = 144
    'android\app\src\main\res\mipmap-xxxhdpi\ic_launcher.png' = 192
    'web\favicon.png' = 32
    'web\icons\Icon-192.png' = 192
    'web\icons\Icon-maskable-192.png' = 192
    'web\icons\Icon-512.png' = 512
    'web\icons\Icon-maskable-512.png' = 512
    'macos\Runner\Assets.xcassets\AppIcon.appiconset\app_icon_16.png' = 16
    'macos\Runner\Assets.xcassets\AppIcon.appiconset\app_icon_32.png' = 32
    'macos\Runner\Assets.xcassets\AppIcon.appiconset\app_icon_64.png' = 64
    'macos\Runner\Assets.xcassets\AppIcon.appiconset\app_icon_128.png' = 128
    'macos\Runner\Assets.xcassets\AppIcon.appiconset\app_icon_256.png' = 256
    'macos\Runner\Assets.xcassets\AppIcon.appiconset\app_icon_512.png' = 512
    'macos\Runner\Assets.xcassets\AppIcon.appiconset\app_icon_1024.png' = 1024
}

foreach ($relativePath in $iconTargets.Keys) {
    Save-ResizedPng -Source $source -Size $iconTargets[$relativePath] -Path (Join-Path $flutterRoot $relativePath)
}

$iosContents = Get-Content (Join-Path $flutterRoot 'ios\Runner\Assets.xcassets\AppIcon.appiconset\Contents.json') | ConvertFrom-Json
foreach ($image in $iosContents.images) {
    if (-not $image.filename) {
        continue
    }

    $sizePart = ($image.size -split 'x')[0]
    $scale = [int]($image.scale.TrimEnd('x'))
    $pixels = [int][Math]::Round([double]$sizePart * $scale)
    Save-ResizedPng -Source $source -Size $pixels -Path (Join-Path $flutterRoot ('ios\Runner\Assets.xcassets\AppIcon.appiconset\' + $image.filename))
}

$serverWebTargets = @{
    'web\app\favicon.png' = 32
    'web\app\icons\Icon-192.png' = 192
    'web\app\icons\Icon-maskable-192.png' = 192
    'web\app\icons\Icon-512.png' = 512
    'web\app\icons\Icon-maskable-512.png' = 512
}

foreach ($relativePath in $serverWebTargets.Keys) {
    $targetPath = Join-Path $serverRoot $relativePath
    if (Test-Path (Split-Path -Parent $targetPath)) {
        Save-ResizedPng -Source $source -Size $serverWebTargets[$relativePath] -Path $targetPath
    }
}

$icoPath = Join-Path $flutterRoot 'windows\runner\resources\app_icon.ico'
$icon = [System.Drawing.Icon]::FromHandle(([System.Drawing.Bitmap]$source).GetHicon())
$stream = [System.IO.File]::Create($icoPath)
$icon.Save($stream)
$stream.Dispose()

$source.Dispose()
