# Autograder Setup
## Organization
Create a new folder (ex. 'cs1371') in the same directory as the setup scripts. This will be the **assignment** directory for the autograder.
- All assignments must be organized into folders inside the assignment directory where the name of the folder is the same as the Gradescope assignment.
- Each assignment folder must contain the following:
    - Solution codes for all problems being tested.
    - A tester file containing all test cases for the assignment.
    - Additional input files (images, text files, etc.) as needed, placed into a `assets` folder.

## Tester Specifications
All tester files must inherit the `matlab.unittest.TestCase` class and implement test cases under the `Test` methods.

By default, the test runner uses the prefix before _Test as the name of the function to be tested. Thus, all test cases should be named `FUNCTION_Test#` where `FUNCTION` is replaced with the name of the function to be tested. To override this, you can set the `TestRunner.FunctionName` property.

All test case methods should be group and tagged with a problem identifier and how the problem should be scored. Having multiple scoring and identifier tags may cause issues.
- The identifier can be any string, and the final order of the test cases will be sorted according to the alphabetical order of the string. It is recommended to simply tag problems with numeric strings such as `'1.1'` and `'2.1'`.
- The scoring tag should be prefixed with how the score should be distributed among test cases for the problem. Set a prefix of `each=` to give each test case within the problem the assigned number of points. Set a prefix of `total=` to divide the assigned number of points evenly between all test cases.
- The point values are defined as follows:
    - `N`: Standard scoring.
    - `+N`: Extra credit. If correct, it will add to the total score. 
    - `-N`: Penalty scoring. If incorrect, it will subtract from the total score. 
    - `xN`: Multiplicative scoring. If correct, it will multiply the final score by N. N can be any value.
    - `/N`: Penalty multiplicative scoring. If incorrect, it will multiply the final score by N. N can be any value.
- Test cases other than the standard scoring will show a max score of 0 for that test case. Multiplication is compounding, and is done before any extra credit or penalty scores are added and subtracted. The final score is set to be a minimum of 0.
- Note that the maximum score for the overall assignment must be set manually within the Gradescope assignment.

### Creating Test Cases
The `TestRunner` class contains functions that should be used to test functions. 
For each test case, create a `TestRunner` object and pass in the same inputs as the function being tested. 
For example, if you are testing a function that you would normally call as follows `out = twoSum([1 2 3], 2)`, then create the object by calling `t = TestRunner([1 2 3], 2)`.

Then, set the properties of the object using dot notation. The following is a list of properties that involve checks. For full details, read the documentation under the TestRunner class [here](src/@TestRunner/README.md).
- RunCheckAllEqual -> Check and compare all solution variables against the student's.
- RunCheckCalls -> Check a function file's calls for banned functions, set by `Function_List.json`. 
- RunCheckPlots -> Check and compare a plot against the solution's.
- RunCheckTextFiles -> Check and compare a text file against the solution's. 
- RunCheckFilesClosed -> Check if all files have been properly closed.
- RunCheckImages -> Check and compare an image against the solution's Set to the filename to check.

The +utils folder contains useful helper methods. You can call these functions by prefixing them with utils. For example, `utils.generateSpecs`.
- generateCellArray -> Generates a random, simple cell array containing various data types.
- generateSpecs -> Generates a random specification for plotting.
- generateString -> Generate a random or pseudorandom string of characters.
- notifyWeb -> Notifies a webhook URL.

Once all properties are set, call the `run()` function on the object.

The following is an example implementation of a test case class. See [HW0Tester.m](examples/autograder/HW0/HW0Tester.m) for more examples.
```
classdef HW0Tester < matlab.unittest.TestCase
    methods(Test, TestTags = {'1.1', 'each=1'})
        function example3_Test1(testCase)
            arr = randi(15, 3, 3);
            t = TestRunner(arr);
            t.IncludeFuncs = {'FOR', 'IF'};
            t.OutputNames = {'array', 'number'};
            t.run();
        end
        function example5_Test1(testCase)
            filename = 'example.txt';
            t = TestRunner(filename);
            t.RunCheckTextFiles = 'new.txt';
            t.run();
        end
    end
    methods(Test, TestTags = {'2.1', 'each=+1'})
        function example8_Test1(testCase)
            ca = utils.generateCellArray(columns=[5, 10]);
            t = TestRunner(ca);
            t.run();
        end
    end
end
```

### Other Specificiations
Because of the possibility of the race condition, test cases that have checks involving files (ie. text files, images) should output to different file names. 
The solution can output to the same name as the student's, but different test cases should output to different files.