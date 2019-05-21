include "./psake-build-helpers.ps1"

properties {
    $configuration = 'Release'
    $version = '1.0.999'
    $owner = 'Headspring'
    $product = 'Sample Build Script Application'
    $yearInitiated = '2018'
    $projectRootDirectory = "$(resolve-path .)"
    $publish = "$projectRootDirectory/Publish"
    $testResults = "$projectRootDirectory/TestResults"
}

exec {
    if ($env:GITVERSION_SEMVER) {
        properties {
            $version = $env:GITVERSION_SEMVER
        }
    }
}

exec { dotnet --info }
  
task default -depends Test, Migrate
task CI -depends Clean, Test, Publish -description "Continuous Integration process"
task Rebuild -depends Clean, Compile -description "Rebuild the code and database, no testing"

task Test -depends Compile -description "Run unit tests" {
    get-childitem . src/*.Tests -directory | foreach-object {
        exec { dotnet fixie --configuration $configuration --no-build --report "$testResults/$($_.name).xml" } -workingDirectory $_.fullname
    }
}
  
task Compile -description "Compile the solution" {
    exec { project-properties } -workingDirectory src
    exec { dotnet build --configuration $configuration /nologo } -workingDirectory src
}

task Publish -depends Compile -description "Publish the primary projects for distribution" {
    delete-directory $publish
    exec { publish-project } -workingDirectory src/Sample1.NetCore
}
  
task Clean -description "Clean out all the binary folders" {
    exec { dotnet clean --configuration $configuration /nologo } -workingDirectory src
}
  
task ? -alias help -description "Display help content and possible targets" {
    WriteDocumentation
}
