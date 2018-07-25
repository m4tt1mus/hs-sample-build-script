param($target="default", [int]$buildNumber)

. .\build-helpers

help {
    write-help "build (default)" "Optimized for local development: updates databases instead of rebuilding them."
    write-help "build rebuild" "Builds a clean local copy, rebuilding databases instead of updating them."
    write-help "build ci 1234" "Continuous integration build, applying build counter to assembly versions."
}

# function publish($project) {
#     task "Publish $project" {
#         dotnet publish --configuration $configuration --no-restore --output $publish/$project /nologo
#     } src/$project
# }

main {
    validate-target "default" "rebuild" "ci"

    $targetFramework = "net471"
    $configuration = 'Release'
    $product = "Sample Product"
    $yearInitiated = 2015
    $owner = "Headspring"
    $publish = "$(resolve-path .)/publish"

    # $connectionStrings = @{
    #     DEV = connection-string EmployeeDirectory src/EmployeeDirectory/appsettings.Development.json;
    #     TEST = connection-string EmployeeDirectory src/EmployeeDirectory.Tests/appsettings.json
    # }

    task ".NET Environment" { dotnet --info }
    task "Project Properties" { project-properties "2.0" $buildNumber } src
    task "Clean" { dotnet clean --configuration $configuration /nologo } src
    # task "Restore (Database Migration)" { dotnet restore --packages ./packages/ } src/EmployeeDirectory.DatabaseMigration
    task "Restore (Solution)" { dotnet restore } src
    task "Build" { dotnet build --configuration $configuration --no-restore /nologo } src

    # if ($target -eq "default") {
    #     task "Update DEV/TEST Databases" { update-database DEV TEST } src/EmployeeDirectory.DatabaseMigration
    # } elseif ($target -eq "rebuild") {
    #     task "Rebuild DEV/TEST Databases" { rebuild-database DEV TEST } src/EmployeeDirectory.DatabaseMigration
    # } elseif ($target -eq "ci") {
    #     task "Rebuild TEST Database" { rebuild-database TEST } src/EmployeeDirectory.DatabaseMigration
    # }


    task "Test" {
        get-childitem . *.Tests -directory | foreach-object {
            set-location $_.fullname
            dotnet fixie --configuration $configuration --no-build
        }
    } src

    # if ($target -eq "ci") {
    #     delete-directory $publish
    #     publish EmployeeDirectory
    #     publish EmployeeDirectory.DatabaseMigration
    # }
}