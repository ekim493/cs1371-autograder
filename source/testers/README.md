# Testers
This section contains all the testers to be run and information regarding the test cases.
The name of the tester should be the gradescope assignment name + 'Tester'.
- Example: The Gradescope assignment `HW0` should have the tester `HW0Tester.m`.
## Tester Specifications
All testers should inherit the `matlab.unittest.TestCase` class and should implement test cases under the `Test` methods.
All testers should have have a `TestClassSetup` method where the following function is implemented:

**Make sure the addpath() call points to the relevant solution folder (ie. HW0). Optionally, also add local testing support**
```
function add_path(testCase)
    if isunix && ~ismac
        addpath('/autograder/source/solutions/HW0');
    else
        addpath('../solutions/HW0');
    end
end
```
All test case methods should be group and tagged by the level of the problem being tested:
- Level 1 problems ('L1') are assigned 1 point, level 2 ('L2') = 2 points, and level 3 ('L3')= 3 points.
- Level 0 ('L0') will be assigned 0 points, but failing any test case will halve the total score.
- Level >=4 will be given 0 points with no effect.
 
All test cases should be name `FUNCTION_Test#`, where `FUNCTION` is replaced with the function name it is testing, and # is an identifier for the test case.

The `TesterHelper.m` contains a `TesterHelper` class which has functions that can should be used to test functions. 
For each test case, a `TesterHelper` object should be created, and the necessary properties should be set. The following is a list of useful properties. 
For full details, read the documentation in `TesterHelper.m`.
- runCheckAllEqual-> Check and compare all solution variables against the student's.
- runCheckCalls -> Check a function file's calls.
- runCheckFilesClosed -> Check if all files have been properly closed.
- runCheckImages -> Check and compare an image against the solution's.
- runCheckPlots -> Check and compare a plot against the solution's.
- runCheckTextFiles -> Check and compare a text file against the solution's.
- toChar -> (static) Turn the input into a character vector for Gradescope diagnosis.
By default, `runCheckAllEqual` and `runCheckCalls` will always run. The inputs to the object constructor should be the inputs to the function being tested. 
Once all properties are set, call the `run()` function on the object.

The following is a recommended implementation of a test case. See `HW0Tester.m` for more examples.
```
function example3_Test1(testCase)
    arr = randi(15, 3, 3)
    t = TesterHelper(arr);
    t.includeFuncs = {'FOR', 'IF'};
    t.run();
end
```