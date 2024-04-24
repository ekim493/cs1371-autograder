# Testers
This section contains all the testers to be run and information regarding the test cases.
The name of the tester should be the gradescope assignment name + 'Tester'.
The name of the scoring rubric should be the gradescope assignment name + 'Scores.json'.
- Example: The Gradescope assignment `HW0` should have the tester `HW0Tester.m` and the scoring rubric `HW0Scores.json`.
## Tester Specifications
All testers should inherit the `matlab.unittest.TestCase` class and should implement test cases under the `Test` methods.
All testers should have have a `TestClassSetup` method where the following function is implemented:

**Make sure the first addpath() call points to the relevant folder (ie. HW0)**
```
function add_path(testCase)
    addpath('../solutions/HW0/');
    addpath('../');
end
```
All test cases should be name `FUNCTION_Test#`, where `FUNCTION` is replaced with the function name it is testing, and # is an identifier for the test case.
Example:
```
function example1_Test1(testCase)
    vec = rand(1,9)*100+1;
    out1 = example1(vec);
    out1_soln = example1_soln(vec);
    testCase.verifyEqual(out1, out1_soln);
end
```
## Scoring Rubric Specifications
All scoring rubrics should be a .json file with at minimum a 'tests' field. This field should contain a list of every function that is to be tested, with the field 'name' assigned to the name of the function, and the field 'max_score' assigned the total possible score for that function.
Any assignment wide fields such as visibility should also be listed in this JSON. See the specifications on [Gradescope](https://gradescope-autograders.readthedocs.io/en/latest/specs/). Currently, additional data in tests is not transferred over.

Example:
```
{ 
  "visibility": "visible",
  "tests":
    [
        {
            "max_score": 1, 
            "name": "example1"
        },
        {
            "max_score": 2, 
            "name": "example2"
        },
        // Add more test cases
    ]
}
```