<#
Build script for the Gradescope autograder. 
This script builds on the base container by adding Matlab code required to run the autograder.
Modify default variables under Param.
#>

Param(
  [string]$Base = 'ekim493/cs1371-autograder:base',
  [string]$Repo = 'ekim493/cs1371-autograder',
  [string]$Tag = 'latest',
  [string]$Source = 'cs1371',
  [Bool]$Encrypt = $true
)

# Check with user and reprompt if necessary
Write-Host "Settings:"
Write-Host "  Base Image : $Base"
Write-Host "  Repository : $Repo"
Write-Host "  Tag        : $Tag"
Write-Host "  Source Dir : $Source"
Write-Host "  Encrypt    : $Encrypt"
Write-Host
$ok = Read-Host "Continue with these settings? (Y/N)"
if ($ok -match '^[Nn]') {
  $prompt = Read-Host "Enter base image (repo:tag)"
  if ($prompt) {$Base = $prompt}

  $prompt = Read-Host "Enter new repository"
  if ($prompt) {$Repo = $prompt}

  $prompt = Read-Host "Enter new tag"
  if ($prompt) {$Tag = $prompt}

  $prompt = Read-Host "Enter source dir"
  if ($prompt) {$Source = $prompt}

  $prompt = Read-Host "Encrypt files? (Y/N)"
  if ($prompt -match '^[Yy]') {
    $Encrypt = $true
  } elseif ($prompt -match '^[Nn]') {
    $Encrypt = $false
  } else {
    Write-Error "Invalid Character(s). Please try again."
    exit 1
  }
} elseif ($ok -notmatch '^[Yy]') {
  Write-Error "Invalid Character(s). Please try again."
  exit 1
}

# Encrypt files
if ($Encrypt) {
  Write-Host "Encrypting files..."
  matlab -batch "cd('src'); encrypt('$PSScriptRoot', '$Source')"
  if ($LASTEXITCODE) { 
    Write-Error "File encryption failed."
    exit 1
  } else {
    Write-Host "Encryption successful."
  }
} else {
  Write-Host "Copying non-encrypted files..."
  Copy-Item -Path $Source -Destination temp -Recurse
  if (-not $?) {
      Write-Error "Failed to copy files."
      exit 1
  }
}

# Check if Docker is running, start it if not
if (-not (Get-Process -Name 'Docker Desktop' -ErrorAction SilentlyContinue)) {
  Write-Host "Docker is not running. Starting Docker Desktop..."
  if ($IsWindows) {
    Start-Process 'C:\Program Files\Docker\Docker\Docker Desktop.exe'
  } else {
    # macOS
    Start-Process 'open' -ArgumentList '-a Docker'
  }
  # Wait for up to 30 seconds, then time out
  $attempt = 0
  do {
    Start-Sleep -Seconds 3
    docker info > $null 2>&1
    $attempt++
  } until ($LASTEXITCODE -eq 0 -or $attempt -ge 10)
  if ($LASTEXITCODE -ne 0) {
      Write-Error "Timed out waiting for Docker to start. Ensure Docker Desktop is installed in the default location and try again."
      exit 1
  }
  Write-Host "Docker Desktop is now running."
} else {
  Write-Host "Docker Desktop is already running. Starting image build..."
}

# Build
docker build -f docker/Dockerfile.build -t ${Repo}:$Tag --platform linux/amd64 --build-arg FROM_IMAGE=$Base .
if ($LASTEXITCODE) { 
    Write-Error "Docker image build failed."
    exit 1
}
Write-Host "Docker image updated successfully. Now pushing to the web..."

# Push
docker push ${Repo}:$Tag
if ($LASTEXITCODE) { 
    Write-Error "Docker push failed."
    exit 1
}

# Clean-up
Remove-Item -Path temp -Recurse -Force

# Finished
Write-Host "The autograder has been updated successfully. Repository: ${Repo}:$Tag" -ForegroundColor Green