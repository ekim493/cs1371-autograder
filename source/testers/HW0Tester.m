classdef HW0Tester < matlab.unittest.TestCase
    methods(TestClassSetup)
        function add_path(testCase)
            addpath('../solutions/HW0');
            addpath('/autograder/submission');
        end
    end
    methods(Test)
        %% Test methods
        % ABC Example
        function exampleABC_Test(testCase) 
            exampleABC();
            exampleABC_soln();
            TesterHelper.checkCalls();
            TesterHelper.checkAllEqual('limit', 'html');
        end
        % Error Example
        function example0_Test1(testCase)
            vec = [1, 2, 3];
            out1 = example0(vec);
            out1_soln = example0_soln(vec);
            TesterHelper.checkCalls();
            TesterHelper.checkAllEqual('html');
        end
        % Basic & multiple test Example
        function example1_Test1(testCase)
            vec = rand(1,9)*100+1;
            out1 = example1(vec);
            out1_soln = example1_soln(vec);
            TesterHelper.checkCalls();
            TesterHelper.checkAllEqual('html');
        end
        function example1_Test2(testCase)
            vec = rand(1,9)*100+1;
            out1 = example1(vec);
            out1_soln = example1_soln(vec);
            TesterHelper.checkCalls();
            TesterHelper.checkAllEqual('html');
        end
        % Character example
        function example2_Test1(testCase)
            word = 'alphabet';
            [out1, out2] = example2(word); 
            [out1_soln, out2_soln] = example2_soln(word);
            TesterHelper.checkCalls();
            TesterHelper.checkAllEqual('html');
        end
        % Array, iteration, and conditionals example
        function example3_Test1(testCase)
            arr = randi(15, 3, 3);
            [out1, out2] = example3(arr);
            [out1_soln, out2_soln] = example3_soln(arr);
            TesterHelper.checkCalls('html', include={'FOR', 'IF'});
            TesterHelper.checkAllEqual('html');
        end
        % Cell array and plotting example
        function example4_Test1(testCase)
            ca = {[1, 4, 5], [3, 6, 8], 'r--', 3;
                  [2, 5, 9], [3, 2, 1], 'b-.', 1;
                  [3, 5, 6], [6, 2, 4], 'g-', 2};
            num = 2;
            close all;
            out1 = example4(ca, num);
            figure;
            out1_soln = example4_soln(ca, num);
            TesterHelper.checkCalls();
            TesterHelper.checkAllEqual('html');
            TesterHelper.checkPlots('html');
        end
        % Lo-level example
        function example5_Test1(testCase)
            filename = 'example.txt';
            example5(filename);
            example5_soln(filename);
            TesterHelper.checkFilesClosed('html');
            TesterHelper.checkCalls();
            TesterHelper.checkTxtFiles('new.txt', 'html');
        end
        % Structures Example
        function example6_Test1(testCase)
            st1 = struct('Season', {'Spring', 'Summer', 'Fall', 'Winter'});
            field1 = 'Temp';
            vals1 = [40, 60, 80, 65];
            new_st = example6(st1, field1, vals1);
            new_st_soln = example6_soln(st1, field1, vals1);
            TesterHelper.checkCalls();
            TesterHelper.checkAllEqual('html');
        end
        % Images Example (bonus)
        function example7_Test1(testCase)
            img = 'image.png';
            num = example7(img);
            num_soln = example7_soln(img);
            TesterHelper.checkCalls();
            TesterHelper.checkAllEqual('html');
            TesterHelper.checkImages('image_updated.png', 'html');
        end
    end

    %#ok<*MANU>
    %#ok<*NASGU>
    %#ok<*ASGLU>
       
end