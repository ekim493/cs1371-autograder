classdef HW0Tester < matlab.unittest.TestCase
    methods(TestClassSetup)
        function add_path(testCase)
            addpath('../solutions/HW0/');
            addpath('../');
        end
    end
    
    methods(Test)
        % Test methods
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
        function example3_Test1(testCase)
            vec = rand(1,9)*100+1;
            out1 = example3(vec);
            out1_soln = example3_soln(vec);
            testCase.verifyEqual(out1, out1_soln);
        end
    end
    
end