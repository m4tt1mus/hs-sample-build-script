include "./build-helpers.ps1"

properties {
    $configuration = 'Release'
    $testResults = 'TestResults'
    $baseVersion = '2.0'
    $buildNumber = ''
    $owner = 'Headspring'
    $product = 'Sample Build Scripts'
    $yearInitiated = '2018'
}

exec { dotnet --info }
  
task default -depends Test

task Test -depends Compile, Clean {
    $testResultsPath = "$(resolve-path .)/$testResults" 
    get-childitem . src/*.Tests -directory | foreach-object {
        exec { dotnet fixie --configuration $configuration --no-build --report "$testResultsPath/$($_.name).xml" } -workingDirectory $_.fullname
    }
}
  
task Compile -depends Clean {
    exec { project-properties $baseVersion $buildNumber $product $owner } -workingDirectory src
    exec { dotnet build --configuration $configuration --no-restore /nologo } -workingDirectory src
}
  
task Clean {
    exec { dotnet clean --configuration $configuration /nologo } -workingDirectory src
}
  
task ? -Description "Helper to display task info" {
    Write-Documentation
}
  