@echo off
REM Default repo and tags. Edit if necessary
set defaultRepoName=ekim493/cs1371-autograder
set defaultCustomTag=latest

REM Prompt user for repoName
echo Default DockerHub repository and tag: %defaultRepoName%:%defaultCustomTag%
set /p repoName="Enter DockerHub repository name (press enter to use default): "
if "%repoName%"=="" (
    set repoName=%defaultRepoName%
)

REM Prompt user for customTag
set /p customTag="Enter custom tag for the image (press enter to use default): "
if "%customTag%"=="" (
    set customTag=%defaultCustomTag%
)

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
docker build . -f Dockerfile/Dockerfile.build -t %repoName%:%customTag%
if %ERRORLEVEL% neq 0 (
    echo Docker image build failed.
    pause
    exit /b 1
) else (
    echo Docker image built successfully. Now running the container...
)

REM Run the Docker container & prompt Matlab login
docker run -it -v /source/submit:/autograder/submission -v /source:/autograder/results %repoName%:%customTag% matlab -licmode onlinelicensing -batch quit
if %ERRORLEVEL% neq 0 (
    echo Docker run or Matlab login failed.
    pause
    exit /b 1
) else (
    echo Matlab login successful. Now committing the Docker container...
)

REM Get the container ID
for /f "tokens=*" %%i in ('docker ps -l -q') do set containerId=%%i

REM Commit the container changes
docker commit %containerId% %repoName%:%customTag%
if %ERRORLEVEL% neq 0 (
    echo Docker commit failed.
    pause
    exit /b 1
) else (
    echo Container committed successfully. Now pushing the Docker container to web...
)

REM Push the image to Docker Hub
docker push %repoName%:%customTag%
if %ERRORLEVEL% neq 0 (
    echo Docker push failed.
    pause
    exit /b 1
) else (
    echo Image pushed to Docker Hub successfully. Now clearing the container...
)
docker container prune -f
echo Autograder setup complete. Repository: %repoName%:%customTag%
pause
