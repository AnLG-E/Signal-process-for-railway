% 测试增强版integrateMatFiles函数的保存功能

% 设置路径
rootFolder = 'F:\\GDB';

% 直接调用函数并启用保存功能
disp('开始测试增强版integrateMatFiles函数...');
disp(['根文件夹: ', rootFolder]);
disp('启用自动保存功能...');

try
    % 调用函数并启用保存
    % 第三个参数'SaveToFile', true 启用自动保存
    % 第五个参数'SaveFileName' 指定保存文件名
    integratedData = integrateMatFiles(rootFolder, 'SaveToFile', true, 'SaveFileName', 'test_result.mat');
    
    % 显示成功信息
    disp('\n✓ 函数调用成功！');
    disp(['整合了 ', num2str(integratedData.metaData.folderCount), ' 个文件夹']);
    disp(['处理了 ', num2str(integratedData.metaData.totalFiles), ' 个文件']);
    
    % 检查文件是否创建
    if exist('test_result.mat', 'file') == 2
        fileSize = dir('test_result.mat').bytes / (1024^2); % MB
        disp(['\n✓ 文件已保存: test_result.mat (', num2str(fileSize, '%.2f'), ' MB)']);
        
        % 尝试读取文件验证
        try
            loadedData = load('test_result.mat');
            disp('✓ 文件可以正常读取！');
            disp('测试成功完成！');
        catch loadError
            disp(['⚠ 文件存在但读取失败: ', loadError.message]);
        end
    else
        disp('⚠ 文件未创建！请检查日志文件。');
    end
    
    catch ME
    disp(['✗ 测试失败: ', ME.message]);
    disp('请查看integration_process_log.txt获取详细信息。');
end