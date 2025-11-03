% INTEGRATEMATFILES 从指定文件夹中抽取所有子文件夹内的.mat文件并整合数据
%   integratedData = INTEGRATEMATFILES(rootFolder) 从指定的rootFolder目录开始，
%   递归查找所有子文件夹中的.mat文件，加载文件内容，并将数据整合到一个统一的结构体中
%   
%   输入参数：
%       rootFolder - 字符串，表示要搜索.mat文件的根文件夹路径
%   
%   输出参数：
%       integratedData - 结构体，整合后的数据组织如下：
%           - 第一层按文件夹名组织（字段名为合法的MATLAB标识符）
%           - 第二层按文件名组织（字段名为合法的MATLAB标识符）
%           - 第三层包含原始数据变量、originalFileName（原始文件名）和filePath（文件路径）
%           - 顶层包含metaData字段，记录整合信息
%   
%   示例：
%       data = integrateMatFiles('F:\\GDB');
%       % 访问k13文件夹中K13+047.mat文件的数据
%       vibData = data.k13.K13_047.vib_data;
%       
%   注意：
%       - 文件名和文件夹名中的非法字符会被转换为合法的MATLAB字段名
%       - 原始文件名会被保存，可通过originalFileName字段访问
%       - 单个文件加载失败不会影响整体处理，错误信息会被记录

function integratedData = integrateMatFiles(rootFolder, varargin)
% INTEGRATEMATFILES - 从指定文件夹递归整合所有.mat文件到统一数据结构（增强版）
%   integratedData = INTEGRATEMATFILES(rootFolder) 从指定的根文件夹开始,
%   递归搜索所有子文件夹中的.mat文件，并将它们整合到一个结构化的MATLAB变量中。
%   
%   参数:
%       rootFolder - 字符串，表示要搜索的根文件夹路径
%       'SaveToFile' - 可选，逻辑值，指定是否自动保存结果（默认false）
%       'SaveFileName' - 可选，字符串，指定保存文件名（默认自动生成）
%       'MaxFileSize' - 可选，数值，指定最大处理文件大小（MB）
%       'ProgressSave' - 可选，逻辑值，是否启用进度保存（默认true）
%   
%   返回值:
%       integratedData - 结构体，包含所有整合的数据
%           .metaData - 元数据，包含整合信息
%           .[folderName] - 按文件夹组织的子结构体
%               .[fileName] - 按文件名组织的数据，保留原始文件名信息
%                   .originalFileName - 原始文件名
%                   .filePath - 文件完整路径
%                   .[dataFields] - 原始.mat文件中的数据字段
%   
%   示例:
%       % 基本使用
%       data = integrateMatFiles('F:\\GDB');
%       
%       % 自动保存结果
%       data = integrateMatFiles('F:\\GDB', 'SaveToFile', true);
%       
%       % 指定保存文件名
%       data = integrateMatFiles('F:\\GDB', 'SaveToFile', true, 'SaveFileName', 'my_data.mat');
%       
%   增强功能:
%       - 内置保存功能，使用-v7.3格式确保大文件兼容性
%       - 详细的处理日志和错误追踪
%       - 文件完整性自动验证
%       - 进度保存，防止处理中断数据丢失
%       - 大文件处理优化

    % 解析输入参数
    saveToFile = false;
    saveFileName = '';
    maxFileSizeMB = Inf;  % 默认不限制
    progressSave = true;  % 默认启用进度保存

    % 处理可变参数
    i = 1;
    while i <= length(varargin)
        if strcmpi(varargin{i}, 'SaveToFile') && i+1 <= length(varargin)
            saveToFile = logical(varargin{i+1});
            i = i + 2;
        elseif strcmpi(varargin{i}, 'SaveFileName') && i+1 <= length(varargin)
            saveFileName = varargin{i+1};
            i = i + 2;
        elseif strcmpi(varargin{i}, 'MaxFileSize') && i+1 <= length(varargin)
            maxFileSizeMB = varargin{i+1};
            i = i + 2;
        elseif strcmpi(varargin{i}, 'ProgressSave') && i+1 <= length(varargin)
            progressSave = logical(varargin{i+1});
            i = i + 2;
        else
            i = i + 1;
        end
    end
    
    % 初始化结果结构体和必要的变量
    integratedData = struct();
    logFile = [];
    progressFileName = '';
    fileProcessed = 0;
    progressInterval = 10;  % 每处理10个文件保存一次进度
    
    % 确保即使在错误情况下也能关闭文件和清理
    cleanupObj = onCleanup(@()cleanupResources(logFile, progressFileName));

    % 创建日志文件
    try
        logFile = fopen('integration_process_log.txt', 'w');
        if logFile == -1
            warning('无法创建日志文件，将只显示控制台输出');
        else
            fprintf(logFile, '=== MATLAB数据整合过程日志 ===\n');
            fprintf(logFile, '开始时间: %s\n', datestr(now));
            fprintf(logFile, '根文件夹: %s\n', rootFolder);
            fprintf(logFile, '参数设置: SaveToFile=%d, MaxFileSize=%.1fMB, ProgressSave=%d\n', ...
                saveToFile, maxFileSizeMB, progressSave);
        end
        logMessage(logFile, '初始化完成，开始处理...');
    catch ME
        warning(ME.identifier, '%s', ME.message);
        logFile = [];
    end

    % 验证输入参数
    if ~ischar(rootFolder) && ~isstring(rootFolder)
        logMessage(logFile, '错误: 根文件夹路径必须是字符串或字符串数组。');
        error('根文件夹路径必须是字符串或字符串数组。');
    end
    
    if ~isfolder(rootFolder)
        logMessage(logFile, sprintf('错误: 指定的路径不是有效文件夹: %s', rootFolder));
        error('指定的路径不是有效文件夹: %s', rootFolder);
    end

    % 创建进度保存文件名（如果启用）
    if progressSave
        progressFileName = 'integration_progress.mat';
        logMessage(logFile, sprintf('启用进度保存: %s', progressFileName));
    end

    % 创建元数据
    integratedData.metaData = struct();
    integratedData.metaData.rootFolder = rootFolder;
    integratedData.metaData.integrationTime = datestr(now);
    integratedData.metaData.folderCount = 0;
    integratedData.metaData.totalFiles = 0;
    integratedData.metaData.successCount = 0;
    integratedData.metaData.failCount = 0;
    integratedData.metaData.failedFiles = {};
    integratedData.metaData.startTime = datestr(now);
    
    % 主要处理逻辑开始，使用try块包裹整个处理过程
    try
        % 生成文件列表（按文件夹分组）
        logMessage(logFile, '生成文件列表...');
        try
            fileListStruct = generateFileListByFolder(rootFolder, '.mat');
            logMessage(logFile, '文件列表生成成功！');
        
        % 获取所有文件夹字段名
        folderFields = fieldnames(fileListStruct);
        
        % 如果没有找到任何.mat文件
        if isempty(folderFields)
            logMessage(logFile, sprintf('警告: 在指定路径中未找到任何.mat文件: %s', rootFolder));
            warning('在指定路径中未找到任何.mat文件: %s', rootFolder);
            
            % 确保文件夹结构正确关闭
            if logFile > 0
                fclose(logFile);
                logFile = [];
            end
            return;
        end
        
        % 记录文件夹数量
        integratedData.metaData.folderCount = length(folderFields);
        
        % 统计总文件数
        totalFiles = 0;
        for i = 1:length(folderFields)
            totalFiles = totalFiles + length(fileListStruct.(folderFields{i}));
        end
        integratedData.metaData.totalFiles = totalFiles;
        logMessage(logFile, sprintf('找到 %d 个包含.mat文件的文件夹', integratedData.metaData.folderCount));
        logMessage(logFile, sprintf('总共找到 %d 个.mat文件', totalFiles));
        
    catch ME
        logMessage(logFile, sprintf('生成文件列表失败: %s', ME.message));
        error('生成文件列表失败: %s', ME.message);
    end
    
    % 遍历每个文件夹
    for folderIdx = 1:length(folderFields)
        folderName = folderFields{folderIdx};
        fileList = fileListStruct.(folderName);
        
        logMessage(logFile, sprintf('\n处理文件夹 %d/%d: %s', folderIdx, length(folderFields), folderName));
        logMessage(logFile, sprintf('包含 %d 个.mat文件', length(fileList)));
        
        try
            % 为当前文件夹创建子结构体
            integratedData.(folderName) = struct();
            
            % 遍历当前文件夹中的所有.mat文件
            for fileIdx = 1:length(fileList)
                filePath = fileList{fileIdx};
                [~, fileName, ~] = fileparts(filePath);
                
                % 获取文件大小
                fileInfo = dir(filePath);
                fileSizeMB = fileInfo.bytes / (1024^2);
                
                logMessage(logFile, sprintf('  处理文件 %d/%d: %s (%.2f MB)', ...
                    fileIdx, length(fileList), fileName, fileSizeMB));
                
                % 检查文件大小限制
                if fileSizeMB > maxFileSizeMB
                    logMessage(logFile, sprintf('    ⚠ 跳过: 文件超过大小限制 %.2f MB', maxFileSizeMB));
                    continue;
                end
                
                % 将文件名转换为合法的结构体字段名
                validFileName = matlab.lang.makeValidName(fileName);
                
                % 初始化文件结构体
                integratedData.(folderName).(validFileName) = struct();
                integratedData.(folderName).(validFileName).originalFileName = fileName;
                integratedData.(folderName).(validFileName).filePath = filePath;
                
                try
                    % 对于大文件，使用更安全的加载方法
                    if fileSizeMB > 100  % 大于100MB的文件
                        logMessage(logFile, '    正在加载大文件...');
                        % 使用matfile函数部分加载，避免内存问题
                        matObj = matfile(filePath);
                        fileVars = who(matObj);
                        
                        % 逐个加载变量
                        for varIdx = 1:length(fileVars)
                            varName = fileVars{varIdx};
                            try
                                integratedData.(folderName).(validFileName).(varName) = matObj.(varName);
                            catch varError
                                logMessage(logFile, sprintf('      ⚠ 加载变量 %s 失败: %s', varName, varError.message));
                                integratedData.(folderName).(validFileName).(sprintf('%s_error', varName)) = varError.message;
                            end
                        end
                    else
                        % 小文件直接加载
                        fileData = load(filePath);
                        fileVars = fieldnames(fileData);
                        
                        % 复制所有变量到整合结构体
                        for varIdx = 1:length(fileVars)
                            varName = fileVars{varIdx};
                            integratedData.(folderName).(validFileName).(varName) = fileData.(varName);
                        end
                    end
                    
                    % 记录成功
                    integratedData.metaData.successCount = integratedData.metaData.successCount + 1;
                    logMessage(logFile, '    ✓ 成功');
                    
                catch ME
                    % 记录失败信息
                    integratedData.metaData.failCount = integratedData.metaData.failCount + 1;
                    integratedData.metaData.failedFiles{end+1} = filePath;
                    integratedData.(folderName).(validFileName).loadError = ME.message;
                    logMessage(logFile, sprintf('    ✗ 失败: %s', ME.message));
                end
                
                % 增加处理文件计数
                fileProcessed = fileProcessed + 1;
                
                % 进度保存
                if progressSave && mod(fileProcessed, progressInterval) == 0
                    try
                        save(progressFileName, 'integratedData');
                        logMessage(logFile, sprintf('    💾 进度保存 (%d/%d)', fileProcessed, totalFiles));
                    catch progressError
                        logMessage(logFile, sprintf('    ⚠ 进度保存失败: %s', progressError.message));
                    end
                end
                
                % 每处理一个文件都强制刷新日志
                if logFile > 0
                    fflush(logFile);
                end
            end
            
        catch folderError
            logMessage(logFile, sprintf('  ✗ 处理文件夹失败: %s', folderError.message));
        end
    end
    
    % 更新元数据信息
    integratedData.metaData.integrationTime = datestr(now);
    integratedData.metaData.endTime = datestr(now);
    
    % 记录整合完成信息
    logMessage(logFile, '\n=== 整合完成 ===');
    logMessage(logFile, sprintf('总文件夹数: %d', integratedData.metaData.folderCount));
    logMessage(logFile, sprintf('总文件数: %d', integratedData.metaData.totalFiles));
    logMessage(logFile, sprintf('成功: %d', integratedData.metaData.successCount));
    logMessage(logFile, sprintf('失败: %d', integratedData.metaData.failCount));

    if integratedData.metaData.failCount > 0
        logMessage(logFile, '\n失败的文件列表:');
        for i = 1:length(integratedData.metaData.failedFiles)
            logMessage(logFile, sprintf('  - %s', integratedData.metaData.failedFiles{i}));
        end
    end

    % 如果需要保存结果
    if saveToFile
        logMessage(logFile, '\n=== 开始保存数据 ===');
        
        % 生成保存文件名（如果未指定）
        if isempty(saveFileName)
            timestamp = datestr(now, 'yyyymmdd_HHMMSS');
            saveFileName = ['integrated_railway_', timestamp, '.mat'];
        end
        
        logMessage(logFile, sprintf('保存到: %s', saveFileName));
        
        % 直接保存数据，使用-v7.3格式
        try
            save(saveFileName, 'integratedData', '-v7.3');
            logMessage(logFile, '✓ 数据保存命令执行成功');
            
            % 验证保存是否成功
            if exist(saveFileName, 'file') == 2
                fileSize = dir(saveFileName).bytes / (1024^2); % MB
                logMessage(logFile, sprintf('✓ 文件已创建，大小: %.2f MB', fileSize));
                
                % 尝试快速验证文件可读取性
                try
                    meta = load(saveFileName, 'integratedData.metaData');
                    logMessage(logFile, '✓ 文件验证成功，可以正常读取');
                    
                    % 显示成功消息
                    disp(['✓ 数据已成功保存到: ', saveFileName]);
                    disp(['  文件大小: ', num2str(fileSize, '%.2f'), ' MB']);
                    
                catch loadError
                    logMessage(logFile, sprintf('⚠ 文件存在但验证读取失败: %s', loadError.message));
                    warning(loadError.identifier, '%s', loadError.message);
                end
            else
                logMessage(logFile, '✗ 错误: 保存命令执行但文件未创建');
                warning('保存命令执行但文件未创建！');
            end
            
        catch saveError
            logMessage(logFile, sprintf('✗ 保存失败: %s', saveError.message));
            warning(saveError.identifier, '%s', saveError.message);
            
            % 尝试使用更简单的格式保存
            try
                logMessage(logFile, '尝试使用基本格式重新保存...');
                save(saveFileName, 'integratedData');
                logMessage(logFile, '✓ 使用基本格式保存成功');
            catch retryError
                logMessage(logFile, sprintf('✗ 重新保存失败: %s', retryError.message));
            end
        end
        
        logMessage(logFile, '=== 保存操作完成 ===');
    end

    % 如果有进度文件且整合完成，删除进度文件
    if progressSave && exist(progressFileName, 'file') == 2
        try
            delete(progressFileName);
            logMessage(logFile, sprintf('清理进度文件: %s', progressFileName));
        catch
            % 忽略删除错误
        end
    end

    % 完成日志
    logMessage(logFile, sprintf('\n结束时间: %s', datestr(now)));
    logMessage(logFile, '====================');
    
    % 显示基本统计信息
    disp('=== 数据整合完成 ===');
    disp(['文件夹数: ', num2str(integratedData.metaData.folderCount)]);
    disp(['文件总数: ', num2str(integratedData.metaData.totalFiles)]);
    disp(['成功: ', num2str(integratedData.metaData.successCount)]);
    disp(['失败: ', num2str(integratedData.metaData.failCount)]);
    disp('详细日志已保存到: integration_process_log.txt');
    
    % 如果有保存的文件，提示如何使用
    if saveToFile && exist(saveFileName, 'file') == 2
        disp(['\n已保存文件: ', saveFileName]);
        disp('要加载数据，请使用: load(''filename'')');
    end
    
    % 正常退出前关闭日志文件
    if logFile > 0
        fclose(logFile);
        logFile = [];
    end
    
    return;
    
    % 处理任何未捕获的错误
    catch ME
        % 记录错误
        logMessage(logFile, sprintf('\n❌ 发生未捕获的错误: %s', ME.message));
        logMessage(logFile, sprintf('错误ID: %s', ME.identifier));
        
        % 尝试保存当前进度
        if progressSave && ~isempty(integratedData)
            try
                save(progressFileName, 'integratedData');
                logMessage(logFile, '已保存当前进度到integration_progress.mat');
            catch
                % 忽略保存错误
            end
        end
        
        % 完成日志
        if logFile > 0
            fprintf(logFile, '\n异常终止时间: %s\n', datestr(now));
            fprintf(logFile, '====================\n');
            fclose(logFile);
        end
        
        % 抛出错误
        error('数据整合过程中发生错误: %s', ME.message);
    end
end
% 辅助函数：同时向控制台和日志文件输出消息
function logMessage(logFile, message)
    % 同时向控制台和日志文件输出消息
    disp(message);
    if logFile > 0
        fprintf(logFile, '%s\n', message);
        fflush(logFile);  % 立即刷新到文件
    end
end

% 辅助函数：清理资源
function cleanupResources(logFile, progressFile)
    % 清理资源的函数，由onCleanup对象调用
    % 关闭日志文件
    if logFile > 0
        try
            fprintf(logFile, '\n资源清理\n');
            fclose(logFile);
        catch
            % 忽略关闭错误
        end
    end
end

% 辅助函数：按文件夹分组生成文件列表
function fileStruct = generateFileListByFolder(folderPath, fileExtension)
    % 确保扩展名格式正确
    if fileExtension(1) ~= '.'
        fileExtension = ['.' fileExtension];
    end
    
    % 递归查找所有指定扩展名的文件
    files = dir(fullfile(folderPath, '**', ['*' fileExtension]));
    files = files(~[files.isdir]); % 排除文件夹
    
    % 如果没有找到文件，返回空结构体
    if isempty(files)
        fileStruct = struct();
        return;
    end
    
    % 按文件夹分组
    folderNames = unique({files.folder}); % 获取唯一文件夹名
    fileStruct = struct();
    
    for i = 1:numel(folderNames)
        thisFolder = folderNames{i};
        idx = strcmp({files.folder}, thisFolder);
        
        % 创建文件完整路径列表
        fileList = fullfile({files(idx).folder}, {files(idx).name});
        
        % 生成相对路径作为字段名（处理非法字符）
        relName = strrep(thisFolder, [folderPath filesep], '');
        if isempty(relName)
            relName = filesep;
        end
        
        fieldName = matlab.lang.makeValidName(relName);
        fileStruct.(fieldName) = fileList;
    end
end