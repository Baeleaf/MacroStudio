[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^\d+\.\d+\.\d+(?:[-+][0-9A-Za-z.-]+)?$')]
    [string]$Version
)

$ErrorActionPreference = 'Stop'

$repositoryRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$tocPath = Join-Path $repositoryRoot 'MacroStudio.toc'
$distPath = Join-Path $repositoryRoot 'dist'
$zipPath = Join-Path $distPath "MacroStudio-v$Version.zip"
$packageId = [Guid]::NewGuid().ToString('N')
$stagingRoot = Join-Path ([System.IO.Path]::GetTempPath()) "MacroStudio-package-$packageId"
$stagedAddonPath = Join-Path $stagingRoot 'MacroStudio'
$temporaryZipPath = Join-Path ([System.IO.Path]::GetTempPath()) "MacroStudio-v$Version-$packageId.zip"
$archive = $null

function Get-RuntimeRelativePath {
    param([AllowEmptyString()][string]$TocLine)

    $candidate = $TocLine.Trim()
    if ($candidate.Length -eq 0 -or $candidate.StartsWith('#')) {
        return $null
    }

    if ([System.IO.Path]::IsPathRooted($candidate)) {
        throw "The TOC contains an absolute runtime path: $candidate"
    }

    $segments = @($candidate -split '[\\/]')
    if ($segments.Count -eq 0 -or $segments -contains '' -or $segments -contains '.' -or $segments -contains '..') {
        throw "The TOC contains an unsafe runtime path: $candidate"
    }

    return ($segments -join [System.IO.Path]::DirectorySeparatorChar)
}

try {
    if (-not (Test-Path -LiteralPath $tocPath -PathType Leaf)) {
        throw "Required addon manifest is missing: $tocPath"
    }

    $tocLines = @(Get-Content -LiteralPath $tocPath)
    $tocVersion = $null
    $tocIconTexture = $null
    foreach ($tocLine in $tocLines) {
        if ($null -eq $tocVersion -and $tocLine -match '^## Version:\s*(.+?)\s*$') {
            $tocVersion = $Matches[1]
        }
        if ($null -eq $tocIconTexture -and $tocLine -match '^## IconTexture:\s*(.+?)\s*$') {
            $tocIconTexture = $Matches[1]
        }
    }
    if ($null -eq $tocVersion) {
        throw 'MacroStudio.toc does not declare a ## Version value.'
    }
    if ($tocVersion -ne $Version) {
        throw "Requested package version '$Version' does not match MacroStudio.toc version '$tocVersion'."
    }
    $coreVersionMatch = [regex]::Match((Get-Content -LiteralPath (Join-Path $repositoryRoot 'Core.lua') -Raw), 'MacroStudio\.VERSION\s*=\s*"([^"]+)"')
    if (-not $coreVersionMatch.Success -or $coreVersionMatch.Groups[1].Value -ne $tocVersion) {
        throw 'Core.lua displayed version must match the TOC and requested package version.'
    }
    if ($null -eq $tocIconTexture) {
        throw 'MacroStudio.toc does not declare a ## IconTexture value.'
    }

    $runtimePaths = New-Object 'System.Collections.Generic.List[string]'
    $seenPaths = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
    [void]$runtimePaths.Add('MacroStudio.toc')
    [void]$seenPaths.Add('MacroStudio.toc')
    # Preserve the MIT copyright and permission notice in every distribution.
    [void]$runtimePaths.Add('LICENSE')
    [void]$seenPaths.Add('LICENSE')

    $normalizedIconTexture = $tocIconTexture.Replace('/', '\')
    $iconPrefix = 'Interface\AddOns\MacroStudio\'
    if (-not $normalizedIconTexture.StartsWith($iconPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "IconTexture must point inside the packaged MacroStudio addon: $tocIconTexture"
    }
    $iconRelativePath = Get-RuntimeRelativePath -TocLine $normalizedIconTexture.Substring($iconPrefix.Length)
    if ($seenPaths.Add($iconRelativePath)) {
        [void]$runtimePaths.Add($iconRelativePath)
    }

    foreach ($tocLine in $tocLines) {
        $relativePath = Get-RuntimeRelativePath -TocLine $tocLine
        if ($null -ne $relativePath -and $seenPaths.Add($relativePath)) {
            [void]$runtimePaths.Add($relativePath)
        }
    }

    New-Item -ItemType Directory -Path $stagedAddonPath -Force | Out-Null
    $repositoryPrefix = $repositoryRoot.TrimEnd([System.IO.Path]::DirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar

    foreach ($relativePath in $runtimePaths) {
        $sourcePath = [System.IO.Path]::GetFullPath((Join-Path $repositoryRoot $relativePath))
        if (-not $sourcePath.StartsWith($repositoryPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "Runtime path resolves outside the repository: $relativePath"
        }
        if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
            throw "Required runtime file is missing: $relativePath"
        }

        $destinationPath = Join-Path $stagedAddonPath $relativePath
        $destinationDirectory = Split-Path -Parent $destinationPath
        if (-not (Test-Path -LiteralPath $destinationDirectory -PathType Container)) {
            New-Item -ItemType Directory -Path $destinationDirectory -Force | Out-Null
        }
        Copy-Item -LiteralPath $sourcePath -Destination $destinationPath
    }

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    Add-Type -AssemblyName System.IO.Compression
    $archive = [System.IO.Compression.ZipFile]::Open(
        $temporaryZipPath,
        [System.IO.Compression.ZipArchiveMode]::Create
    )
    try {
        foreach ($relativePath in $runtimePaths) {
            $stagedSourcePath = Join-Path $stagedAddonPath $relativePath
            $entryName = 'MacroStudio/' + $relativePath.Replace('\', '/')
            [void][System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
                $archive,
                $stagedSourcePath,
                $entryName,
                [System.IO.Compression.CompressionLevel]::Optimal
            )
        }
    }
    finally {
        $archive.Dispose()
        $archive = $null
    }

    $archive = [System.IO.Compression.ZipFile]::OpenRead($temporaryZipPath)
    $archiveFiles = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($entry in $archive.Entries) {
        if ($entry.FullName.Contains('\')) {
            throw "Generated archive contains a non-portable entry path: $($entry.FullName)"
        }
        $entryName = $entry.FullName.Replace('\', '/')
        if (-not $entryName.EndsWith('/')) {
            [void]$archiveFiles.Add($entryName)
        }
    }

    foreach ($relativePath in $runtimePaths) {
        $expectedEntry = 'MacroStudio/' + $relativePath.Replace('\', '/')
        if (-not $archiveFiles.Contains($expectedEntry)) {
            throw "Generated archive is missing required entry: $expectedEntry"
        }
    }
    if ($archiveFiles.Count -ne $runtimePaths.Count) {
        throw "Generated archive contains unexpected files: expected $($runtimePaths.Count), found $($archiveFiles.Count)."
    }
    if (-not $archiveFiles.Contains('MacroStudio/MacroStudio.toc')) {
        throw 'Generated archive does not contain MacroStudio/MacroStudio.toc.'
    }

    $archive.Dispose()
    $archive = $null

    New-Item -ItemType Directory -Path $distPath -Force | Out-Null
    if (Test-Path -LiteralPath $zipPath) {
        Remove-Item -LiteralPath $zipPath -Force
    }
    Move-Item -LiteralPath $temporaryZipPath -Destination $zipPath

    Write-Host "Packaged $($runtimePaths.Count) files (addon runtime and license)." -ForegroundColor Green
    Write-Output $zipPath
}
finally {
    if ($null -ne $archive) {
        $archive.Dispose()
    }
    if (Test-Path -LiteralPath $temporaryZipPath) {
        Remove-Item -LiteralPath $temporaryZipPath -Force
    }
    if (Test-Path -LiteralPath $stagingRoot) {
        $resolvedStagingRoot = (Resolve-Path -LiteralPath $stagingRoot).Path
        $expectedStagingRoot = [System.IO.Path]::GetFullPath((Join-Path ([System.IO.Path]::GetTempPath()) "MacroStudio-package-$packageId"))
        if ($resolvedStagingRoot -ne $expectedStagingRoot) {
            throw "Refusing to remove unexpected staging directory: $resolvedStagingRoot"
        }
        Remove-Item -LiteralPath $resolvedStagingRoot -Recurse -Force
    }
}
