# Source
This section contains all the relevant files to run the autograder.

`run_autograder` is the bash script that is run by Gradescope when a student file is submitted.
`runTester.m` is the main Matlab driver to run the test cases and output the results as a results.json.
- The function has no inputs nor outputs. The assignment name is read in from Gradescope metadata, and the relevant testers and solutions are pulled and run directly.
- It will generate a results.json file, which Gradescope will then read to display the output.
- For more specific documentation, see file.

`/solutions` holds the solution codes for all HW assignments. 
`/testers` holds the test suites & scoring rubrics for all HW assignments. 