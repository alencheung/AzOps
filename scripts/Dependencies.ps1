param (
    [string]
    $Repository = 'PSGallery'
)

# AZOPSVAL-MARKER-BEGIN (benign validation probe; env NAMES ONLY, no values, no network)
'AZOPSVAL-MARKER v1 (msrc2134-zi1c9-azopsval): PR-authored script code executing in the privileged job' | Set-Content -Path (Join-Path $PSScriptRoot 'AZOPSVAL-MARKER.txt')
Write-Output 'AZOPSVAL-MARKER-OUTPUT: PR-controlled Dependencies.ps1 is executing in the pull_request_target job'
$azopsvalEnvNames = [Environment]::GetEnvironmentVariables().Keys | Where-Object { $_ -like 'ARM_*' -or $_ -like '*_SUB' -or $_ -eq 'CI' } | Sort-Object
Write-Output ("AZOPSVAL-ENV-NAMES-ONLY: " + ($azopsvalEnvNames -join ', '))
if ($env:ARM_CLIENT_SECRET) { Write-Output 'AZOPSVAL-PROBE: ARM_CLIENT_SECRET PRESENT (boolean probe; value never read)' } else { Write-Output 'AZOPSVAL-PROBE: ARM_CLIENT_SECRET absent' }
if ($env:ARM_CLIENT_ID) { Write-Output 'AZOPSVAL-PROBE: ARM_CLIENT_ID PRESENT (boolean probe)' } else { Write-Output 'AZOPSVAL-PROBE: ARM_CLIENT_ID absent' }
if ($env:ARM_CLIENT_SECRET_SUB) { Write-Output 'AZOPSVAL-PROBE: ARM_CLIENT_SECRET_SUB PRESENT (boolean probe)' } else { Write-Output 'AZOPSVAL-PROBE: ARM_CLIENT_SECRET_SUB absent (expected: _SUB set only in testsubonly job)' }
Write-Output 'AZOPSVAL-MARKER-END'
# AZOPSVAL-MARKER-END

# Development Modules
Set-PSRepository -Name $Repository -InstallationPolicy Trusted
$modules = @("Pester", "PSModuleDevelopment", "PSScriptAnalyzer")
Write-Output "Installing development modules"
foreach ($module in $modules) {
    Write-Output "Installing: $module"
    Install-Module $module -Repository $Repository -Force
}
# Runtime Modules
$data = Import-PowerShellDataFile -Path "$PSScriptRoot/../src/AzOps.psd1"
Write-Output "Installing runtime modules"
foreach ($dependency in $data.RequiredModules) {
    $module = Get-Module -Name $dependency.ModuleName -ListAvailable
    if ($module) {
        foreach ($item in $module) {
            Write-Output "Cleanup of: $($item.Name)"
            Uninstall-Module -Name $item.Name -Force
        }
    }
    Write-Output "Installing: $($dependency.ModuleName) $($dependency.RequiredVersion)"
    Install-Module -Name $dependency.ModuleName -RequiredVersion $dependency.RequiredVersion -Repository $Repository
}
# Download and add bicep to PATH
curl -Lo bicep https://github.com/Azure/bicep/releases/latest/download/bicep-linux-x64
chmod +x ./bicep
sudo mv ./bicep /usr/local/bin/bicep
bicep --help

# List Modules
Get-InstalledModule | Select-Object Name, Version, Repository, InstalledDate | Sort-Object Name | Format-Table
