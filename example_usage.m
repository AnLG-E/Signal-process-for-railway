% 铁路信号数据整合示例脚本
% 这个脚本展示了如何使用增强版integrateMatFiles函数处理铁路信号数据

% 显示欢迎信息
disp('====================================================');
disp('           铁路信号数据整合工具');
disp('====================================================');
disp('这个脚本将整合指定文件夹中的所有.mat文件，并自动保存为可靠格式');
disp('增强版功能包括:');
disp('  • 内置保存功能，确保文件格式兼容性');
disp('  • 详细的处理日志');
disp('  • 自动验证保存文件的完整性');
disp('  • 错误处理和恢复机制');
disp('====================================================');

% 设置根文件夹路径
rootFolder = 'F:\\GDB';
disp(['\n根文件夹: ', rootFolder]);
disp('正在自动开始处理...')

% 使用新的integrateMatFiles函数，启用自动保存功能
try
    % 调用函数并启用保存功能
    % 会自动使用-v7.3格式保存，以支持大文件和确保兼容性
    disp('\n开始数据整合和保存...');
    disp('这可能需要一些时间，请耐心等待...');
    integratedData = integrateMatFiles(rootFolder, 'SaveToFile', true);
    
    % 整合完成后显示使用说明
    disp('\n====================================================');
    disp('             操作完成!');
    disp('====================================================');
    disp('整合数据已成功保存到带有时间戳的.mat文件');
    disp('\n=== 使用说明 ===');
    disp('要加载保存的数据，请使用以下命令:');
    disp('  data = load(''integrated_railway_*.mat'');');
    disp('  integratedData = data.integratedData;');
    
    % 演示如何查看数据结构
    disp('\n=== 数据结构说明 ===');
    disp('integratedData包含以下部分:');
    disp('  • .metaData - 整合信息和统计数据');
    disp('  • .[folderName] - 按文件夹组织的数据');
    
    % 获取文件夹列表（排除metaData）
    folderNames = fieldnames(integratedData);
    folderNames = folderNames(strcmp(folderNames, 'metaData') == 0);
    
    if ~isempty(folderNames)
        disp('\n整合的文件夹示例:');
        maxFoldersToShow = min(3, length(folderNames)); % 最多显示3个
        for i = 1:maxFoldersToShow
            folderName = folderNames{i};
            fileCount = length(fieldnames(integratedData.(folderName)));
            disp(['  • ', folderName, ' (', num2str(fileCount), ' 个文件)']);
        end
        if length(folderNames) > maxFoldersToShow
            disp(['  • ... 等', num2str(length(folderNames) - maxFoldersToShow), '个文件夹']);
        end
    end
    
    disp('\n=== 访问数据示例 ===');
    if ~isempty(folderNames)
        firstFolder = folderNames{1};
        firstFolderFiles = fieldnames(integratedData.(firstFolder));
        if ~isempty(firstFolderFiles)
            firstFile = firstFolderFiles{1};
            disp(['\n访问示例文件: integratedData.', firstFolder, '.', firstFile]);
            disp('访问原始文件名: integratedData.', firstFolder, '.', firstFile, '.originalFileName');
            disp('访问文件路径: integratedData.', firstFolder, '.', firstFile, '.filePath');
        end
    end
    
    % 显示日志信息
    disp('\n=== 日志信息 ===');
    disp('详细处理日志已保存到: integration_process_log.txt');
    disp('请查看日志文件了解完整的处理过程和可能的错误信息');
    
    % 提示用户可以安全退出
    disp('\n=== 完成 ===');
    disp('数据处理已完成，您可以安全地退出MATLAB。');
    
    % 如果有失败的文件，提醒用户
    if integratedData.metaData.failCount > 0
        warning('在处理过程中，有 %d 个文件加载失败。请查看日志文件了解详情。', ...
            integratedData.metaData.failCount);
    end
    
    catch ME
    % 显示错误信息
    disp('\n====================================================');
    disp('                  错误!');
    disp('====================================================');
    disp(['错误消息: ', ME.message]);
    disp('\n请检查以下几点:');
    disp('  1. 确保根文件夹路径正确');
    disp('  2. 确保有足够的磁盘空间');
    disp('  3. 检查MATLAB权限是否足够');
    disp('  4. 查看integration_process_log.txt获取详细日志');
    
    % 重新抛出错误以便在命令窗口中显示完整堆栈
    rethrow(ME);
end

% 额外的辅助函数：显示文件夹内容
function showFolderContents(integratedData, folderName)
    if isfield(integratedData, folderName)
        files = fieldnames(integratedData.(folderName));
        disp(['\n文件夹 "', folderName, '" 包含 ', num2str(length(files)), ' 个文件:']);
        for i = 1:length(files)
            originalName = integratedData.(folderName).(files{i}).originalFileName;
            disp(['  ', num2str(i), '. ', originalName]);
        end
    else
        disp(['错误: 文件夹 "', folderName, '" 不存在']);
    end
end