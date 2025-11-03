% 测试加载已生成的MAT文件

disp('开始测试加载MAT文件...');

% 尝试加载最新生成的文件
try
    % 查找带时间戳的integrated_data文件
    fileList = dir('integrated_data_*.mat');
    
    if isempty(fileList)
        disp('错误: 未找到带时间戳的integrated_data文件');
    else
        % 按修改时间排序，获取最新的文件
        [~, idx] = sort([fileList.datenum], 'descend');
        latestFile = fileList(idx(1)).name;
        
        disp(['正在尝试加载文件: ', latestFile]);
        
        % 尝试加载文件的元数据部分（较小，加载更快）
        try
            disp('尝试加载元数据...');
            metaData = load(latestFile, 'integratedData.metaData');
            disp('元数据加载成功！');
            disp(['根文件夹: ', metaData.integratedData.metaData.rootFolder]);
            disp(['文件总数: ', num2str(metaData.integratedData.metaData.totalFiles)]);
            disp('文件可读，保存成功！');
        catch metaError
            disp(['加载元数据失败: ', metaError.message]);
            
            % 尝试加载整个文件
            try
                disp('尝试加载整个文件...');
                fullData = load(latestFile);
                disp('整个文件加载成功！');
                disp(['数据结构: ', class(fullData.integratedData)]);
            catch fullError
                disp(['加载整个文件失败: ', fullError.message]);
            end
        end
    end
    
catch generalError
    disp(['发生错误: ', generalError.message]);
end

disp('测试完成。');