function results = run_tests(test_category)
% RUN_TESTS Run BControl test suite
%   results = run_tests() runs all tests
%   results = run_tests('unit') runs unit tests
%   results = run_tests('integration') runs integration tests
%   results = run_tests('protocols') runs protocol tests
%
%   Returns:
%       results: Test results object from MATLAB's testing framework

% Add test directory to path
test_dir = fileparts(mfilename('fullpath'));
addpath(test_dir);

% Run all tests if no category specified
if nargin < 1
    results = runtests(test_dir);
    return;
end

% Run specific test category
switch lower(test_category)
    case 'unit'
        results = runtests(fullfile(test_dir, 'unit'));
    case 'integration'
        results = runtests(fullfile(test_dir, 'integration'));
    case 'protocols'
        results = runtests(fullfile(test_dir, 'protocols'));
    otherwise
        error('Unknown test category: %s', test_category);
end

% Display results
disp('Test Results:');
disp('-------------');
for i = 1:numel(results)
    if results(i).Passed
        fprintf('✓ %s\n', results(i).Name);
    else
        fprintf('✗ %s\n', results(i).Name);
        fprintf('  Error: %s\n', results(i).Error.message);
    end
end

% Print summary
fprintf('\nSummary:\n');
fprintf('Passed: %d\n', sum([results.Passed]));
fprintf('Failed: %d\n', sum(~[results.Passed]));
fprintf('Total:  %d\n', numel(results));
end 