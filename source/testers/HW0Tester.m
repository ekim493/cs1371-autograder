classdef HW0Tester < matlab.unittest.TestCase
    methods(TestClassSetup)
        function add_path(testCase)
            addpath('/autograder/source/solutions/HW0');
        end
    end
    methods(Test)
        %% Test methods
        % ABC Example
        function exampleABC_Test1(testCase) 
            t = TesterHelper();
            t.outputType = 'limit';
            t.run();
        end
        % Error Example
        function example0_Test1(testCase)
            vec = [1, 2, 3]
            t = TesterHelper(vec);
            t.run();
        end
        % Basic & multiple test Example
        function example1_Test1(testCase)
            vec = rand(1,9)*100+1
            t = TesterHelper(vec);
            t.run();
        end
        function example1_Test2(testCase)
            vec = rand(1,9)*100+1
            t = TesterHelper(vec);
            t.run();
        end
        % Character example
        function example2_Test1(testCase)
            word = 'alphabet'
            t = TesterHelper(word);
            t.run();
        end
        % Array, iteration, and conditionals example
        function example3_Test1(testCase)
            arr = randi(15, 3, 3)
            t = TesterHelper(arr);
            t.includeFuncs = {'FOR', 'IF'};
            t.run();
        end
        % Cell array and plotting example
        function example4_Test1(testCase)
            ca = {[1, 4, 5], [3, 6, 8], 'r--', 3;
                  [2, 5, 9], [3, 2, 1], 'b-.', 1;
                  [3, 5, 6], [6, 2, 4], 'g-', 2}
            num = 2
            t = TesterHelper(ca, num);
            t.runCheckPlots = true;
            t.run();
        end
        % Lo-level example
        function example5_Test1(testCase)
            filename = 'example.txt'
            t = TesterHelper(filename);
            t.runCheckFilesClosed = true;
            t.runCheckTextFiles = 'new.txt';
            t.run();
        end
        % Structures Example
        function example6_Test1(testCase)
            st1 = struct('Season', {'Spring', 'Summer', 'Fall', 'Winter'})
            field1 = 'Temp'
            vals1 = [40, 60, 80, 65];
            t = TesterHelper(st1, field1, vals1);
            t.run();
        end
        % Images Example (bonus)
        function example7_Test1(testCase)
            img = 'image.png'
            t = TesterHelper(img);
            t.runCheckImages = 'image_updated.png';
            t.run();
        end
    end

    %#ok<*MANU>
    %#ok<*NOPRT>
       
end