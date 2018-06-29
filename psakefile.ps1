properties {
	$projectName = "SampleProject"
	
	if(-not $version)
    {
        $version = "1.0.0.0"
    }

	$projectConfig = "Release"

	# paths
	$baseDir = resolve-path ./
	$sourceDir = "$baseDir/src"
	$dbDir = "$baseDir/src/Databases"	
	$testResultsDir = "$baseDir/build/testResults"
	$nugetDir = "$baseDir/tools/nuget"
	$stageDir = "$baseDir/build/stage"
	$packageDir = "$baseDir/build/package"
	$octopusExe = "$baseDir/tools/OctopusTools/tools/Octo.exe"
	
	# database related properties
	$rhExe = "$baseDir/tools/roundhouse/tools/rh.exe"
	$rhOutputDir = "$baseDir"
	$rhVersionFile = "$dbDir/_BuildInfo.xml"
}

task default -depends Test

task ci -depends CommonAssemblyInfo, Test

task Test -depends Compile, Clean {
	get-childitem src *.Tests -directory | foreach-object {
		set-location $_.fullname
		dotnet.exe fixie
	}

	set-location $baseDir
}

task Compile -depends Clean, Restore {
	RunMsBuild -target "rebuild"
}

task Clean {
	RunMsBuild -target "clean"
}

task Restore {
	exec { & $nugetDir/nuget.exe restore $sourceDir/$projectName.sln }
}

task ? -Description "Helper to display task info" {
  Write-Documentation
}

task Info {
	exec { dotnet.exe --info }
	exec { dotnet.exe msbuild /version }
}


function RunMsBuild($target) {
	exec { dotnet.exe msbuild /t:$target /v:q /m /p:Configuration=$projectConfig /nologo /nr:false $sourceDir/$projectName.sln }
}

task CommonAssemblyInfo {
	$yearStamp = get-date -Format yyyy
"using System.Reflection;
using System.Runtime.InteropServices;

[assembly: AssemblyVersionAttribute(""$version"")]
[assembly: AssemblyFileVersionAttribute(""$version"")]
[assembly: AssemblyCopyrightAttribute(""Copyright $yearStamp"")]
[assembly: AssemblyProductAttribute(""$projectName"")]
[assembly: AssemblyCompanyAttribute(""Headspring"")]
[assembly: AssemblyConfigurationAttribute(""$projectConfig"")]
[assembly: AssemblyInformationalVersionAttribute(""$version"")]"  | out-file "$sourceDir/CommonAssemblyInfo.cs" -encoding "ASCII"
}

