% 简单的MATLAB保存功能测试脚本

% 创建测试数据
testData = struct('field1', rand(100), 'field2', 'test string');
testFileName = 'test_simple_save.mat';

disp(['开始测试保存功能...']);
disp(['文件名: ', testFileName]);

% 尝试保存
try
    save(testFileName, 'testData', '-v7.3');
    disp('保存命令执行成功');
    
    % 检查文件是否存在
    if exist(testFileName, 'file') == 2
        fileInfo = dir(testFileName);
        disp(['文件已创建，大小: ', num2str(fileInfo.bytes/1024, '%.2f'), ' KB']);
        
        % 尝试读取文件
        try
            loadedData = load(testFileName);
            disp('文件读取成功！');
            disp(['验证数据: ', loadedData.testData.field2]);
            disp('保存和读取功能正常工作！');
        catch readError
            disp(['读取失败: ', readError.message]);
        end
    else
        disp('错误: 文件未创建');
    end
    
catch saveError
    disp(['保存失败: ', saveError.message]);
    disp(['错误ID: ', saveError.identifier]);
    
    % 尝试不使用-v7.3选项
    disp('\n尝试不使用-v7.3选项...');
    try
        save(testFileName, 'testData');
        disp('不使用-v7.3选项保存成功');
    catch
        disp('不使用-v7.3选项也保存失败');
    end
end

% 清理测试文件
if exist(testFileName, 'file') == 2
    delete(testFileName);
    disp(['已删除测试文件: ', testFileName]);
end