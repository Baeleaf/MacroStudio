[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$AddOnsPath
)

$ErrorActionPreference = 'Stop'

function Get-NormalizedPath {
    param([Parameter(Mandatory = $true)][string]$Path)
    return [System.IO.Path]::GetFullPath($Path).TrimEnd('\')
}

$repositoryRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$tocPath = Join-Path $repositoryRoot 'MacroStudio.toc'

if (-not (Test-Path -LiteralPath $tocPath -PathType Leaf)) {
    throw "MacroStudio.toc was not found at the repository root: $repositoryRoot"
}

if (-not (Test-Path -LiteralPath $AddOnsPath -PathType Container)) {
    throw "The supplied AddOns directory does not exist: $AddOnsPath"
}

$resolvedAddOnsPath = (Resolve-Path -LiteralPath $AddOnsPath).Path
$linkPath = Join-Path $resolvedAddOnsPath 'MacroStudio'
$expectedTarget = Get-NormalizedPath -Path $repositoryRoot
$existingItem = Get-Item -LiteralPath $linkPath -Force -ErrorAction SilentlyContinue

if ($null -ne $existingItem) {
    $isReparsePoint = ($existingItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0
    $isJunction = $isReparsePoint -and $existingItem.LinkType -eq 'Junction'

    if ($isJunction) {
        $targets = @($existingItem.Target)
        $matchesExpectedTarget = $false
        foreach ($target in $targets) {
            if ($target -and (Get-NormalizedPath -Path $target) -eq $expectedTarget) {
                $matchesExpectedTarget = $true
            }
        }

        if ($matchesExpectedTarget) {
            Write-Host 'MacroStudio development Junction is already configured correctly.' -ForegroundColor Green
            Write-Host "WoW addon: $linkPath"
            Write-Host "Repository: $repositoryRoot"
            return
        }

        throw "A Junction already exists at '$linkPath', but it targets '$($targets -join ', ')' instead of '$repositoryRoot'. Remove or inspect it manually."
    }

    throw "A real directory, file, or non-Junction reparse point already exists at '$linkPath'. Nothing was changed. Inspect that path manually."
}

$junction = New-Item -ItemType Junction -Path $linkPath -Target $repositoryRoot
$verifiedItem = Get-Item -LiteralPath $linkPath -Force
$verifiedReparsePoint = ($verifiedItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0

if (-not $verifiedReparsePoint -or $verifiedItem.LinkType -ne 'Junction') {
    throw "The path was created but could not be verified as a Junction: $linkPath"
}

Write-Host ''
Write-Host 'MacroStudio development Junction created.' -ForegroundColor Green
Write-Host "WoW addon: $($junction.FullName)"
Write-Host "Repository: $repositoryRoot"
Write-Host 'Changes saved in the repository are now immediately visible to WoW.'
Write-Host 'Use /reload after Lua or TOC changes.'
