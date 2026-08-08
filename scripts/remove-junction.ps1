[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$AddOnsPath
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $AddOnsPath -PathType Container)) {
    throw "The supplied AddOns directory does not exist: $AddOnsPath"
}

$resolvedAddOnsPath = (Resolve-Path -LiteralPath $AddOnsPath).Path
$linkPath = Join-Path $resolvedAddOnsPath 'MacroStudio'
$item = Get-Item -LiteralPath $linkPath -Force -ErrorAction SilentlyContinue

if ($null -eq $item) {
    Write-Host "No MacroStudio path exists at: $linkPath"
    return
}

$isReparsePoint = ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0
if (-not $isReparsePoint -or $item.LinkType -ne 'Junction') {
    throw "Refusing to remove '$linkPath' because it is not a filesystem Junction. Inspect it manually."
}

$targets = @($item.Target)
Write-Host "Verified Junction: $linkPath"
Write-Host "Target: $($targets -join ', ')"

if ($PSCmdlet.ShouldProcess($linkPath, 'Remove the MacroStudio Junction only')) {
    # Directory.Delete with recursive=false removes the verified reparse point
    # itself. It does not enumerate or delete anything in the Junction target.
    [System.IO.Directory]::Delete($linkPath, $false)
}

if (Get-Item -LiteralPath $linkPath -Force -ErrorAction SilentlyContinue) {
    throw "The Junction still exists after the removal attempt: $linkPath"
}

Write-Host 'MacroStudio Junction removed.' -ForegroundColor Green
Write-Host 'The repository target was not removed or altered.'
