% 简单的MATLAB保存功能测试脚本 - 结果写入日志

% 创建日志文件
logFile = fopen('test_save_log.txt', 'w');
fprintf(logFile, '=== MATLAB 保存功能测试开始 ===\n');
fprintf(logFile, '当前时间: %s\n', datestr(now));

% 创建测试数据
testData = struct('field1', rand(100), 'field2', 'test string');
testFileName = 'test_simple_save.mat';

fprintf(logFile, '\n开始测试保存功能...\n');
fprintf(logFile, '文件名: %s\n', testFileName);

% 尝试保存
try
    save(testFileName, 'testData');
    fprintf(logFile, '基本保存命令执行成功\n');
    
    % 检查文件是否存在
    if exist(testFileName, 'file') == 2
        fileInfo = dir(testFileName);
        fprintf(logFile, '文件已创建，大小: %.2f KB\n', fileInfo.bytes/1024);
        
        % 尝试读取文件
        try
            loadedData = load(testFileName);
            fprintf(logFile, '文件读取成功！\n');
            fprintf(logFile, '验证数据: %s\n', loadedData.testData.field2);
            fprintf(logFile, '基本保存和读取功能正常工作！\n');
        catch readError
            fprintf(logFile, '读取失败: %s\n', readError.message);
        end
    else
        fprintf(logFile, '错误: 文件未创建\n');
    end
    
    % 尝试v7.3格式
    fprintf(logFile, '\n尝试使用-v7.3格式...\n');
    try
        save(testFileName, 'testData', '-v7.3');
        fprintf(logFile, '-v7.3格式保存成功\n');
    catch v73Error
        fprintf(logFile, '-v7.3格式保存失败: %s\n', v73Error.message);
    end
    
    % 尝试保存到新文件名
    fprintf(logFile, '\n尝试保存到新文件名...\n');
    newFileName = 'new_test_file.mat';
    try
        save(newFileName, 'testData');
        fprintf(logFile, '保存到新文件成功: %s\n', newFileName);
        if exist(newFileName, 'file') == 2
            fprintf(logFile, '新文件已确认创建\n');
            delete(newFileName);
        end
    catch newFileError
        fprintf(logFile, '保存到新文件失败: %s\n', newFileError.message);
    end
    
catch saveError
    fprintf(logFile, '保存失败: %s\n', saveError.message);
    fprintf(logFile, '错误ID: %s\n', saveError.identifier);
end

% 清理测试文件
if exist(testFileName, 'file') == 2
    delete(testFileName);
    fprintf(logFile, '\n已删除测试文件: %s\n', testFileName);
end

fprintf(logFile, '\n=== 测试结束 ===\n');
fclose(logFile);

% 也显示到命令窗口
disp('测试完成，结果已写入 test_save_log.txt');