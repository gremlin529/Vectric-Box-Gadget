# PowerShell Script: Update g_version and Create Release ZIP
param (
    $version = $null,
    $subversion = $null
)

Write-Host ""
Write-Host ""

if ($version) {
    Write-Host "Version provided as argument: $version"
}
else {
    # Prompt user for new version
    $version = Read-Host "Enter the new version (e.g., 5.7)"
    if (-not $version -match '^\d+(\.\d+)*$') {
        Write-Error "Invalid version format. Use numbers and dots only (e.g., 5.7, 6.0.1)."
        exit 1
    }
}

if ($subversion) {
    Write-Host "Subversion provided as argument: $subversion"
}
else {
    # Prompt user for subversion string - this is optional, press Enter to leave empty
    $subversion = Read-Host "Enter the subversion string, or press Enter to leave empty (e.g., beta1, rc2)"
}

# Files to include in the release ZIP (relative or absolute paths)
$filesToRelease = @(
    "box_creator_ver_dev.lua",
    "box_creator_ver_dev.html",
    "stylesheets",
    "images"
)

# Release directory
$releaseDir = "release"

function UpdateVersionInLuaFile {
    param (
        [string]$filePath,
        [string]$version,
        [string]$subversion
    )       

    # Read file content
    $content = Get-Content -Path $filePath -Raw

    # Replace g_version = "dev"
    $versionPattern = 'g_version\s*=\s*"\s*dev\s*"'
    if ($content -match $versionPattern) {
        $content = $content -replace $versionPattern, "g_version=`"$version`""
        Write-Host "g_version updated to '$version' in '$filePath'."
    } else {
        Write-Warning "No matching g_version line found in '$filePath'. Version not updated."
        Write-Warning "Release Not Created"
        exit 1
    }

    # Replace g_subVersion = "..." with the new subversion string
    $subVersionPattern = 'g_subVersion\s*=\s*"[^"]*"'
    if ($content -match $subVersionPattern) {
        $content = $content -replace $subVersionPattern, "g_subVersion=`"$subversion`""
        Write-Host "g_subVersion updated to '$subversion' in '$filePath'."
    } else {
        Write-Warning "No matching g_subVersion line found in '$filePath'. Subversion not updated."
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
    $releaseFileDirectory = "Box_Creator_Ver_" + $version + "\Box_Creator_Ver_" + $version
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
    $luaFileInRelease = Join-Path $versionDir "Box_Creator_Ver_dev.lua"
    Write-Host "Updating version in '$luaFileInRelease' file in release directory to '$version'..."
    if (Test-Path $luaFileInRelease) {  
        UpdateVersionInLuaFile -filePath $luaFileInRelease -version $version -subversion $subversion
    }
    else {
        Write-Warning "Lua file not found in release directory: $luaFileInRelease (skipping version update)"
        exit 1
    }

    # now rename the lua and html file in the reslease directory with a version

    $luaFile = Join-Path $versionDir "box_creator_ver_dev.lua"
    $luaFileVersioned = Join-Path $versionDir ("Box_Creator_Ver_" + $version + ".lua")

    write-Host ""

    if (Test-Path $luaFile) {
        if (Test-Path $luaFileVersioned) {  
            Remove-Item $luaFileVersioned -Force
        }
        Write-Host "Renaming '$luaFile' to 'Box_Creator_Ver_$version.lua'..."
        Rename-Item -Path $luaFile -NewName ("Box_Creator_Ver_" + $version + ".lua") -Force
    }
    else {
        Write-Warning "File not found: $luaFile (skipping rename)"
    }

    $htmlFile = Join-Path $versionDir "box_creator_ver_dev.html"    
    $htmlFileVersioned = Join-Path $versionDir ("Box_Creator_Ver_" + $version + ".html")
    if (Test-Path $htmlFile) {
        if (Test-Path $htmlFileVersioned) {  
            Remove-Item $htmlFileVersioned -Force
        }
        Write-Host "Renaming '$htmlFile' to 'Box_Creator_Ver_$version.html'..."
        Rename-Item -Path $htmlFile -NewName ("Box_Creator_Ver_" + $version + ".html") -Force
    }
    else {
        Write-Warning "File not found: $htmlFile (skipping rename)"
    }

    # ZIP file path, this zip file will be renamed to .vgadget after creation, but needs to be created as a zip file 
    # first in order to create it
    $zipPath = Join-Path $releaseDir ("\Box_Creator_Ver_" + $version + ".zip")
    Write-Debug "Preparing to create ZIP file at '$zipPath'..."

    # Remove old ZIP if exists
    if (Test-Path $zipPath) {
        Remove-Item $zipPath -Force
    }

    #Create a zip file from the version directory incluuding all files and subdirectories
    #Note the release path looks doubled, but it needs to otherwise the gadget file
    #will not have the correct folder structure when unzipped
    $releaseTree = "Box_Creator_Ver_" + $version 
    $releasePath = Join-Path $releaseDir $releaseTree
    Write-Debug "Creating ZIP file from '$releasePath'..."
    Compress-Archive -Path (Join-Path $releasePath "*") -DestinationPath $zipPath -Force

    #Rename the zip file with a .vgadget extension
    $vgadgetPath = Join-Path $releaseDir ("\Box_Creator_Ver_" + $version + ".vgadget")
    Write-Debug "Renaming ZIP file to '$vgadgetPath'..." 
    if (Test-Path $vgadgetPath) {
        Write-Host "Versioned gadget file already exists: $vgadgetPath. Removing old versioned gadget file..."
        Remove-Item $vgadgetPath -Force
    }
    Rename-Item -Path $zipPath -NewName ("Box_Creator_Ver_" + $version + ".vgadget") -Force

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