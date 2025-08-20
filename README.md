# CS1371-autograder
The Gradescope autograder for CS1371. 

This repository contains files to setup and run the Gradescope autograder for Georgia Tech's CS1371 class. It supports testing various problem types including function outputs, plots, images, and text files. Other features include infinite loop timeouts, function call restrictions, customizable point distribution, image comparisons, and more.

Contact [Eric Kim](mailto:ekim493@gatech.edu) for questions or comments.
## Getting Started
### Requirements
1. The [Gradescope Autograder](https://gradescope-autograders.readthedocs.io/en/latest/) works by pulling a Docker image from Docker hub. Currently, the Docker is hosted by me at [ekim493/cs1371-autograder](https://hub.docker.com/r/ekim493/cs1371-autograder). To follow these instructions on your own, create a [Docker Hub](https://hub.docker.com) account, then create your own Docker Hub repository.
2. The setup scripts require Powershell 6+ to run. It is avaiable on Windows by default and can be installed for MacOS through Homebrew.
3. Docker Desktop must be installed in the default location and logged in. Matlab must also be installed and be executable through your search PATH.
4. Follow the setup instructions to create a source folder containing solution codes and testers for the autograder.

### Setup
See the [setup.md](setup.md) file for a comprensive overview on how to setup the autograder. See the [examples](examples/) folder for an example.
- All assignments should be organized into folders where the name of the folder is the same as the gradescope assignment.
- All solutions codes should be name `FUNCTION_soln.m`, where `FUNCTION` is replaced with the name of the function.
- The name of the tester should be the the gradescope assignment name + 'Tester.m'.
    - Example: For a gradescope assignment called `HW0`, the tester file should be called `HW0Tester.m`.

### Image Build
- Clone this Github repository.
- *Optional*: Run the `setup.ps1` script. See the advanced usage section below for more info.
- Run the `build.ps1` script. To run a Powershell script, open a Powershell terminal, navigate to the directory with the script, and run `.\build.ps1`. You can override the default parameters for `base`, `repo`, `tag`, `source`, and `encrypt`. To do this, either specify the parameters when executing the script (ex: `.\build.ps1 -source myfolder -tag HW01`), or run the script and follow the prompts to manually configure these values.
    - The `base` parameter is the name of the repository and tag of the Docker image with Matlab installed. Use the default value or enter the repo:tag used in the `setup.ps1` script. The default is `ekim493/cs1371-autograder:base` with Matlab version `2024b`. 
    - The `repo` parameter is the name of the new repository that the script will push to. This should be the same name as the repository you created in Docker Hub. The default is `ekim493/cs1371-autograder`.
    - The `tag` parameter is the name of an identifier to distinguish different images. This can be anything. Note that using the same tag will override previous versions. The default is `latest`.
    - The `source` parameter is the name of the source folder created during autograder setup. This folder should contain other folders named after the Gradescope assignment and contain the solution codes and testers for the autograder. The default is `cs1371`. 
    - The `encrypt` parameter is a boolean value on whether to encrypt the source folder. The default is `$true`.

- In gradescope, go to the 'Configure Autograder' tab, select 'Manual Docker configuration', and then type in the docker Hub repository and tag. For example, `ekim493/cs1371-autograder:latest`.
    - Make sure the Docker hub repository is public. NOTE: Making it public will allow all files to be visible online. To prevent this, either make the Docker private and add `gradescopeecs` as a collaborator (requires Pro account) or ensure encryption is set to true.
    - If you run into a "sign-in failed" message, see section on running the setup file below.

## Advanced Usage
### Running the Setup File
The `setup.ps1` file creates a Docker image compatible with Gradescope and with Matlab installed and logged in. This file can be used to troubleshoot login issues and to update Matlab/linux if necessary. This script will prompt you for your Mathworks email and a one-time password. 
- If you see a "sign-in failed" message on Gradescope, you may need to re-login to Matlab. To run the script without re-installing Matlab, use the `SkipInstall` tag or follow the prompt after running the script normally.
- To change Matlab versions, modify the `MATLAB_RELEASE` argument at the top of the `docker/Dockerfile.setup` script. In addition, modify the list of Matlab dependencies in the Dockerfile by going [here](https://github.com/mathworks-ref-arch/container-images/tree/main/matlab-deps) for the full list.
- To add additional Matlab toolboxes, modify the `MATLAB_PRODUCT_LIST` argument at the top of the `docker/Dockerfile.setup` script.
- To change the linux version or update the Gradescope base, change the repository and tag following the `FROM` call in the setup Dockerfile.
- See [here](https://github.com/mathworks-ref-arch/matlab-dockerfile) for additional details on building a container image with Matlab MPM.

### Changing Default Values
The following are a list of default values set for the autograder and where they can be modified.
- The `setup.ps1` script and the `build.ps1` script have default parameters that can be adjusted at the top under "Param".
- The `run_autograder` script has default values at the top. See the source folder overview section below for more details.
- The `createTestOutput.m` function has a constant variable `MAX_OUTPUT_LENGTH` for maximum display characters it can output to Gradescope.
- The `Allowed_Functions.json` list contains the default list of allowed functions and operations.
- The `TestRunner.m` class contains a list of default properties used when running tests (it is recommended these values are modifed through the tester files instead).

### Source Folder Overview
- `run_autograder` is the bash script that is run by Gradescope when a student file is submitted.
    - It will attempt to run `runTester.m` up to 3 times. For each attempt, if Matlab takes too long to run, it will automatically timeout.
    - Adjustable variables at the top of the script:
        - `DELAY` adds an additional delay in seconds before displaying the results in Gradescope. Used to deter autograder spamming.
        - `LOCALTIMEOUT` sets the timeout of each test case in seconds.
        - `TIMEOUT` sets the timeout of each run in minutes. The maximum runtime of run_autograder is set to its double. It is recommended this default value is not changed.
        
- `runTester.m` is the main Matlab function to run the test suite and output the results as a results.json.
- `runSuite.m` is a Matlab function used to run the test suite with a timeout.
- `createTestOutput.m` is a Matlab function used to customize the text output to Gradescope given the test result.
- `encrypt.m` is a Matlab function to encrypt the source folder.
- `TestRunner.m` is a Matlab class used to run test cases. See [setup](setup.md) for more info.

### Running the autograder locally
You can run the autograder locally from the terminal using the following command: 

`docker run -it -v .:/autograder/submission -v .:/autograder/results --platform linux/amd64 ekim493/cs1371-autograder:latest bash`

Replace `ekim493/cs1371-autograder:latest` with the name of the repository and tag you want to test. You can mount local files as if you were submitting to the autograder by changing the directory you run this command from or change the `.` to the directory containing the files (ex. `./mydir:/autograder/submission`).

## Local Testing
To test student code locally, create a folder called `submissions` and add code to test to this folder. Modify the variables at the top of the `Local_Tester.m` script if necessary and then run the file. The output for the test cases will display in the command window, and it will also open up the results.json file. To use the Matlab debugger, set `useParallel` to false.
