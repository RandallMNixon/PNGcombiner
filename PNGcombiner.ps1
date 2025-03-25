# Automatically set the folder path to the location of the script
$folderPath = Split-Path -Path $MyInvocation.MyCommand.Definition

# Define the output file name
$outputFile = "combined_runtime_grid.png"

# Load System.Drawing
Add-Type -AssemblyName System.Drawing

# Get all PNG files in the folder
Write-Output "Looking for PNG files in: $folderPath"
$pngFiles = Get-ChildItem -Path $folderPath -Filter *.png | Sort-Object Name

if ($pngFiles.Count -eq 0) {
    Write-Output "No PNG files found in the folder where the script is located."
    exit
}

$totalImages = $pngFiles.Count
Write-Output "Found $totalImages PNG files."

# Suggest grid dimensions
Write-Output "Calculating suggested grid dimensions for $totalImages images..."
$suggestedGridWidth = [Math]::Ceiling([Math]::Sqrt($totalImages))
$suggestedGridHeight = [Math]::Ceiling($totalImages / $suggestedGridWidth)
Write-Output "Suggested grid size: $suggestedGridWidth squares across (width) and $suggestedGridHeight squares down (height)."

# Provide instructions for user input
Write-Output "You can use the suggested grid size by pressing Enter, or specify your own dimensions."
Write-Output "- Ensure the product of grid width and height is equal to or greater than the number of images ($totalImages)."
Write-Output "- If the grid size is larger than the number of images, the remaining spaces will be blank."

# Prompt the user for grid width and height
$gridWidthInput = Read-Host "Enter the number of squares across (grid width) [Suggested: $suggestedGridWidth]"
$gridHeightInput = Read-Host "Enter the number of squares down (grid height) [Suggested: $suggestedGridHeight]"

# Assign suggested values if the user presses Enter and explicitly convert to integers
$gridWidth = if ($gridWidthInput -eq "") { [int]$suggestedGridWidth } else { [int]$gridWidthInput }
$gridHeight = if ($gridHeightInput -eq "") { [int]$suggestedGridHeight } else { [int]$gridHeightInput }

Write-Output "Grid dimensions set to: $gridWidth x $gridHeight"

# Validate grid dimensions
if ($gridWidth * $gridHeight -lt $totalImages) {
    Write-Output "Error: The grid size ($gridWidth x $gridHeight) cannot fit all $totalImages images."
    exit
}

# Load the first image to determine tile dimensions
try {
    $sampleImage = [System.Drawing.Image]::FromFile($pngFiles[0].FullName)
    $tileWidth = $sampleImage.Width
    $tileHeight = $sampleImage.Height
    $sampleImage.Dispose()

    Write-Output "Tile dimensions determined: $tileWidth x $tileHeight"
} catch {
    Write-Output "Error loading the first image. Ensure all PNG files are valid."
    exit
}

# Calculate final image dimensions
$finalWidth = $gridWidth * $tileWidth
$finalHeight = $gridHeight * $tileHeight

Write-Output "Final image dimensions: $finalWidth x $finalHeight"

# Create a new empty bitmap with the combined dimensions
try {
    $finalImage = New-Object System.Drawing.Bitmap $finalWidth, $finalHeight
    $graphics = [System.Drawing.Graphics]::FromImage($finalImage)
    $graphics.Clear([System.Drawing.Color]::White)
    Write-Output "Successfully initialized the final image."
} catch {
    Write-Output "Error initializing the final image. Check calculated dimensions."
    exit
}

# Position images on the grid
$i = 0
foreach ($row in 0..($gridHeight - 1)) {
    foreach ($col in 0..($gridWidth - 1)) {
        if ($i -lt $pngFiles.Count) {
            try {
                Write-Output "Processing file: $($pngFiles[$i].FullName)"
                $image = [System.Drawing.Image]::FromFile($pngFiles[$i].FullName)
                $graphics.DrawImage($image, $col * $tileWidth, $row * $tileHeight, $tileWidth, $tileHeight)
                $image.Dispose()
                Write-Output "Image $($i + 1) positioned at grid: Row $row, Column $col"
            } catch {
                Write-Output "Error loading or drawing image: $($pngFiles[$i].FullName)"
            }
            $i++
        }
    }
}

# Save the final image
try {
    $finalImage.Save($outputFile, [System.Drawing.Imaging.ImageFormat]::Png)
    Write-Output "PNG files combined into a grid and saved as $outputFile in the same folder as this script."
} catch {
    Write-Output "Error saving the final image. Ensure the folder is writable."
}

# Clean up
$graphics.Dispose()
$finalImage.Dispose()
Write-Output "Script completed successfully."
