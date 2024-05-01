# CS1371-autograder
The *new* Gradescope autograder for CS1371.
## To-Do
- [ ] Modify the runner once a valid Matlab license has been obtained to run inside Gradescope.
    - Originally, the goal was to attempt to silently install Matlab (see [here](https://www.mathworks.com/help/install/ug/install-noninteractively-silent-installation.html))
    - However, it seems like a connection to a license network server must be made instead (see [here](https://github.com/mathworks-ref-arch/matlab-dockerfile))
- [ ] Figure out how to run the tester once that's done
- [ ] Figure out how to get github to automatically publish the Docker image to Docker hub. Documentation [here](https://docs.github.com/en/actions/publishing-packages/publishing-docker-images) and [here](https://github.com/docker/build-push-action).
    - So it looks like this isn't possible unless we move the github to a non-enterprise version or we pay for Docker hub
## Stucture
`Dockerfile` is the file used to build our Docker environment
- To run the Docker image locally, download the repo and the Docker engine, then type `docker build /repo/download/location -t cs1371-autograder` followed by `docker run --rm -it -v /source/submit:/autograder/submission -v /source:/autograder/results cs1371-autograder:latest bash`.
    - **REPLACE `/repo/download/location` with your repo location**
    - To test the gradescope output, run `source/runTester.m` in your local Matlab, upload the resulting 'test_output.zip' to a gradescope autograder, and submit any file to get the autograder running.
- Update the Dockerfile if the Matlab version changes.
- Ideally we want the Docker to be published automatically somehow.

`matlab` holds the linux installation for the relevant Matlab version. 

`source` holds all relevant data necessary to run the autograder
- `source/runTester.m` is the main Matlab driver to run the test cases and output the results as a results.json.
- `source/solutions` holds the solution codes for all HW assignments. 
    - All assignments should be organized into folders where the name of the folder is the same as the gradescope assignment.
    - All solutions codes should be name `FUNCTION_soln.m`, where `FUNCTION` is replaced with the name of the function.
- `source/testers` holds the test suites & scoring rubrics for all HW assignments. 
    - The name of the tester should be the the gradescope assignment name + 'Tester.m'.
    - The name of the scoring rubrics should be a JSON with the name being the assignment + 'Scores.json'.
    - Example: For a gradescope assignment called `HW0`, the testers file should contain a `HW0Tester.m` and a `HW0Scores.json`.
## Gradescope view
What the current gradescope autograder view looks like:
![image](current_gradescope_view.png)

