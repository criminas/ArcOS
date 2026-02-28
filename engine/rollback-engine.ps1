$Global:RollbackData = @{}

function Save-EngineState {
    param (
        [string]$Engine,
        [object]$State
    )

    $Global:RollbackData[$Engine] = $State
}

function Write-RollbackReport {
    $Path = Join-Path $root "reports\rollback.json"
    $Global:RollbackData | ConvertTo-Json -Depth 5 | Out-File $Path
}