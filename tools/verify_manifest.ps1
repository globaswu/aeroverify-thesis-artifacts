[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$packageRoot = [System.IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$manifestPath = Join-Path $packageRoot 'manifest.json'
if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    throw "Missing manifest: $manifestPath"
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$textExtensions = @('.md', '.m', '.ps1', '.json', '.csv', '.txt', '.yml', '.cff')
$utf8WithoutBom = [System.Text.UTF8Encoding]::new($false)

function Get-PortableBytes {
    param([System.IO.FileInfo]$File)
    $isText = $textExtensions -contains $File.Extension.ToLowerInvariant() -or
        $File.Name -in @('.gitignore', '.gitattributes')
    if (-not $isText) {
        return ,([System.IO.File]::ReadAllBytes($File.FullName))
    }
    $content = [System.IO.File]::ReadAllText($File.FullName)
    $normalized = $content -replace "`r`n?", "`n"
    return ,($utf8WithoutBom.GetBytes($normalized))
}

function Get-Sha256Hex {
    param([byte[]]$Bytes)
    $algorithm = [System.Security.Cryptography.SHA256]::Create()
    try {
        $hash = $algorithm.ComputeHash($Bytes)
    }
    finally {
        $algorithm.Dispose()
    }
    return (($hash | ForEach-Object { $_.ToString('x2') }) -join '')
}

$listed = [System.Collections.Generic.HashSet[string]]::new(
    [System.StringComparer]::OrdinalIgnoreCase)
$packagePrefix = $packageRoot.TrimEnd(
    [System.IO.Path]::DirectorySeparatorChar) +
    [System.IO.Path]::DirectorySeparatorChar

foreach ($entry in $manifest.files) {
    $relative = [string]$entry.path
    $candidate = [System.IO.Path]::GetFullPath((Join-Path $packageRoot (
        $relative -replace '/', [System.IO.Path]::DirectorySeparatorChar)))
    if (-not $candidate.StartsWith(
            $packagePrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Manifest path escapes package root: $relative"
    }
    if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) {
        throw "Manifest file is missing: $relative"
    }
    $file = Get-Item -LiteralPath $candidate
    [byte[]]$portableBytes = Get-PortableBytes -File $file
    if ([int64]$entry.size_bytes -ne $portableBytes.LongLength) {
        throw "Size mismatch for $relative"
    }
    $hash = Get-Sha256Hex -Bytes $portableBytes
    if ($hash -ne ([string]$entry.sha256).ToLowerInvariant()) {
        throw "SHA-256 mismatch for $relative"
    }
    if (-not $listed.Add($relative.Replace('\', '/'))) {
        throw "Duplicate manifest path: $relative"
    }
}

$maximumBytes = 100MB
$prohibitedExtensions = @(
    '.op2', '.f04', '.f06', '.h5', '.hdf5', '.ntop', '.mat', '.fig',
    '.bdf', '.dat', '.pch', '.rcf', '.zip', '.mexw64', '.exe', '.dll'
)
$unlisted = [System.Collections.Generic.List[string]]::new()
foreach ($file in Get-ChildItem -LiteralPath $packageRoot -Recurse -File) {
    $relative = $file.FullName.Substring($packageRoot.Length + 1).Replace('\', '/')
    if ($relative.StartsWith('.git/', [System.StringComparison]::OrdinalIgnoreCase) -or
            $relative.StartsWith('generated/', [System.StringComparison]::OrdinalIgnoreCase) -or
            $relative.StartsWith('test-output/', [System.StringComparison]::OrdinalIgnoreCase) -or
            $relative.StartsWith('tmp/', [System.StringComparison]::OrdinalIgnoreCase)) {
        continue
    }
    if ($file.Length -ge $maximumBytes) {
        throw "Release file reaches or exceeds GitHub's 100 MiB limit: $relative"
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

$drivePattern = '[A-Za-z]' + [char]58 + '\\'
$uncIpPattern = '\\\\(?:\d{1,3}\.){3}\d{1,3}\\'
$profilePattern = '(?i)Users\\[^\\]+\\|OneDrive\\Desktop|/home/[^/]+/'
$privateHostPattern = '(?i)YH-WS117'
$secretPatterns = @(
    '-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----',
    'gh[pousr]_[A-Za-z0-9_]{30,}',
    'sk-[A-Za-z0-9]{32,}',
    'AKIA[0-9A-Z]{16}'
)

foreach ($file in Get-ChildItem -LiteralPath $packageRoot -Recurse -File) {
    $relative = $file.FullName.Substring($packageRoot.Length + 1).Replace('\', '/')
    if ($relative.StartsWith('.git/', [System.StringComparison]::OrdinalIgnoreCase) -or
            $relative.StartsWith('generated/', [System.StringComparison]::OrdinalIgnoreCase) -or
            $relative.StartsWith('test-output/', [System.StringComparison]::OrdinalIgnoreCase) -or
            $relative.StartsWith('tmp/', [System.StringComparison]::OrdinalIgnoreCase) -or
            $file.FullName -eq $PSCommandPath -or
            $textExtensions -notcontains $file.Extension.ToLowerInvariant()) {
        continue
    }
    $content = Get-Content -LiteralPath $file.FullName -Raw
    if ($content -match $drivePattern -or $content -match $uncIpPattern -or
            $content -match $profilePattern -or $content -match $privateHostPattern) {
        throw "Machine-specific path or host found in release text: $relative"
    }
    foreach ($pattern in $secretPatterns) {
        if ($content -match $pattern) {
            throw "Potential credential found in release text: $relative"
        }
    }
}

Write-Output (("Manifest verified: {0} files; hashes, sizes, completeness, " +
    "excluded types, machine paths, and high-confidence secret patterns passed.") -f
    $manifest.files.Count)
