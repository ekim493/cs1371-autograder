# Testers
This section contains all the testers to be run and information regarding the test cases.
The name of the tester should be the gradescope assignment name + 'Tester'.
The name of the scoring rubric should be the gradescope assignment name + 'Scores.json'.
- Example: The Gradescope assignment `HW0` should have the tester `HW0Tester.m` and the scoring rubric `HW0Scores.json`.
## Tester Specifications
All testers should inherit the `matlab.unittest.TestCase` class and should implement test cases under the `Test` methods.
All testers should have have a `TestClassSetup` method where the following function is implemented:

**Make sure the addpath() call points to the relevant folder (ie. HW0)**
```
function add_path(testCase)
    addpath('/autograder/source/solutions/HW0');
end
```
All test cases should be name `FUNCTION_Test#`, where `FUNCTION` is replaced with the function name it is testing, and # is an identifier for the test case.

The `TesterHelper.m` contains a `TesterHelper` class which contains static helper functions that can be used by any Tester. The following is a list of useful check and helper functions. For full details, read the documentation contained in `TesterHelper.m`.
- run -> Run the student's code with a timeout and display inputs to stdout.
- checkAllEqual	-> Check and compare all solution variables against the student's.
- checkCalls -> Check a function file's calls.
- checkFilesClosed -> Check if all files have been properly closed.
- checkImages -> Check and compare an image against the solution's.
- checkPlots -> Check and compare a plot against the solution's.
- checkTxtFiles -> Check and compare a text file against the solution's.
- generateCellArray -> Generate a pseudorandom cell array with various options.
- generateString -> Generate a character array with various options.
- toChar -> Turn the input into a character vector for Gradescope diagnosis.

The following is a recommended implementation of a test case. See `HW0Tester.m` for more examples.
```
function example1_Test1(testCase)
    vec = [1 2 3 4 5];
    out1 = TesterHelper.run(vec);
    out1_soln = example1_soln(vec);
    TesterHelper.checkCalls();
    TesterHelper.checkAllEqual();
end
```

## Scoring Rubric Specifications
All scoring rubrics should be a .json file with at minimum a 'tests' field. This field should contain a list of every function that is to be tested, with the field 'name' assigned to the name of the function, and the field 'level' assigned the level/difficulty for that problem.
- Level 1 problems are assigned 1 point, level 2 = 2 points, and level 3 = 3 points.
- Level 0 or ABC problems will be assigned 0 points, but failing any test case will halve the total score.
- Extra credit problems will be given 0 points with no effect.

Any assignment wide fields such as visibility should also be listed in this JSON. See the specifications on [Gradescope](https://gradescope-autograders.readthedocs.io/en/latest/specs/).

Example:
```
{ 
  "visibility": "visible",
  "tests":
    [
        {
            "level": 0,
            "name": "exampleABC"
        },
        {
            "level": 1, 
            "name": "example1"
        },
        {
            "level": 2, 
            "name": "example2"
        },
        {
            "level": 3, 
            "name": "example3"
        },
        {
            "level": 4,
            "name": "exampleEC"
        }
    ]
}
```
