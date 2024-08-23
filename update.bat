@echo off
REM Defaults. Edit if necessary
set baseDir=ekim493/cs1371-autograder:stable
set repoName=ekim493/cs1371-autograder

REM Prompt user for customTag
set /p customTag="Enter a tag for the image: "
if "%customTag%"=="" (
    set customTag=latest
)

echo Pulling from repository %baseDir% and updating to %repoName%:%customTag%

REM Default Docker execution location
set dockerExePath="C:\Program Files\Docker\Docker\Docker Desktop.exe"  

REM Check if Docker Desktop is running, start it if not
tasklist /FI "IMAGENAME eq Docker Desktop.exe" 2>NUL | find /I "Docker Desktop.exe" >NUL
if %ERRORLEVEL% neq 0 (
    echo Docker Desktop is not running. Starting Docker Desktop...
    start "" %dockerExePath%
    echo Waiting for Docker to start...

    :waitForDocker
    docker info >NUL 2>&1
    if %ERRORLEVEL% neq 0 (
        echo Docker is still starting...
        timeout /t 5 /nobreak >NUL
        goto waitForDocker
    )
    echo Docker is now running.
) else (
    echo Docker Desktop is already running.
)

REM Build the Docker image
docker build . -f Dockerfile/Dockerfile.update -t %repoName%:%customTag% --build-arg FROM_IMAGE=%baseDir%
if %ERRORLEVEL% neq 0 (
    echo Docker image build failed.
    pause
    exit /b 1
) else (
    echo Docker image updated successfully. Now pushing to the web...
)

REM Push the image to Docker Hub
docker push %repoName%:%customTag%
if %ERRORLEVEL% neq 0 (
    echo Docker push failed.
    pause
    exit /b 1
) else (
    echo Image pushed to Docker Hub successfully.
)

echo The autograder has been updated successfully. Repository: %repoName%:%customTag%
pause
