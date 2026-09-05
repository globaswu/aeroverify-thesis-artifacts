[CmdletBinding()]
param(
    [switch]$KeepFixture
)

$ErrorActionPreference = 'Stop'
$packageRoot = [System.IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$generatedRoot = [System.IO.Path]::GetFullPath((Join-Path $packageRoot 'generated'))
$fixtureName = 'manifest-portability-' + [guid]::NewGuid().ToString('N')
$fixtureRoot = [System.IO.Path]::GetFullPath((Join-Path $generatedRoot $fixtureName))
$utf8WithoutBom = [System.Text.UTF8Encoding]::new($false)
$utf8WithBom = [System.Text.UTF8Encoding]::new($true)
$script:checkCount = 0
$completed = $false

function Assert-FixtureRoot {
    $expected = [System.IO.Path]::GetFullPath((Join-Path $generatedRoot $fixtureName))
    $prefix = $generatedRoot.TrimEnd([System.IO.Path]::DirectorySeparatorChar) +
        [System.IO.Path]::DirectorySeparatorChar
    if ($fixtureName -notmatch '^manifest-portability-[0-9a-f]{32}$' -or
            $fixtureRoot -ne $expected -or
            -not $fixtureRoot.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw 'Refusing to use an unexpected fixture directory.'
    }
    foreach ($directory in @($generatedRoot, $fixtureRoot)) {
        if (Test-Path -LiteralPath $directory) {
            $item = Get-Item -LiteralPath $directory -Force
            if (-not $item.PSIsContainer -or
                    ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint)) {
                throw 'Refusing to use a fixture directory containing a reparse point.'
            }
        }
    }
}

function Assert-Accepted {
    param([string]$Name)
    $output = @(& $verifyScript)
    if (-not ($output -match '^Manifest verified: 4 files;')) {
        throw "Expected successful four-file verification: $Name"
    }
    $script:checkCount++
    Write-Output "PASS: $Name"
}

function Assert-Rejected {
    param([string]$Name, [string]$ExpectedMessage)
    $failure = $null
    try {
        & $verifyScript | Out-Null
    }
    catch {
        $failure = $_.Exception.Message
    }
    if ($null -eq $failure) {
        throw "Verifier unexpectedly accepted: $Name"
    }
    if ($failure -notlike ($ExpectedMessage + '*')) {
        throw "Unexpected rejection for ${Name}: $failure"
    }
    $script:checkCount++
    Write-Output "PASS: $Name"
}

function Assert-UnchangedManifest {
    param([string]$Name)
    & $updateScript | Out-Null
    if ([System.IO.File]::ReadAllText($manifestPath) -cne $baselineManifest) {
        throw "Updater changed the LF baseline manifest: $Name"
    }
    $script:checkCount++
    Write-Output "PASS: $Name"
}

Assert-FixtureRoot
if (Test-Path -LiteralPath $fixtureRoot) {
    throw 'The unique fixture directory already exists.'
}
try {
    $fixtureTools = Join-Path $fixtureRoot 'tools'
    New-Item -ItemType Directory -Path $fixtureTools -Force | Out-Null
    foreach ($name in @('verify_manifest.ps1', 'update_manifest.ps1')) {
        Copy-Item -LiteralPath (Join-Path $PSScriptRoot $name) -Destination $fixtureTools
    }
    $verifyScript = Join-Path $fixtureTools 'verify_manifest.ps1'
    $updateScript = Join-Path $fixtureTools 'update_manifest.ps1'
    $manifestPath = Join-Path $fixtureRoot 'manifest.json'
    $textPath = Join-Path $fixtureRoot 'sample.txt'
    $binaryPath = Join-Path $fixtureRoot 'sample.bin'
    $baselineText = "alpha`nbeta`n"
    [byte[]]$baselineBinary = @(0, 10, 13, 128, 255)
    [System.IO.File]::WriteAllText($textPath, $baselineText, $utf8WithoutBom)
    [System.IO.File]::WriteAllBytes($binaryPath, $baselineBinary)
    & $updateScript | Out-Null
    $baselineManifest = [System.IO.File]::ReadAllText($manifestPath)
    Assert-Accepted 'LF baseline'

    [System.IO.File]::WriteAllText(
        $textPath, ($baselineText -replace "`n", "`r`n"), $utf8WithoutBom)
    Assert-Accepted 'CRLF text accepted against LF manifest'
    Assert-UnchangedManifest 'CRLF updater preserves LF manifest'

    [System.IO.File]::WriteAllText($textPath, $baselineText, $utf8WithBom)
    Assert-Accepted 'UTF-8 BOM text accepted against LF manifest'
    Assert-UnchangedManifest 'UTF-8 BOM updater preserves LF manifest'

    [System.IO.File]::WriteAllText(
        $textPath, ($baselineText -replace "`n", "`r`n"), $utf8WithBom)
    Assert-Accepted 'CRLF with UTF-8 BOM accepted against LF manifest'
    Assert-UnchangedManifest 'CRLF with UTF-8 BOM updater preserves LF manifest'

    [System.IO.File]::WriteAllText($textPath, "ALPHA`nbeta`n", $utf8WithoutBom)
    Assert-Rejected 'Same-length text tamper rejected' 'SHA-256 mismatch for sample.txt'
    [System.IO.File]::WriteAllText($textPath, $baselineText, $utf8WithoutBom)

    [System.IO.File]::WriteAllBytes($binaryPath, [byte[]]@(0, 10, 13, 129, 255))
    Assert-Rejected 'Same-length binary tamper rejected' 'SHA-256 mismatch for sample.bin'
    [System.IO.File]::WriteAllBytes($binaryPath, $baselineBinary)

    $missingTextPath = Join-Path $fixtureRoot 'sample.txt.moved'
    [System.IO.File]::Move($textPath, $missingTextPath)
    Assert-Rejected 'Missing listed file rejected' 'Manifest file is missing: sample.txt'
    [System.IO.File]::Move($missingTextPath, $textPath)

    foreach ($unsafePath in @('../outside.txt', '..\outside.txt')) {
        $unsafeManifest = $baselineManifest | ConvertFrom-Json
        $unsafeManifest.files[0].path = $unsafePath
        [System.IO.File]::WriteAllText(
            $manifestPath, ($unsafeManifest | ConvertTo-Json -Depth 6), $utf8WithoutBom)
        Assert-Rejected "Path escape rejected ($unsafePath)" 'Manifest path escapes package root:'
    }
    [System.IO.File]::WriteAllText($manifestPath, $baselineManifest, $utf8WithoutBom)
    Assert-Accepted 'Restored fixture passes'
    $completed = $true
    Write-Output "Manifest portability regression passed: $script:checkCount checks."
}
finally {
    if ($completed -and -not $KeepFixture) {
        Assert-FixtureRoot
        $reparsePoints = @(Get-ChildItem -LiteralPath $fixtureRoot -Recurse -Force |
            Where-Object { $_.Attributes -band [System.IO.FileAttributes]::ReparsePoint })
        if ($reparsePoints.Count -gt 0) {
            throw 'Refusing to remove a fixture containing a reparse point.'
        }
        Remove-Item -LiteralPath $fixtureRoot -Recurse -Force
        Write-Output 'Removed the generated test fixture; repository data and manifest were not changed.'
    }
    elseif (Test-Path -LiteralPath $fixtureRoot) {
        Write-Output "Fixture retained for inspection: $fixtureRoot"
    }
}
