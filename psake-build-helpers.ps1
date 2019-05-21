
function project-properties {
    $copyright = $(get-copyright)

    write-host "$product $version"
    write-host $copyright

    regenerate-file "$pwd/Directory.Build.props" @"
<Project>
    <PropertyGroup>
        <Product>$product</Product>
        <Version>$version</Version>
        <Copyright>$copyright</Copyright>
        <LangVersion>latest</LangVersion>
    </PropertyGroup>
</Project>
"@
}

function get-copyright {
    $date = Get-Date
    $year = $date.Year
    $copyrightSpan = if ($year -eq $yearInitiated) { $year } else { "$yearInitiated-$year" }
    return "© $copyrightSpan $owner"
}

function publish-project {
    $project = Split-Path $pwd -Leaf
    Write-Host "Publishing $project"
    dotnet publish --configuration $configuration --no-restore --output $publish/$project /nologo
}

function regenerate-file($path, $newContent) {
    if (-not (test-path $path -PathType Leaf)) {
        $oldContent = $null
    } else {
        $oldContent = [IO.File]::ReadAllText($path)
    }

    if ($newContent -ne $oldContent) {
        write-host "Generating $path"
        [System.IO.File]::WriteAllText($path, $newContent, [System.Text.Encoding]::UTF8)
    }
}

function delete-directory($path) {
    if (test-path $path) {
        write-host "Deleting $path"
        Remove-Item $path -recurse -force -ErrorAction SilentlyContinue | out-null
    }
}

function find-dependency($name) {
    $exes = @(gci packages -rec -filter $name)

    if ($exes.Length -ne 1) {
        throw "Expected to find 1 $name, but found $($exes.Length)."
    }

    return $exes[0].FullName
}

function connection-string($environmentVariablePrefix, $appsettingsPath) {
    $environmentVariableName = "$($environmentVariablePrefix):Database:ConnectionString"

    if (test-path env:$environmentVariableName) {
        return (get-item env:$environmentVariableName).Value
    }

    return (get-content $appsettingsPath | out-string | convertfrom-json).Database.ConnectionString
}

function update-database([Parameter(ValueFromRemainingArguments)]$environments) {
    $migrationsProject =  (get-item -path .).Name
    $roundhouseExePath = find-dependency rh.exe
    $roundhouseOutputDir = [System.IO.Path]::GetDirectoryName($roundhouseExePath) + "\output"

    $migrationScriptsPath ="Scripts"
    $roundhouseVersionFile = "bin\$configuration\$targetFramework\$migrationsProject.dll"

    foreach ($environment in $environments) {
        $connectionString = $connectionStrings[$environment]

        write-host "Executing RoundhousE for environment:" $environment

        execute { & $roundhouseExePath --connectionstring $connectionString `
                                       --commandtimeout 300 `
                                       --env $environment `
                                       --output $roundhouseOutputDir `
                                       --sqlfilesdirectory $migrationScriptsPath `
                                       --versionfile $roundhouseVersionFile `
                                       --transaction `
                                       --silent }
    }
}

function rebuild-database([Parameter(ValueFromRemainingArguments)]$environments) {
    $migrationsProject = (get-item -path .).Name
    $roundhouseExePath = find-dependency rh.exe
    $roundhouseOutputDir = [System.IO.Path]::GetDirectoryName($roundhouseExePath) + "\output"

    $migrationScriptsPath ="Scripts"
    $roundhouseVersionFile = "bin\$configuration\$targetFramework\$migrationsProject.dll"

    foreach ($environment in $environments) {
        $connectionString = $connectionStrings[$environment]

        write-host "Executing RoundhousE for environment:" $environment

        execute { & $roundhouseExePath --connectionstring $connectionString `
                                       --commandtimeout 300 `
                                       --env $environment `
                                       --output $roundhouseOutputDir `
                                       --silent `
                                       --drop }

        execute { & $roundhouseExePath --connectionstring $connectionString `
                                       --commandtimeout 300 `
                                       --env $environment `
                                       --output $roundhouseOutputDir `
                                       --sqlfilesdirectory $migrationScriptsPath `
                                       --versionfile $roundhouseVersionFile `
                                       --transaction `
                                       --silent `
                                       --simple }
    }
}

function start-mysql-container($containerName, $mySqlPort = 23306) {
    $portSub = "$($mySqlPort):3306"
    docker run --name $containerName -e MYSQL_ROOT_PASSWORD=root -e MYSQL_DATABASE=skfdata -d -p $portSub mysql:5 --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Docker container created failed."
    }
}

function stop-mysql-container($containerName) {
    docker stop $containerName
    docker rm $containerName
}

function wait-for-mysql-container($containerName) {
    $mysqlIsReady = $FALSE

    for ($count = 0; ($count -lt 10) -and (-not $mysqlIsReady); $count++) {
        Start-Sleep -Seconds 5
        docker exec $containerName mysql --user=root --password=root -e "SELECT 1"
        $mysqlIsReady = $LASTEXITCODE -eq 0
    }

    return $mysqlIsReady
}
