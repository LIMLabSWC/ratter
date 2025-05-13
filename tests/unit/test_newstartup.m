function tests = test_newstartup
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

function test_path_configuration(testCase)
    % Test that paths are correctly configured
    newstartup();
    
    % Verify core directories are in path
    verifyTrue(testCase, any(strcmp(path, fullfile(pwd, 'bin'))));
    verifyTrue(testCase, any(strcmp(path, fullfile(pwd, 'HandleParam'))));
    verifyTrue(testCase, any(strcmp(path, fullfile(pwd, 'Modules'))));
    verifyTrue(testCase, any(strcmp(path, fullfile(pwd, 'Utility'))));
end

function test_settings_loading(testCase)
    % Test settings loading
    newstartup();
    
    % Verify settings are loaded
    [Protocols_Directory, errID] = bSettings('get', 'GENERAL', 'Protocols_Directory');
    verifyEqual(testCase, errID, 0);
    verifyNotEmpty(testCase, Protocols_Directory);
end

function test_protocol_directory_validation(testCase)
    % Test protocol directory validation
    newstartup();
    
    % Verify protocol directory is in path
    [Protocols_Directory, errID] = bSettings('get', 'GENERAL', 'Protocols_Directory');
    verifyEqual(testCase, errID, 0);
    verifyTrue(testCase, any(strcmp(path, Protocols_Directory)));
end

function test_first_run_handling(testCase)
    % Test first run handling
    % Remove custom settings to trigger first run
    if exist('Settings/Settings_Custom.conf', 'file')
        delete('Settings/Settings_Custom.conf');
    end
    
    newstartup();
    
    % Verify custom settings were created
    verifyTrue(testCase, exist('Settings/Settings_Custom.conf', 'file'));
end

function test_global_variables(testCase)
    % Test global variable initialization
    newstartup();
    
    % Verify critical globals are set
    verifyNotEmpty(testCase, Solo_rootdir);
    verifyNotEmpty(testCase, Solo_datadir);
    verifyNotEmpty(testCase, fake_rp_box);
end 