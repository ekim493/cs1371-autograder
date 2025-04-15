# Testers
This section contains all the testers to be run and information regarding the test cases.
The name of the tester should be the gradescope assignment name + 'Tester'.
- Example: The Gradescope assignment `HW0` should have the tester `HW0Tester.m`.
## Tester Specifications
All testers should inherit the `matlab.unittest.TestCase` class and should implement test cases under the `Test` methods.

All test case methods should be group and tagged by the level of the problem being tested:
- Level 1 problems ('L1') are assigned 1 point, level 2 ('L2') = 2 points, and level 3 ('L3')= 3 points.
- Level 0 ('L0') will be assigned 0 points, but failing any test case will halve the total score.
- Level >= 4 will be given 0 points with no effect.
 
All test cases should be name `FUNCTION_Test#`, where `FUNCTION` is replaced with the function name it is testing, and # is an identifier for the test case.

### Creating Test Cases
The `TesterHelper.m` file contains a `TesterHelper` class which has functions that should be used to test functions. 
For each test case, create a `TesterHelper` object and pass in the same inputs as the function being tested. 
For example, if you are testing a function that you would normally call as follows `out = twoSum([1 2 3], 2)`, then create the object by calling `t = testerHelper([1 2 3], 2)`.

Then, set the properties of the object using dot notation. The following is a list of properties that involve checks. For full details, read the documentation in `TesterHelper.m`.
- runCheckAllEqual-> Check and compare all solution variables against the student's. Set to true or false (Default = true).
- runCheckCalls -> Check a function file's calls for banned functions, set by `Allowed_Functions.json`. Set to true or false (Default = true).
- runCheckPlots -> Check and compare a plot against the solution's. Set to true or false (Default = false).
- runCheckTextFiles -> Check and compare a text file against the solution's. Set to the filename to check. If empty, it will not run (Default = '').
- runCheckFilesClosed -> Check if all files have been properly closed. Set to true or false (Default = false).
- runCheckImages -> Check and compare an image against the solution's Set to the filename to check. If empty, it will not run (Default = '').

The following are a list of other useful properties. Additional properties can be found in the documentation.

- For the following 3 properties which modify runCheckCalls, any keywords that are listed when `iskeyword` is called in Matlab must be in all caps.
    - allowedFuncs -> Functions that are allowed to be used, regardless of if it is not in the allowed function list. Set to a cell array of characters.
    - bannedFuncs -> Functions that are banned, regardless of it is in the allowed function list. Set to a cell array of characters.
    - includeFuncs -> Functions that must be used by the student. Set to a cell array of characters.
- outputType -> Amount of information that the output should display. Set to 'full', 'limit', or 'none' (Default = 'full').
- outputNames -> Add optional output names to variables instead of the default 'output#'. For Student QOL.
- textRule -> How strict checkTextFiles should be. Set to 'default', 'strict', or 'loose' (Default = 'default').
- numTolerance -> Absolute tolerance for numerical comparisons in checkAllEqual. Default = 0.001.

The following are a list of useful static methods provided by the class.
- generateCellArray -> Generates a random, simple cell array containing various data types.
- generateSpecs -> Generates a random specification for plotting.
- generateString -> Generate a random or pseudorandom string of characters.
- toChar -> Turns any input into a character vector for Gradescope display.

Once all properties are set, call the `run()` function on the object.

The following is an example implementation of a test case calling the `example3` function. See `HW0Tester.m` for more examples.
```
function example3_Test1(testCase)
    arr = randi(15, 3, 3)
    t = TesterHelper(arr);
    t.includeFuncs = {'FOR', 'IF'};
    t.run();
end
```

### Test Case specificiations
Because of the possibility of the race condition, test cases that have checks involving files (ie. text files, images) should output to different file names. 
The solution can output to the same name as the student's, but different test cases should output to different files.