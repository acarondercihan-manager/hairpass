Add-Type -AssemblyName System.Drawing

$srcPath = "c:\Users\Onder\Desktop\Yeni klasör\source_logo.jpg"
$src = [System.Drawing.Image]::FromFile($srcPath)

$w = $src.Width
$h = $src.Height

# Ortadaki kare HairPass ahşap rozet
# Görselde ortadaki büyük kare rozet koordinatları:
# Sol: %22.5, Üst: %20.5, Genişlik: %55, Yükseklik: %57
$cropX = [int]($w * 0.225)
$cropY = [int]($h * 0.205)
$cropW = [int]($w * 0.55)
$cropH = [int]($h * 0.57)

$rect = New-Object System.Drawing.Rectangle $cropX, $cropY, $cropW, $cropH
$cropped = New-Object System.Drawing.Bitmap $cropW, $cropH
$g = [System.Drawing.Graphics]::FromImage($cropped)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.DrawImage($src, (New-Object System.Drawing.Rectangle 0, 0, $cropW, $cropH), $rect, [System.Drawing.GraphicsUnit]::Pixel)

$publicDir = "c:\Users\Onder\Desktop\Yeni klasör\public"
$appDir = "c:\Users\Onder\Desktop\Yeni klasör\kuafor_app\assets\images"

if (!(Test-Path $appDir)) { 
    New-Item -ItemType Directory -Force -Path $appDir | Out-Null
}

$cropped.Save("$publicDir\logo.png", [System.Drawing.Imaging.ImageFormat]::Png)
$cropped.Save("$appDir\logo.png", [System.Drawing.Imaging.ImageFormat]::Png)

# 192x192 ikon
$b192 = New-Object System.Drawing.Bitmap 192, 192
$g192 = [System.Drawing.Graphics]::FromImage($b192)
$g192.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g192.DrawImage($cropped, 0, 0, 192, 192)
$b192.Save("$publicDir\icon-192.png", [System.Drawing.Imaging.ImageFormat]::Png)
$g192.Dispose()
$b192.Dispose()

# 512x512 ikon
$b512 = New-Object System.Drawing.Bitmap 512, 512
$g512 = [System.Drawing.Graphics]::FromImage($b512)
$g512.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g512.DrawImage($cropped, 0, 0, 512, 512)
$b512.Save("$publicDir\icon-512.png", [System.Drawing.Imaging.ImageFormat]::Png)
$g512.Dispose()
$b512.Dispose()

$g.Dispose()
$cropped.Dispose()
$src.Dispose()

Write-Output "BAŞARILI: Logo ve ikonlar oluşturuldu!"
