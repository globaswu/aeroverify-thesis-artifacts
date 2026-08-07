[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$packageRoot = [System.IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$manifestPath = Join-Path $packageRoot 'manifest.json'
if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    throw "Missing manifest: $manifestPath"
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$listed = [System.Collections.Generic.HashSet[string]]::new(
    [System.StringComparer]::OrdinalIgnoreCase)

foreach ($entry in $manifest.files) {
    $relative = [string]$entry.path
    $candidate = [System.IO.Path]::GetFullPath(
        (Join-Path $packageRoot ($relative -replace '/', [System.IO.Path]::DirectorySeparatorChar)))
    $prefix = $packageRoot.TrimEnd([System.IO.Path]::DirectorySeparatorChar) +
        [System.IO.Path]::DirectorySeparatorChar
    if (-not $candidate.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Manifest path escapes package root: $relative"
    }
    if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) {
        throw "Manifest file is missing: $relative"
    }
    $file = Get-Item -LiteralPath $candidate
    if ([int64]$entry.size_bytes -ne $file.Length) {
        throw "Size mismatch for $relative"
    }
    $hash = (Get-FileHash -LiteralPath $candidate -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($hash -ne ([string]$entry.sha256).ToLowerInvariant()) {
        throw "SHA-256 mismatch for $relative"
    }
    [void]$listed.Add($relative.Replace('\', '/'))
}

$maximumBytes = 20MB
$prohibitedExtensions = @(
    '.op2', '.f06', '.h5', '.hdf5', '.ntop', '.mat', '.fig', '.pdf'
)
$unlisted = [System.Collections.Generic.List[string]]::new()
foreach ($file in Get-ChildItem -LiteralPath $packageRoot -Recurse -File) {
    $relative = $file.FullName.Substring($packageRoot.Length + 1).Replace('\', '/')
    if ($relative.StartsWith('generated/', [System.StringComparison]::OrdinalIgnoreCase)) {
        continue
    }
    if ($file.Length -ge $maximumBytes) {
        throw "File is not below 20 MB: $relative"
    }
    if ($prohibitedExtensions -contains $file.Extension.ToLowerInvariant()) {
        throw "Prohibited release file type: $relative"
    }
    if ($relative -ne 'manifest.json' -and -not $listed.Contains($relative)) {
        $unlisted.Add($relative)
    }
}
if ($unlisted.Count -gt 0) {
    throw "Files absent from manifest: $($unlisted -join ', ')"
}

$textExtensions = @('.md', '.m', '.ps1', '.json', '.csv', '.txt')
$drivePattern = '[A-Za-z]' + [char]58 + '\\'
$uncIpPattern = '\\\\(?:\d{1,3}\.){3}\d{1,3}\\'
$profilePattern = '(?i)Users\\[^\\]+\\|OneDrive\\Desktop'
foreach ($file in Get-ChildItem -LiteralPath $packageRoot -Recurse -File) {
    if ($file.FullName -eq $PSCommandPath) {
        continue
    }
    if ($file.FullName.Contains(
        [System.IO.Path]::DirectorySeparatorChar + 'generated' +
        [System.IO.Path]::DirectorySeparatorChar)) {
        continue
    }
    if ($textExtensions -notcontains $file.Extension.ToLowerInvariant() -and
            $file.Name -ne '.gitignore') {
        continue
    }
    $text = Get-Content -LiteralPath $file.FullName -Raw
    if ($text -match $drivePattern -or $text -match $uncIpPattern -or
            $text -match $profilePattern) {
        $relative = $file.FullName.Substring($packageRoot.Length + 1)
        throw "Machine-specific path found in release text: $relative"
    }
}

Write-Output (("Manifest verified: {0} listed files; all hashes, sizes, " +
    "scope exclusions, and path checks passed.") -f $manifest.files.Count)
