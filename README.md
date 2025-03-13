# CS1371-autograder
The Gradescope autograder for CS1371. Contact [Eric Kim](mailto:ekim493@gatech.edu) for questions or comments.
## Install instructions 
Currently, the Docker is hosted by me at `ekim493/cs1371-autograder`. To follow these instructions on your own, create a Docker hub account, then create your own Docker hub repository.
- Clone this Github repository.
- Add all necessary files (solution codes and testers) for the HW.
    - See the [Structure](https://github.gatech.edu/ekim493/cs1371-autograder#stucture) section below for more info. Also see the [testers readme](https://github.gatech.edu/ekim493/cs1371-autograder/tree/master/source/testers#testers) for info on how to structure the tester.
- Run the `update.bat` script (this script will only work on Windows).
    - There is an optional setting (enabled by default) that will add encryption. This will p-code all solution and tester files before creating and uploading the Docker container.
    - If you have created your own repository, edit the `RepoName` variable at the top of the `update.bat` file.
    - You must have Docker installed and be logged in.
- Enter a tag for the docker image (ex. HW01).
- In gradescope, go to 'Configure Autograder', select 'Manual Docker configuration', and then type in the docker hub repository and tag. For example, `ekim493/cs1371-autograder:latest`.
    - Make sure the Docker hub repository is public. NOTE: Making it public will allow all files to be visible online. To prevent this, either make the Docker private and add `gradescopeecs` as a collaborator (requires Pro account) or ensure all solution files are pcoded.

If Matlab or the Dockerfile needs to be updated, use the `setup.bat` script. Enter the DockerHub repository and tag to publish to, or use the default values. You will be prompted for your Mathworks email and a OTP.
    

<details>
  <summary><b>Old/Manual Instructions</b></summary>

Currently, the Docker is hosted by me at ekim493/cs1371-autograder. To follow these instructions on your own, create a Docker hub account, then create your own Docker hub repository. Then, replace all instances of 'ekim493/cs1371-autograder' with the name of your Docker hub repository. These instructions are only tested for Windows.

-  Clone this Github repository.
-  Download the Docker engine and log in.
- Open the terminal and navigate to the cloned repository directory with the Dockerfile.
- Add all necessary files (solution codes, tester, and scores.json) for the corresponding HW assignment.
    - See the [Structure](https://github.gatech.edu/ekim493/cs1371-autograder#stucture) section below for more info. Also see the [testers readme](https://github.gatech.edu/ekim493/cs1371-autograder/tree/master/source/testers#testers) for info on how to structure the tester and json.
- Type `docker build ./ -t ekim493/cs1371-autograder` and wait for the build process to finish.
- Type `docker run --rm -it -v /source/submit:/autograder/submission -v /source:/autograder/results ekim493/cs1371-autograder:latest bash`.
- You should now be in the Docker container, and the terminal should say something like root@123123.
- Run Matlab by typing `matlab -licmode onlinelicensing`. You will then be prompted to enter your email (enter the one used to login to Mathworks).
- It will then prompt you for a one time password by following a link to the Mathworks website.
- Enter the password and Matlab should start.
- Open a new terminal **while the previous one is still running**, and type `docker commit CONTAINER_NAME ekim493/cs1371-autograder:TAG`.
    - Replace CONATINER_NAME with the name of the current container. This can be found in the Docker desktop app under the 'containers' tab.
    - Replace TAG with a tag to label this instance
    - **Ensure you are logged in**
- Finally, push the image to the web using `docker push ekim493/cs1371-autograder:TAG` (while still in the new terminal).
- In gradescope, go to 'Configure Autograder', select 'Manual Docker configuration', and then type in the docker image name. `ekim493/cs1371-autograder:TAG` in this case.
    - Make sure the Docker hub repository is public. NOTE: Making it public will allow all files to be visible online. To prevent this, either make the Docker private and add `gradescopeecs` as a collaborator (requires Pro account) or ensure all solution files are pcoded.
</details>

## Stucture
`Dockerfile` is the file used to build our Docker environment
- Update the Dockerfile if the Matlab version changes.
- See [here](https://github.com/mathworks-ref-arch/matlab-dockerfile) for details on building the matlab docker, and see [here](https://github.com/mathworks-ref-arch/container-images/tree/main/matlab-deps) for details on the required Matlab dependencies.

`source` holds all relevant data necessary to run the autograder
- `source/run_autograder` is the main shell script run by the Gradescope harness.
- `source/runTester.m` is the main Matlab driver to run the test cases and output the results as a results.json.
- `source/solutions` holds the solution codes for all HW assignments. 
    - All assignments should be organized into folders where the name of the folder is the same as the gradescope assignment.
    - All solutions codes should be name `FUNCTION_soln.m`, where `FUNCTION` is replaced with the name of the function.
- `source/testers` holds the tester files for all HW assignments. 
    - The name of the tester should be the the gradescope assignment name + 'Tester.m'.
    - Example: For a gradescope assignment called `HW0`, the testers file should contain a `HW0Tester.m`.

## Local Testing
To test code locally, add all code to test to the `Submissions` folder. Then run `Local_Tester.m`. The output for the test cases will display in the command window, and it will also open up the results.json file.