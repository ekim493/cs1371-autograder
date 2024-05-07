classdef HW0Tester < matlab.unittest.TestCase
    methods(TestClassSetup)
        function add_path(testCase)
            addpath('../solutions/HW0');
            addpath('/autograder/submission');
        end
    end
    
    methods(Test)
        % Test methods
        function exampleABC_A(testCase)
            exampleABC();
            testCase.verifyEqual(A, 'abc');
        end
        function exampleABC_B(testCase)
            exampleABC();
            testCase.verifyEqual(B, {123});
        end
        function exampleABC_C(testCase)
            exampleABC();
            testCase.verifyEqual(C, true);
        end
        function example1_Test1(testCase)
            vec = rand(1,9)*100+1;
            out1 = example1(vec);
            out1_soln = example1_soln(vec);
            testCase.verifyEqual(out1, out1_soln);
        end
        function example2_Test1(testCase)
            vec = rand(1,9)*100+1;
            out1 = example2(vec);
            out1_soln = example2_soln(vec);
            testCase.verifyEqual(out1, out1_soln, sprintf('Actual output: %d\nExpected output: %d',out1, out1_soln));
        end
        function example2_Test2(testCase)
            vec = rand(1,9)*100+1;
            out1 = example2(vec);
            out1_soln = example2_soln(vec);
            testCase.verifyEqual(out1, out1_soln, sprintf('Actual output: %d\nExpected output: %d',out1, out1_soln));
        end
        function example2_Test3(testCase)
            vec = rand(1,9)*100+1;
            out1 = example2(vec);
            out1_soln = example2_soln(vec);
            testCase.verifyEqual(out1, out1_soln, sprintf('Actual output: %d\nExpected output: %d',out1, out1_soln));
        end
        function example3_Test1(testCase)
            vec = rand(1,9)*100+1;
            [out1, out2] = example3(vec);
            [out1_soln, out2_soln] = example3_soln(vec);
            testCase.verifyEqual(out1, out1_soln, sprintf('Actual output: %d\nExpected output: %d',out1, out1_soln));
            testCase.verifyEqual(out2, out2_soln, sprintf('Actual output: %d\nExpected output: %d',out2, out2_soln));
        end
        function exampleEC_Test1(testCase)
            vec = rand(1,9)*100+1;
            [out1, out2] = exampleEC(vec);
            [out1_soln, out2_soln] = exampleEC_soln(vec);
            testCase.verifyEqual(out1, out1_soln, sprintf('Actual output: %d\nExpected output: %d',out1, out1_soln));
            testCase.verifyEqual(out2, out2_soln, sprintf('Actual output: %d\nExpected output: %d',out2, out2_soln));
        end
    end
    
end