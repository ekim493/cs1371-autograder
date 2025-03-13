# Source
This section contains all the relevant files to run the autograder. For more specific documentation, see file contents.

- `run_autograder` is the bash script that is run by Gradescope when a student file is submitted. It will attempt to run `runTester.m` up to 3 times (in case of rare segmentation fault issue). For each attempt, if Matlab takes too long to run, it will automatically timeout.
- `runTester.m` is the main Matlab driver to run the test cases and output the results as a results.json.
- `runSuite.m` is a Matlab function used to run a test suite with a timeout.
- `createTestOutput.m` is a Matlab function used to customize the text output given the test result.

`/solutions` holds the solution codes for all HW assignments. 
`/testers` holds the tester files for all HW assignments. 