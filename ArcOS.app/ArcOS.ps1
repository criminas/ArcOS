Add-Type -AssemblyName PresentationFramework

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$xamlPath = Join-Path $root "ArcOS.xaml"

[xml]$xaml = Get-Content $xamlPath
$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

$ProfileBox = $window.FindName("ProfileBox")
$RunButton  = $window.FindName("RunButton")
$ExitButton = $window.FindName("ExitButton")
$LogBox     = $window.FindName("LogBox")

function Write-GuiLog {
    param($Message)
    $LogBox.AppendText("$Message`r`n")
    $LogBox.ScrollToEnd()
}

$RunButton.Add_Click({

    $selected = $ProfileBox.SelectedItem.Content.ToLower()

    Write-GuiLog "Starting ArcOS with profile: $selected"

    $mainScript = Join-Path (Split-Path $root -Parent) "main.ps1"

    Start-Process powershell `
        -ArgumentList "-ExecutionPolicy Bypass -File `"$mainScript`"" `
        -Verb RunAs `
        -Environment @{"ARCOS_PROFILE"=$selected}
})

$ExitButton.Add_Click({ $window.Close() })

$window.ShowDialog() | Out-Null