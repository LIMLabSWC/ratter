function tests = test_newstartup_helpers
    tests = functiontests(localfunctions);
end

function setup(testCase)
    % Setup test environment
    testCase.TestData.originalPath = path;
    testCase.TestData.originalPwd = pwd;
    
    % Create temporary test directory
    testCase.TestData.testDir = tempname;
    mkdir(testCase.TestData.testDir);
    cd(testCase.TestData.testDir);
    
    % Create test settings directory
    mkdir('Settings');
    copyfile(fullfile(testCase.TestData.originalPwd, 'ExperPort', 'Settings', 'Settings_Template.conf'), ...
             fullfile('Settings', 'Settings_Default.conf'));
end

function teardown(testCase)
    % Restore original state
    path(testCase.TestData.originalPath);
    cd(testCase.TestData.originalPwd);
    
    % Clean up test directory
    rmdir(testCase.TestData.testDir, 's');
end

function test_handle_newstartup_error(testCase)
    % Test error handling
    verifyError(testCase, @() HandleNewstartupError(1, 'Test error'), 'MATLAB:error');
end

function test_bcontrol_first_run(testCase)
    % Test first run handling
    if exist('Settings/Settings_Custom.conf', 'file')
        delete('Settings/Settings_Custom.conf');
    end
    
    [errID, errmsg] = BControl_First_Run('Settings/Settings_Custom.conf', ...
                                       'Settings/Settings_Default.conf');
    
    verifyEqual(testCase, errID, 0);
    verifyEmpty(testCase, errmsg);
    verifyTrue(testCase, exist('Settings/Settings_Custom.conf', 'file'));
end

function test_verify_settings(testCase)
    % Test settings verification
    [errID, errmsg] = Verify_Settings();
    
    verifyEqual(testCase, errID, 0);
    verifyEmpty(testCase, errmsg);
end

function test_compatibility_globals(testCase)
    % Test global variable initialization
    [errID, errmsg] = Compatibility_Globals();
    
    verifyEqual(testCase, errID, 0);
    verifyEmpty(testCase, errmsg);
    
    % Verify critical globals are set
    verifyNotEmpty(testCase, Solo_rootdir);
    verifyNotEmpty(testCase, Solo_datadir);
    verifyNotEmpty(testCase, fake_rp_box);
end 