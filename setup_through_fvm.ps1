$ErrorActionPreference = "Stop"

function Invoke-Step {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Title,

        [Parameter(Mandatory = $true)]
        [scriptblock] $Command
    )

    Write-Host ""
    Write-Host "==> $Title"
    & $Command

    if ($LASTEXITCODE -ne 0) {
        throw "Step failed: $Title"
    }
}

Invoke-Step "Using Flutter 3.41.6 through FVM" {
    fvm use 3.41.6
}

Invoke-Step "Setting Flutter 3.41.6 as global FVM version" {
    fvm global 3.41.6
}

Invoke-Step "Cleaning Flutter project" {
    fvm flutter clean
}

Write-Host ""
Write-Host "==> Removing generated files (*.g.dart, *.mocks.dart)"
Get-ChildItem -Path "lib" -Recurse -Filter "*.g.dart" -File -ErrorAction SilentlyContinue | Remove-Item -Force
Get-ChildItem -Path "test" -Recurse -Filter "*.mocks.dart" -File -ErrorAction SilentlyContinue | Remove-Item -Force

Invoke-Step "Getting Flutter dependencies" {
    fvm flutter pub get
}

Invoke-Step "Cleaning build_runner" {
    fvm dart run build_runner clean
}

Invoke-Step "Building generated files" {
    fvm dart run build_runner build --delete-conflicting-outputs
}

Write-Host ""
Write-Host "Setup through FVM completed."
