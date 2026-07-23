[CmdletBinding()]
param(
    [Parameter()]
    [string]$Source
)

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing

$projectRoot = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($Source)) {
    $projectUserDirectory = Split-Path -Parent (
        Split-Path -Parent (
            Split-Path -Parent $projectRoot
        )
    )
    $downloadsDirectory = Join-Path $projectUserDirectory 'Downloads'
    $sourceFile = Get-ChildItem -LiteralPath $downloadsDirectory -File -Filter 'ChatGPT_Image_2026*16_55_32.png' |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
    if ($null -eq $sourceFile) {
        throw 'Source icon not found. Pass its path with -Source.'
    }
    $sourcePath = $sourceFile.FullName
}
else {
    $sourcePath = (Resolve-Path -LiteralPath $Source).Path
}
$assetDirectory = Join-Path $projectRoot 'assets\images'
$assetPath = Join-Path $assetDirectory 'app_logo.png'

New-Item -ItemType Directory -Path $assetDirectory -Force | Out-Null
Copy-Item -LiteralPath $sourcePath -Destination $assetPath -Force

$sourceImage = [System.Drawing.Image]::FromFile($assetPath)
try {
    if ($sourceImage.Width -ne $sourceImage.Height) {
        throw "The source icon must be square. Actual size: $($sourceImage.Width)x$($sourceImage.Height)."
    }

    function Write-ResizedPng {
        param(
            [Parameter(Mandatory)]
            [string]$RelativePath,

            [Parameter(Mandatory)]
            [int]$Size
        )

        $destination = Join-Path $projectRoot $RelativePath
        $destinationDirectory = Split-Path -Parent $destination
        New-Item -ItemType Directory -Path $destinationDirectory -Force | Out-Null

        $bitmap = [System.Drawing.Bitmap]::new(
            $Size,
            $Size,
            [System.Drawing.Imaging.PixelFormat]::Format24bppRgb
        )
        try {
            $bitmap.SetResolution(72, 72)
            $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
            try {
                $graphics.Clear([System.Drawing.Color]::White)
                $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
                $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
                $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
                $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality

                $attributes = [System.Drawing.Imaging.ImageAttributes]::new()
                try {
                    $attributes.SetWrapMode([System.Drawing.Drawing2D.WrapMode]::TileFlipXY)
                    $graphics.DrawImage(
                        $sourceImage,
                        [System.Drawing.Rectangle]::new(0, 0, $Size, $Size),
                        0,
                        0,
                        $sourceImage.Width,
                        $sourceImage.Height,
                        [System.Drawing.GraphicsUnit]::Pixel,
                        $attributes
                    )
                }
                finally {
                    $attributes.Dispose()
                }
            }
            finally {
                $graphics.Dispose()
            }

            $bitmap.Save($destination, [System.Drawing.Imaging.ImageFormat]::Png)
        }
        finally {
            $bitmap.Dispose()
        }

        [pscustomobject]@{
            Path = $RelativePath
            Size = "${Size}x${Size}"
        }
    }

    $targets = [ordered]@{
        'web\favicon.png' = 16
        'web\icons\Icon-192.png' = 192
        'web\icons\Icon-512.png' = 512
        'web\icons\Icon-maskable-192.png' = 192
        'web\icons\Icon-maskable-512.png' = 512

        'android\app\src\main\res\mipmap-mdpi\ic_launcher.png' = 48
        'android\app\src\main\res\mipmap-hdpi\ic_launcher.png' = 72
        'android\app\src\main\res\mipmap-xhdpi\ic_launcher.png' = 96
        'android\app\src\main\res\mipmap-xxhdpi\ic_launcher.png' = 144
        'android\app\src\main\res\mipmap-xxxhdpi\ic_launcher.png' = 192

        'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-20x20@1x.png' = 20
        'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-20x20@2x.png' = 40
        'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-20x20@3x.png' = 60
        'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-29x29@1x.png' = 29
        'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-29x29@2x.png' = 58
        'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-29x29@3x.png' = 87
        'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-40x40@1x.png' = 40
        'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-40x40@2x.png' = 80
        'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-40x40@3x.png' = 120
        'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-60x60@2x.png' = 120
        'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-60x60@3x.png' = 180
        'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-76x76@1x.png' = 76
        'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-76x76@2x.png' = 152
        'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-83.5x83.5@2x.png' = 167
        'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-1024x1024@1x.png' = 1024
    }

    $generated = foreach ($target in $targets.GetEnumerator()) {
        Write-ResizedPng -RelativePath $target.Key -Size $target.Value
    }

    Write-Host "Copied original icon to assets\images\app_logo.png ($($sourceImage.Width)x$($sourceImage.Height))."
    $generated | Format-Table -AutoSize
}
finally {
    $sourceImage.Dispose()
}
