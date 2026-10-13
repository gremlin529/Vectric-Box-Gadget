# PowerShell Script: Update G_version and Create Release ZIP
param (
    $version = $null,
    $subversion = $null,
    $configFile = $null
)

Write-Host ""
Write-Host ""

# Load configuration (moduleToCreate, mainLuaFile, mainHTMLFile, extra files to release)
# so this script can be reused across different gadgets/projects without editing the script itself.
if (-not $configFile) {
    $configFile = Join-Path $PSScriptRoot "Release.config.json"
}

if (-not (Test-Path $configFile)) {
    Write-Error "Configuration file not found: $configFile"
    exit 1
}

try {
    $config = Get-Content -Path $configFile -Raw | ConvertFrom-Json
}
catch {
    Write-Error "Failed to parse configuration file '$configFile': $_"
    exit 1
}

foreach ($requiredField in @("ModuleToCreate", "MainLuaFile", "MainHTMLFile")) {
    if (-not $config.$requiredField) {
        Write-Error "Configuration file '$configFile' is missing required field '$requiredField'."
        exit 1
    }
}

$moduleToCreate = $config.ModuleToCreate
$mainLuaFile = $config.MainLuaFile
$mainHTMLFile = $config.MainHTMLFile

# Optionally leave the version number out of the released file names.
# Config field "AppendVersionToFileNames": true (default, or absent) stamps the
# version into the lua/htm file names and the .vgadget; false releases them as
# <ModuleToCreate>.lua / <ModuleToCreate>.htm / <ModuleToCreate>.vgadget.
$appendVersionToFileNames = $true
if ($null -ne $config.AppendVersionToFileNames) {
    if ($config.AppendVersionToFileNames -is [bool]) {
        $appendVersionToFileNames = $config.AppendVersionToFileNames
    }
    elseif ("$($config.AppendVersionToFileNames)" -match "^(false|0|no)$") {
        $appendVersionToFileNames = $false
    }
}

# manually add extra files here (in the config file), but it will automatically include the main lua
# and html file based on the config above, so no need to add those to FilesToRelease
$filesToRelease = @($mainLuaFile, $mainHTMLFile) + @($config.FilesToRelease)

# Remember the last version/subversion used, so they can be suggested next time.
$releaseVerFile = "ReleaseVer.txt"

$lastVersion = $null
$lastSubversion = $null
if (Test-Path $releaseVerFile) {
    foreach ($line in Get-Content -Path $releaseVerFile) {
        if ($line -match '^Version=(.*)$') { $lastVersion = $Matches[1] }
        elseif ($line -match '^SubVersion=(.*)$') { $lastSubversion = $Matches[1] }
    }
    if ($lastVersion) {
        Write-Host "Last release: version '$lastVersion', subversion '$lastSubversion'"
    }
}

function Save-ReleaseVer {
    param (
        [string]$filePath,
        [string]$version,
        [string]$subversion
    )
    "Version=$version", "SubVersion=$subversion" | Set-Content -Path $filePath
}

if ($version) {
    Write-Host "Version provided as argument: $version"
}
else {
    # Prompt user for new version, suggesting the last one used if there is one
    if ($lastVersion) {
        $versionInput = Read-Host "Enter the new version (e.g., 5.7) [$lastVersion]"
        $version = if ([string]::IsNullOrWhiteSpace($versionInput)) { $lastVersion } else { $versionInput }
    }
    else {
        $version = Read-Host "Enter the new version (e.g., 5.7)"
    }
    if (-not $version -match '^\d+(\.\d+)*$') {
        Write-Error "Invalid version format. Use numbers and dots only (e.g., 5.7, 6.0.1)."
        exit 1
    }
}

if ($subversion) {
    Write-Host "Subversion provided as argument: $subversion"
}
else {
    # Prompt user for subversion string - this is optional, press Enter to reuse
    # the last one used (if any), or to leave it empty if there wasn't one
    if ($lastSubversion) {
        $subversionInput = Read-Host "Enter the subversion string, or press Enter to reuse the last value (e.g., beta1, rc2) [$lastSubversion]"
        $subversion = if ([string]::IsNullOrWhiteSpace($subversionInput)) { $lastSubversion } else { $subversionInput }
    }
    else {
        $subversion = Read-Host "Enter the subversion string, or press Enter to leave empty (e.g., beta1, rc2)"
    }
}

Save-ReleaseVer -filePath $releaseVerFile -version $version -subversion $subversion

# Base name used for the released files, the staging folder and the .vgadget.
if ($appendVersionToFileNames) {
    $releaseName = $moduleToCreate + "_" + $version
}
else {
    $releaseName = $moduleToCreate
    Write-Host "AppendVersionToFileNames is false: released file names will not include the version."
}

# Release directory
$releaseDir = "release"

function UpdateVersionInLuaFile {
    param (
        [string]$filePath,
        [string]$version,
        [string]$subversion,
        [bool]$removeVersionFromHtmlName = $false
    )

    # Read file content
    $content = Get-Content -Path $filePath -Raw

    # Replace G_version = "dev"
    $versionPattern = 'G_version\s*=\s*"\s*dev\s*"'
    if ($content -match $versionPattern) {
        $content = $content -replace $versionPattern, "G_version=`"$version`""
        Write-Host "G_version updated to '$version' in '$filePath'."
    } else {
        Write-Warning "No matching G_version line found in '$filePath'. Version not updated."
        Write-Warning "Release Not Created"
        exit 1
    }

    # Replace G_subVersion = "..." with the new subversion string
    $subVersionPattern = 'G_subVersion\s*=\s*"[^"]*"'
    if ($content -match $subVersionPattern) {
        $content = $content -replace $subVersionPattern, "G_subVersion=`"$subversion`""
        Write-Host "G_subVersion updated to '$subversion' in '$filePath'."
    } else {
        Write-Warning "No matching G_subVersion line found in '$filePath'. Subversion not updated."
    }

    # The dialog HTML file name is built from G_version (e.g. "Vektor_PDF_" .. G_version .. ".htm").
    # When the released files carry no version, that reference has to lose it as well.
    if ($removeVersionFromHtmlName) {
        $htmlNamePattern = '"([^"]*)_"\s*\.\.\s*G_version\s*\.\.\s*"\.htm"'
        if ($content -match $htmlNamePattern) {
            $content = $content -replace $htmlNamePattern, '"${1}.htm"'
            Write-Host "HTML dialog file reference in '$filePath' changed to the unversioned name."
        } else {
            Write-Warning "No versioned HTML file name expression found in '$filePath'. Check that it opens the unversioned .htm file."
        }
    }

    # Write updated content back to file
    Set-Content -Path $filePath -Value $content
}

try {
    # Ensure release directory exists if not create it
    if (-not (Test-Path $releaseDir)) {
        New-Item -ItemType Directory -Path $releaseDir | Out-Null
    }

    # create directory under release and copy files there
    # note inorder for the gadget file to have the correct folder structure when unzipped, 
    # the version directory needs to be created under the release directory and then the files 
    # copied there before creating the zip file
    $releaseFileDirectory = $releaseName + "\" + $releaseName
    $versionDir = Join-Path $releaseDir $releaseFileDirectory

    Write-Host "Creating version directory at '$versionDir' and copying files..."
    if (-not (Test-Path $versionDir)) {
        Write-Host "Version directory not found. Creating '$versionDir'..."
        New-Item -ItemType Directory -Path $versionDir | Out-Null
    }

    #copy each and directory in the list to the version directory
    foreach ($item in $filesToRelease) {
        if (Test-Path $item) {
            Write-Host "Copying '$item' to '$versionDir'..."
            Copy-Item -Path $item -Destination $versionDir -Recurse -Force
        }
        else {
            Write-Warning "File or directory not found: $item (skipping copy)"
        }
    }

    Write-Host ""

    # # now update the lua file in the release directory to have the correct version number
    $luaFileInRelease = Join-Path $versionDir $mainLuaFile
    Write-Host "Updating version in '$luaFileInRelease' file in release directory to '$version'..."
    if (Test-Path $luaFileInRelease) {  
        UpdateVersionInLuaFile -filePath $luaFileInRelease -version $version -subversion $subversion -removeVersionFromHtmlName (-not $appendVersionToFileNames)
    }
    else {
        Write-Warning "Lua file not found in release directory: $luaFileInRelease (skipping version update)"
        exit 1
    }

    # now rename the lua and html file in the reslease directory with a version

    $luaFile = Join-Path $versionDir $mainLuaFile
    $luaFileVersioned = Join-Path $versionDir ($releaseName + ".lua")

    write-Host ""

    if (Test-Path $luaFile) {
        if (Test-Path $luaFileVersioned) {  
            Remove-Item $luaFileVersioned -Force
        }
        Write-Host "Renaming '$luaFile' to '$releaseName.lua'..."
        Rename-Item -Path $luaFile -NewName ($releaseName + ".lua") -Force
    }
    else {
        Write-Warning "File not found: $luaFile (skipping rename)"
    }

    $htmlFile = Join-Path $versionDir $mainHTMLFile    
    $htmlFileVersioned = Join-Path $versionDir ($releaseName + ".htm")
    if (Test-Path $htmlFile) {
        if (Test-Path $htmlFileVersioned) {  
            Remove-Item $htmlFileVersioned -Force
        }
        Write-Host "Renaming '$htmlFile' to '$releaseName.htm'..."
        Rename-Item -Path $htmlFile -NewName ($releaseName + ".htm") -Force
    }
    else {
        Write-Warning "File not found: $htmlFile (skipping rename)"
    }

    # ZIP file path, this zip file will be renamed to .vgadget after creation, but needs to be created as a zip file 
    # first in order to create it
    $zipPath = Join-Path $releaseDir ($releaseName + "_staging.zip")
    Write-Debug "Preparing to create ZIP file at '$zipPath'..."

    # Remove old ZIP if exists
    if (Test-Path $zipPath) {
        Remove-Item $zipPath -Force
    }

    #Create a zip file from the version directory incluuding all files and subdirectories
    #Note the release path looks doubled, but it needs to otherwise the gadget file
    #will not have the correct folder structure when unzipped
    $releaseTree = $releaseName
    $releasePath = Join-Path $releaseDir $releaseTree
    Write-Debug "Creating ZIP file from '$releasePath'..."
    Compress-Archive -Path (Join-Path $releasePath "*") -DestinationPath $zipPath -Force

    #Rename the zip file with a .vgadget extension
    $vgadgetPath = Join-Path $releaseDir ($releaseName + ".vgadget")
    Write-Debug "Renaming ZIP file to '$vgadgetPath'..." 
    if (Test-Path $vgadgetPath) {
        Write-Host "Versioned gadget file already exists: $vgadgetPath. Removing old versioned gadget file..."
        Remove-Item $vgadgetPath -Force
    }
    Rename-Item -Path $zipPath -NewName ($releaseName + ".vgadget") -Force

    #remove the version directory after creating the zip
    Write-Host "Removing temporary version directory '$releasePath'..."  
    Remove-Item $releasePath -Recurse -Force
    Write-Host ""
    Write-Host ""
    Write-Host "Release created successfully: $vgadgetPath"
    Write-Host ""
}
catch {
    Write-Error "An error occurred: $_"
}