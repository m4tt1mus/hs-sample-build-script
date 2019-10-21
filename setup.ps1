# Setup the environment to use PSAKE if not ready (run this once)

# set PSGallery as trusted so we can install packages from there
Write-Host 'Trusting PS Gallery'
Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted

# Install PSAKE
# Note: 4.7.4 is used for now, 4.8.0 has some bugs and incompatibilities
Write-Host 'Installing PSake'
Install-Module -Name psake -MaximumVersion 4.7.4 -Scope CurrentUser -Force

# Install NuGet based tools
# Write-Host 'Installing NuGet Tools'
# tools/nuget/nuget install tools/packages.config -ExcludeVersion -OutputDirectory tools

# Install dotnet based tools
Write-Host 'Install dotnet tools'
dotnet tool update dotnet-format -g
dotnet tool install dotnet-format -g
