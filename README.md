# CS1371-autograder
The MATLAB Gradescope autograder, designed for Georgia Tech's CS1371 course. 

This repository contains files to setup and run the Gradescope autograder. It supports testing various problem types including script variables, function outputs, plots, images, and text files. Other features include infinite loop timeouts, function call restrictions, customizable point distribution, image comparisons, and more.

Contact [Eric Kim](mailto:ekim493@gatech.edu) for questions or comments.
## Getting Started
### Requirements
1. The [Gradescope Autograder](https://gradescope-autograders.readthedocs.io/en/latest/) works by pulling a Docker image from Docker hub. To follow these instructions on your own, create a [Docker Hub](https://hub.docker.com) account, then create your own Docker Hub repository. You can view the CS1371 Docker here: [ekim493/cs1371-autograder](https://hub.docker.com/r/ekim493/cs1371-autograder).
2. The setup scripts require Powershell 6+ to run. It is avaiable on Windows by default and can be installed for MacOS through Homebrew.
3. Docker Desktop must be installed in the default location and logged in. MATLAB must also be installed and be executable through your search PATH.
4. Follow the setup instructions to create a source folder containing solution codes and testers for the autograder.

### Setup
See the [setup.md](setup.md) file for a comprehensive overview on how to setup the autograder and tester file. See the [examples](examples/) folder for an example.
- All assignments should be organized into folders where the name of the folder is the same as the Gradescope assignment.
- One tester file, which inherits the `matlab.unittest.TestCase` class should be inside each assignment folder.
- Any resources (ie. images, text files), should be placed into a folder called `assets` within the assignment folder. This name is customizable.

### Image Build
- Clone this Github repository.
- *Optional*: Run the `setup.ps1` script. See the advanced usage section below for more info.
- Run the `update.ps1` script. To run a Powershell script, open a Powershell terminal, navigate to the directory with the script, and run `.\update.ps1`. Set the parameters for `base`, `repo`, `tag`, `source`, and `encrypt` when executing the script (ex: `.\update.ps1 -source myfolder -tag HW01`).
    - The `base` parameter is the name of the repository and tag of the Docker image with Matlab installed. Use the default value or enter the repo:tag used in the `setup.ps1` script. The default is `ekim493/cs1371-autograder:base`. 
    - The `repo` parameter is the name of the new repository that the script will push to. This should be the same name as the repository you created in Docker Hub. The default is `ekim493/cs1371-autograder`.
    - The `tag` parameter is the name of an identifier to distinguish different images. This can be anything. Note that using the same tag will override previous versions. The default is `latest`.
    - The `source` parameter is the name of the source folder created during autograder setup. This folder should contain other folders named after the Gradescope assignment and contain the solution codes and testers for the autograder. The default is `cs1371`. 
    - The `encrypt` parameter is a boolean value on whether to encrypt the source folder. The default is `$true`.

- In Gradescope, go to the 'Configure Autograder' tab, select 'Manual Docker configuration', and then type in the docker Hub repository and tag. For example, `ekim493/cs1371-autograder:latest`. 
    - Make sure the Docker hub repository is public. NOTE: Making it public will allow all files to be visible online. To prevent this, either make the Docker private and add `gradescopeecs` as a collaborator (requires Pro account) or ensure encryption is set to `true` (done by default).
- Go to assignment -> settings and ensure that the `Container Specifications` under autograder settings is set to the maximum allocated. It is also recommended to put the following into the ignored file section to only accept .m files:
```
*
!*.m
```

## Advanced Usage
### Running the Setup File
The `setup.ps1` file creates a Docker image compatible with Gradescope and with MATLAB installed and logged in. This file can be used to update Matlab/linux if necessary. This script will prompt you for your Mathworks login. The following are the tags associated with the setup:
- The `Repo` parameter is the name of the repository and tag of the new Docker image. The input to this parameter should be the same as the input to the `base` parameter of the update.ps1 file. The default is `ekim493/cs1371-autograder:base`.
- The `GradescopeBase` parameter is the name of the Gradescope repository and tag that will become the base container. Ensure that the tag corresponds with an Ubuntu install or you may run into issues. The default is `gradescope/autograder-base:latest`.
- The `MatlabRelease` parameter is the version of Matlab you want installed. The default is `r2025a`.
- The `ProductList` parameter is a list of Matlab products you want installed, separated by spaces. You can view the formatted names for products [here](https://github.com/mathworks-ref-arch/matlab-dockerfile). The default is `MATLAB Parallel_Computing_Toolbox`. 
- The `DependencyFile` parameter is the file name containing a list of Linux dependencies that the relevant Matlab version requires. You can download the dependency file from [here](https://github.com/mathworks-ref-arch/container-images/tree/main/matlab-deps). The default is `base-dependencies.txt`.
- If you see a "sign-in failed" message on Gradescope, you may need to re-login to Matlab. To run the script without re-installing Matlab, use the `SkipInstall` tag or follow the prompt after running the script normally.

### Changing Default Values
The autograder contains various default values that have been set. You may edit them at the following locations:
- The `setup.ps1` script and the `update.ps1` script have default parameters that can be adjusted at the top under "Param".
- The `run_autograder` script has default values at the top.
- The `Autograder` class has various properties with default values.
- The `TestRunner` class has various properties with default values. It is recommended these values are modified through the tester file instead.
- The `Function_List.json` list contains the default list of allowed functions and operations.

### Source Folder Overview
- `run_autograder` is the bash script that is run by Gradescope when a student file is submitted.
    - It will attempt to run `runTester.m` up to 3 times. For each attempt, if Matlab takes too long to run, it will automatically timeout.
    - Adjustable variables at the top of the script:
        - `DELAY` adds an additional delay in seconds before displaying the results in Gradescope. Used to deter autograder spamming.
        - `TIMEOUT` sets the timeout of each autograder attempt in minutes. 
        - `MAX_ATTEMPTS` sets the maximum number of times to attempt running the autograder.
        - `MAX_TIME` sets the timeout of the entire autograder run in minutes. 
        - `MATLAB_ARGS` adds additional Matlab arguments. Currently set to launch with online licensing.
        
- `@Autograder` is the main Matlab class used to run the test suite and parse the results.
- `@TestRunner` is the Matlab class used to run individual test cases. For ease of use, this repository uses subtrees to store this class. The main repository can be found [here](https://github.com/ekim493/test-runner). View the readme [here](./src/@TestRunner/README.md).

- `+utils` contain extra Matlab functions useful for test cases or the autograder.
- `env` folder should be created and contain environment specific files (if necessary).
- `localTester.m` is a Matlab function used to run the autograder locally.
- `encrypt.m` is a Matlab function to encrypt the source folder.

### Running the autograder through Docker
You can run the autograder locally from the terminal using the following command: 

```
docker run -it --platform linux/amd64 ekim493/cs1371-autograder:latest bash
```

Replace `ekim493/cs1371-autograder:latest` with the name of the repository and tag you want to test. You can also mount local files as if you were submitting to the autograder. For example, you can upload files from a local `submission` folder by running the command: `docker run -it -v ./submission:/autograder/submission --platform linux/amd64 ekim493/cs1371-autograder:latest bash`.

## Local Testing
To test student code locally, create a folder called `submission` and add code to test to this folder. Then navigate to the `src` directory or add it to your path and run the `localTester` function. You can modify the submission folder (`SubmissionFolder`), assignment folder (`SourceFolder`), and whether or not to use parallel (`UseParallel`) by using the NAME=VALUE format. For example, to test with parallel off, call `localTester(UseParallel=false)`. 
