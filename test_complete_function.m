% 完整功能测试脚本 - 测试增强版integrateMatFiles函数的所有功能

% 清除工作空间，避免变量冲突
clear all;
close all;
clc;

disp('=== 开始测试增强版数据整合功能 ===');
disp('');

% 测试参数设置
testRootFolder = 'F:\\GDB';  % 根文件夹路径
testSaveFileName = 'test_complete_result.mat';  % 保存文件名

% 测试进度保存功能
disp('1. 测试进度保存和大文件处理功能');
disp('');

% 创建一个示例的小型MAT文件用于测试
testDataFolder = fullfile(pwd, 'test_data');
if ~exist(testDataFolder, 'dir')
    mkdir(testDataFolder);
end

% 创建测试文件
disp('创建测试数据文件...');
testFile1 = fullfile(testDataFolder, 'test1.mat');
testStruct1 = struct('name', '测试文件1', 'data', rand(100), 'timestamp', now);
save(testFile1, 'testStruct1');

testFile2 = fullfile(testDataFolder, 'test2.mat');
testStruct2 = struct('name', '测试文件2', 'data', rand(200), 'timestamp', now);
save(testFile2, 'testStruct2');

disp('测试文件创建完成');
disp('');

% 执行整合测试，启用所有新功能
disp('执行数据整合测试...');
try
    % 调用增强版函数，启用所有功能
    integratedData = integrateMatFiles(testRootFolder, ...
        'SaveToFile', true, ...
        'SaveFileName', testSaveFileName, ...
        'ProgressSave', true, ...
        'MaxFileSize', 50);  % 50MB作为大文件阈值
    
    disp('');
    disp('✓ 整合函数调用成功');
    
    % 验证文件是否创建
    if exist(testSaveFileName, 'file') == 2
        fileInfo = dir(testSaveFileName);
        disp(sprintf('✓ 结果文件已创建: %s (%.2f KB)', testSaveFileName, fileInfo.bytes/1024));
        
        % 验证文件内容
        disp('验证文件内容...');
        try
            loadedData = load(testSaveFileName, 'integratedData');
            disp('✓ 成功加载保存的文件');
            disp(sprintf('  整合的文件夹数: %d', loadedData.integratedData.metaData.folderCount));
            disp(sprintf('  整合的文件数: %d', loadedData.integratedData.metaData.totalFiles));
            disp(sprintf('  成功处理: %d', loadedData.integratedData.metaData.successCount));
            disp(sprintf('  失败处理: %d', loadedData.integratedData.metaData.failCount));
            
        catch loadError
            disp(sprintf('✗ 文件加载失败: %s', loadError.message));
        end
    else
        disp('✗ 结果文件未创建');
    end
    
    % 验证日志文件
    if exist('integration_process_log.txt', 'file') == 2
        logInfo = dir('integration_process_log.txt');
        disp(sprintf('✓ 日志文件已创建 (%.2f KB)', logInfo.bytes/1024));
    else
        disp('✗ 日志文件未创建');
    end
    
    % 验证进度文件已被清理（整合完成后应该删除）
    if exist('integration_progress.mat', 'file') == 0
        disp('✓ 进度文件已正确清理');
    else
        disp('⚠ 进度文件未被清理');
    end
    
    catch ME
    disp(sprintf('✗ 测试失败: %s', ME.message));
    disp(sprintf('  错误ID: %s', ME.identifier));
    
    % 检查是否生成了进度文件（在异常情况下应该存在）
    if exist('integration_progress.mat', 'file') == 2
        disp('✓ 异常情况下进度文件已保存');
    end
end

disp('');
disp('=== 测试完成 ===');
disp('');
disp('清理测试数据...');

% 清理测试文件
try
    if exist(testFile1, 'file') == 2
        delete(testFile1);
    end
    if exist(testFile2, 'file') == 2
        delete(testFile2);
    end
    if exist(testDataFolder, 'dir') == 7
        rmdir(testDataFolder);
    end
    disp('测试数据清理完成');
catch
    disp('警告: 部分测试数据清理失败');
end

disp('');
disp('要手动验证结果，请检查:');
disp(['1. 结果文件: ', testSaveFileName]);
disp('2. 日志文件: integration_process_log.txt');
disp('');
disp('所有测试已完成！');