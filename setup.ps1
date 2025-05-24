<#
Setup script for the Gradescope autograder. 
This script builds a Docker container with Matlab installed and logged in.
Modify default variables under Param.
#>

Param(
  [string]$Repo = 'ekim493/cs1371-autograder:base',
  [switch]$SkipInstall
  )

# Prompt
if (-not $SkipInstall) {
  $prompt = Read-Host -Prompt "Press ENTER to continue with Matlab installation or type N to skip"
  if ($prompt -match '^[Nn]') {
    $SkipInstall = $true
    Write-Host "Pulling from base repositiory $Repo"
    $prompt = Read-Host -Prompt "Press ENTER to continue or type new repository and tag"
    if ($prompt) {$Repo = $prompt}
  } elseif ($prompt) {
    Write-Error "Invalid Character(s). Please try again."
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

# Build the Docker Image
if (-not $SkipInstall) {
  docker build -f docker/Dockerfile.setup -t $Repo --platform linux/amd64 --no-cache .
  if ($LASTEXITCODE -ne 0) {
    Write-Error "Docker image build failed."
    exit 1
  }
} else {
  Write-Host "Skipping image build. Pulling latest image instead..."
  docker pull $Repo
  if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to pull base repository $Repo"
    exit 1
  }
}

# Run container for MATLAB login
Write-Host "Running container to login to MATLAB…"
$name = "autograder-$(Get-Random)"
docker run -it -v .:/autograder/submission -v .:/autograder/results --platform linux/amd64 --name $name $Repo matlab -licmode onlinelicensing -batch quit
if ($LASTEXITCODE -ne 0) {
  Write-Error "Docker run or Matlab login failed."
  exit 1
}

# Get container ID and commit changes
Write-Host "Matlab login successful. Now committing the Docker container…"
docker commit $name $Repo
if ($LASTEXITCODE -ne 0) {
  Write-Error "Docker commit failed."
  exit 1
} else {
  Write-Host "Container committed successfully."
}

# Push to web and cleanup
if (-not $SkipInstall) {
  Write-Host "Pushing to repositiory $Repo"
  $prompt = Read-Host -Prompt "Press ENTER to continue or type new repository and tag"
  if ($prompt) {$NewRepo = $prompt} else {$NewRepo = $Repo}
  docker push $NewRepo
  if ($LASTEXITCODE -ne 0) {
    Write-Error "Docker push failed."
    exit 1
  }
  # Cleanup
  Write-Host "Docker push successful. Cleaning docker container..."
  docker rm $name -f
  Write-Host "Docker setup complete. Repository: $NewRepo" -ForegroundColor Green
}