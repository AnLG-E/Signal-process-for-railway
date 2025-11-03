% 测试脚本 - 验证integrateMatFiles函数修复后的语法结构

% 清除工作空间
clear all;
close all;
clc;

disp('=== 测试修复后的integrateMatFiles函数 ===');
disp('');

try
    % 显示函数信息
    disp('函数信息:');
    help integrateMatFiles;
    disp('');
    
    % 尝试使用小数据集调用函数
    testFolder = fullfile(pwd, 'test_data_small');
    if ~exist(testFolder, 'dir')
        mkdir(testFolder);
    end
    
    % 创建一个小型测试文件
    testData = struct('test', 1, 'data', rand(5,5));
    save(fullfile(testFolder, 'test_small.mat'), 'testData');
    
    disp('创建测试数据完成，开始调用函数...');
    disp('');
    
    % 调用函数，使用小数据集和基本参数
    integratedData = integrateMatFiles(testFolder, ...
        'SaveToFile', false, ...
        'ProgressSave', false);
    
    disp('✓ 函数调用成功！');
    disp('');
    
    % 显示结果信息
    disp('整合结果信息:');
    disp(['文件夹数: ', num2str(integratedData.metaData.folderCount)]);
    disp(['文件数: ', num2str(integratedData.metaData.totalFiles)]);
    disp(['成功: ', num2str(integratedData.metaData.successCount)]);
    disp(['失败: ', num2str(integratedData.metaData.failCount)]);
    
    % 清理测试数据
    delete(fullfile(testFolder, 'test_small.mat'));
    rmdir(testFolder);
    
    disp('');
    disp('=== 测试完成！代码语法结构正确 ===');
    
catch ME
    disp('✗ 测试失败，仍存在错误:');
    disp(['错误消息: ', ME.message]);
    disp(['错误ID: ', ME.identifier]);
    disp(['错误行号: ', num2str(ME.stack.line)]);
    disp(['错误函数: ', ME.stack.name]);
    
    % 清理测试数据
    if exist(testFolder, 'dir') == 7
        if exist(fullfile(testFolder, 'test_small.mat'), 'file') == 2
            delete(fullfile(testFolder, 'test_small.mat'));
        end
        rmdir(testFolder);
    end
end