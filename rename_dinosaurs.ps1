$path = Join-Path $PSScriptRoot "assets/images/dinosaurs"

if (-not (Test-Path $path)) {
    Write-Host "Error: No se encuentra la ruta $path" -ForegroundColor Red
    return
}

# Mapeo de sufijos y corrección de erratas
$rules = @{
    'recreation'  = 'normal'
    'recreatoin'  = 'normal'
    'recreacion'  = 'normal'
    'recreatiom'  = 'normal'
    'recration'   = 'normal'
    'recreaton'   = 'normal'
    'recreatio'   = 'normal'
    'size'        = 'comparison'
    'sige'        = 'comparison'
    'comparision' = 'comparison'
    '-size'       = 'comparison'
    'skeleton'    = 'skeleton'
    'skeletal'    = 'skeleton'
    'skelton'     = 'skeleton'
    'skeketon'    = 'skeleton'
    'slkeletal'   = 'skeleton'
    'normal'      = 'normal'
    'comparison'  = 'comparison'
}

$files = Get-ChildItem -Path $path -File | Where-Object { $_.Name -ine "desktop.ini" }
$actions = @()
$seenDestinations = @{}

foreach ($file in $files) {
    $extension = $file.Extension
    $baseName = $file.BaseName

    $foundSuffix = $null
    $namePart = $baseName

    # Ordenar por longitud descendente para coincidir con el más específico primero
    $sortedKeys = $rules.Keys | Sort-Object -Property Length -Descending

    foreach ($key in $sortedKeys) {
        # Búsqueda insensible a mayúsculas
        if ($baseName -like "*$key*") {
            $foundSuffix = $rules[$key]
            # Quitar la palabra clave del nombre (regex escape para seguridad)
            $namePart = $baseName -replace [regex]::Escape($key), ""
            break
        }
    }

    # Si no tiene palabra clave, asumimos que es la imagen normal
    if (-not $foundSuffix) {
        $foundSuffix = "normal"
    }

    # Limpiar el nombre (preservando el casing original)
    # Reemplaza espacios (normales y NBSP \u00A0), puntos, guiones, interrogaciones por "_"
    $namePart = $namePart -replace "[\s\xa0\.\-\?]+", "_"
    $namePart = $namePart.Trim("_")
    $namePart = $namePart -replace "_+", "_"

    if (-not $namePart) {
        $namePart = "dino"
    }

    # Construir el nuevo nombre
    $newFileName = "$namePart`_$foundSuffix$extension"

    if ($file.Name -eq $newFileName) {
        continue
    }

    $destPath = Join-Path $path $newFileName

    # Verificar conflictos
    if ($seenDestinations.ContainsKey($newFileName)) {
        Write-Host "ERROR: Conflicto de duplicados. '$($file.Name)' y '$($seenDestinations[$newFileName])' acabarían llamándose igual: '$newFileName'." -ForegroundColor Red
        return
    }

    if (Test-Path $destPath) {
        Write-Host "ERROR: El archivo '$newFileName' ya existe físicamente. No se puede renombrar '$($file.Name)' sin sobrescribir." -ForegroundColor Red
        return
    }

    $seenDestinations[$newFileName] = $file.Name
    $actions += [PSCustomObject]@{
        Source      = $file.FullName
        Destination = $destPath
        NewName     = $newFileName
        OldName     = $file.Name
    }
}

if ($actions.Count -eq 0) {
    Write-Host "Todos los archivos ya están correctamente nombrados."
    return
}

Write-Host "Renombrando $($actions.Count) archivos..."
foreach ($action in $actions) {
    Rename-Item -Path $action.Source -NewName $action.NewName
    Write-Host "OK: $($action.OldName) -> $($action.NewName)"
}

Write-Host "`n¡Listo! Nombres actualizados respetando mayúsculas/minúsculas."
