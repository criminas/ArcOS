# =====================================================
# Risk Tier Ordering
# =====================================================

$RiskOrder = @{
    "Stable"       = 1
    "Performance"  = 2
    "Minimal"      = 3
    "Experimental" = 4
}

# =====================================================
# Playbook Executor
# =====================================================

function Invoke-Playbook {
    param (
        [Parameter(Mandatory)]
        [string]$PlaybookPath,

        [string]$Profile = "Stable"
    )

    if (-not (Test-Path $PlaybookPath)) {
        Write-ArcLog "Playbook not found: $PlaybookPath" "ERROR"
        return
    }

    if (-not $root) {
        Write-ArcLog "Root path not initialized." "ERROR"
        return
    }

    $ManifestPath = Join-Path $root "engine\engine.manifest.json"

    if (-not (Test-Path $ManifestPath)) {
        Write-ArcLog "Engine manifest missing." "ERROR"
        return
    }

    try {
        $Manifest = Get-Content $ManifestPath -Raw | ConvertFrom-Json
        $Playbook = Get-Content $PlaybookPath -Raw | ConvertFrom-Json
    }
    catch {
        Write-ArcLog "Failed to parse manifest or playbook JSON." "ERROR"
        return
    }

    if (-not $RiskOrder.ContainsKey($Profile)) {
        Write-ArcLog "Invalid profile: $Profile" "ERROR"
        return
    }

    Write-ArcLog "Executing playbook: $($Playbook.name)"
    Write-ArcLog "Profile level: $Profile"
    Write-ArcLog "Windows build: $Global:CurrentBuild"

    foreach ($Engine in $Playbook.engines) {

        if (-not $Manifest.PSObject.Properties.Name.Contains($Engine)) {
            Write-ArcLog "$Engine missing metadata." "WARN"
            continue
        }

        $Meta = $Manifest.$Engine

        # Build validation
        if ($Global:CurrentBuild -lt $Meta.minBuild) {
            Write-ArcLog "$Engine skipped (unsupported build)." "WARN"
            continue
        }

        # Risk validation
        if ($RiskOrder[$Meta.risk] -gt $RiskOrder[$Profile]) {
            Write-ArcLog "$Engine skipped (risk tier)." "INFO"
            continue
        }

        $FunctionName = "Invoke-$Engine"

        if (-not (Get-Command $FunctionName -ErrorAction SilentlyContinue)) {
            Write-ArcLog "$FunctionName not found." "ERROR"
            continue
        }

        try {
            Write-ArcLog "Executing $Engine"
            & $FunctionName
            Write-ArcLog "$Engine completed."
        }
        catch {
            Write-ArcLog "$Engine failed: $($_.Exception.Message)" "ERROR"
        }
    }

    Write-ArcLog "Playbook execution complete."
}