Add-Type -AssemblyName System.Drawing

$baseDir = "c:\Users\儲秉軒\Downloads\物理"
$folders = @("1", "2", "3", "4", "5")

foreach ($folder in $folders) {
    $folderPath = Join-Path $baseDir $folder
    if (-not (Test-Path $folderPath)) { continue }
    
    $files = Get-ChildItem -Path $folderPath -Filter "*.jpg"
    foreach ($file in $files) {
        # Skip already cropped images
        if ($file.Name -like "*_cropped.jpg") { continue }
        
        $srcPath = $file.FullName
        $destPath = [System.IO.Path]::Combine($folderPath, ($file.BaseName + "_cropped.jpg"))
        
        Write-Output "Processing: $($file.Name)..."
        
        try {
            $img = [System.Drawing.Bitmap]::FromFile($srcPath)
            $w = $img.Width
            $h = $img.Height
            
            $minX = $w
            $maxX = 0
            $minY = $h
            $maxY = 0
            
            # Use step size 15 for faster scanning
            for ($y = 0; $y -lt $h; $y += 15) {
                for ($x = 0; $x -lt $w; $x += 15) {
                    $c = $img.GetPixel($x, $y)
                    # Check green chalkboard range
                    if ($c.G -gt 35 -and $c.G -lt 120 -and $c.G -gt ($c.R + 5) -and $c.G -gt ($c.B + 5) -and $c.R -lt 100 -and $c.B -lt 100) {
                        if ($x -lt $minX) { $minX = $x }
                        if ($x -gt $maxX) { $maxX = $x }
                        if ($y -lt $minY) { $minY = $y }
                        if ($y -gt $maxY) { $maxY = $y }
                    }
                }
            }
            
            if ($minX -lt $maxX -and $minY -lt $maxY) {
                # Add margin padding
                $pad = 15
                $left = [Math]::Max(0, $minX - $pad)
                $right = [Math]::Min($w - 1, $maxX + $pad)
                $top = [Math]::Max(0, $minY - $pad)
                $bottom = [Math]::Min($h - 1, $maxY + $pad)
                
                $cropW = $right - $left
                $cropH = $bottom - $top
                
                # Crop
                $rect = New-Object System.Drawing.Rectangle($left, $top, $cropW, $cropH)
                $cropped = $img.Clone($rect, $img.PixelFormat)
                
                # Save cropped image
                $cropped.Save($destPath, [System.Drawing.Imaging.ImageFormat]::Jpeg)
                $cropped.Dispose()
                Write-Output "  Successfully cropped to: X=[$left, $right], Y=[$top, $bottom]"
            } else {
                # Fallback to copy original if color detection fails
                Copy-Item -Path $srcPath -Destination $destPath -Force
                Write-Output "  No chalkboard detected. Copied original to cropped path."
            }
            $img.Dispose()
        }
        catch {
            Write-Output "  Error processing $($file.Name): $_"
        }
    }
}
Write-Output "All cropping tasks completed."
