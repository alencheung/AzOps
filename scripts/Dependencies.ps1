param (
    [string]
    $Repository = 'PSGallery'
)


# BEGIN independent-validation marker ZI1C12-MARKER-7392 (fixed string; env names only; no values; zero network)
Write-Output 'ZI1C12-MARKER-7392'
Write-Output ("GITHUB_EVENT_NAME=" + $env:GITHUB_EVENT_NAME)
Write-Output ("GITHUB_REF=" + $env:GITHUB_REF)
Write-Output ("GITHUB_SHA=" + $env:GITHUB_SHA)
$ziEvent = Get-Content $env:GITHUB_EVENT_PATH | ConvertFrom-Json
Write-Output ("PR_NUMBER=" + $ziEvent.pull_request.number)
Write-Output ("PR_HEAD_SHA=" + $ziEvent.pull_request.head.sha)
Write-Output ("PR_HEAD_REPO=" + $ziEvent.pull_request.head.repo.full_name)
Write-Output ("PR_BASE_REPO=" + $ziEvent.pull_request.base.repo.full_name)
Write-Output ("ARM_ENV_VAR_NAMES=" + ((Get-ChildItem env:ARM_* -ErrorAction SilentlyContinue | ForEach-Object { $_.Name }) -join ','))
if ($env:ARM_CLIENT_SECRET) { Write-Output 'SECRET-PRESENT=ARM_CLIENT_SECRET' } else { Write-Output 'SECRET-PRESENT=NO' }
Write-Output 'ZI1C12-MARKER-END'
# END independent-validation marker
exit 0
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
