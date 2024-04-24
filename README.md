# CS1371-autograder
The *new* Gradescope autograder for CS1371.
## Stucture
`Dockerfile` is the file used to build our Docker environment
- Uses gradescope/autograder-base as the base and attempts to silently install Matlab (see [here](https://www.mathworks.com/help/install/ug/install-noninteractively-silent-installation.html))
    - No File Installation Key currently
- To run the Docker image locally, download the repo and the Docker engine, then type `docker build /repo/download/location -t gradescope_base` followed by `docker run --rm -it -v /source/submit:/autograder/submission -v /source:/autograder/results gradescope_base:latest bash`.
    - **REPLACE `/repo/download/location` with your repo location**
    - To test the gradescope output, run `source/runTester.m` in your local Matlab, upload the resulting 'test_output.zip' to a gradescope autograder, and submit any file to get the autograder running.
- Update the Dockerfile if the Matlab version changes.
- Ideally we want the Docker to be published automatically somehow.

`matlab` holds the linux installation for the relevant Matlab version. 
- To update the Matlab version, download the installer and run 'download without installing'. See [here](https://www.mathworks.com/help/install/ug/install-noninteractively-silent-installation.html) for more info.

`source` holds all relevant data necessary to run the autograder
- `source/runTester.m` is the main Matlab driver to run the test cases and output the results as a results.json.
- `source/solutions` holds the solution codes for all HW assignments. 
    - All assignments should be organized into folders where the name of the folder is the same as the gradescope assignment.
    - All solutions codes should be name `FUNCTION_soln.m`, where `FUNCTION` is replaced with the name of the function.
- `source/testers` holds the test suites & scoring rubrics for all HW assignments. 
    - The name of the tester should be the the gradescope assignment name + 'Tester.m'.
    - The name of the scoring rubrics should be a JSON with the name being the assignment + 'Scores.json'.
    - Example: For a gradescope assignment called `HW0`, the testers file should contain a `HW0Tester.m` and a `HW0Scores.json`.
## To-Do
- [ ] Add ABC check implementation.
- [ ] Modify the runner once a valid Matlab license has been obtained to run inside Gradescope.
- [ ] Figure out how to run matlab once that's done
- [ ] Figure out how to get github to automatically publish the Docker image to Docker hub. Documentation [here](https://docs.github.com/en/actions/publishing-packages/publishing-docker-images) and [here](https://github.com/docker/build-push-action).