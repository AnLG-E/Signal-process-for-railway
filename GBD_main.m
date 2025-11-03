% 生成一个顺序读取的文件列表
function fileStruct = generateFileListByFolder(folderPath, fileExtension)
    % 支持递归查找子文件夹中的指定扩展名文件，并按文件夹分组
    % 防止文件夹名中有非法字符，使用matlab.lang.makeValidName进行转换
    if isempty(fileExtension)
        error('fileExtension 不能为空。');
    end

    % 确保扩展名前有点号
    if fileExtension(1) ~= '.'
        fileExtension = ['.' fileExtension];
    end

    % 获取所有指定扩展名的文件
    files = dir(fullfile(folderPath, '**', ['*' fileExtension]));
    files = files(~[files.isdir]);

    % 如果没有找到任何文件，返回空结构体
    if isempty(files)
        fileStruct = struct();
        return;
    end

    % 按文件夹分组（保留绝对路径用于对比，但用相对路径生成字段名）
    folderNames = unique({files.folder});                       % 获取唯一文件夹名（绝对路径）
    fileStruct = struct();                                      % 初始化输出结构体
    for i = 1:numel(folderNames)                                % 遍历每个文件夹
        thisFolder = folderNames{i};                            % 绝对路径
        idx = strcmp({files.folder}, thisFolder);               % 找出属于当前文件夹的文件
        % 以当前文件夹的名称创建文件列表（使用完整路径字符串）
        fileList = fullfile({files(idx).folder}, {files(idx).name});
        % 生成相对于输入 folderPath 的字段名（非法字符替换为下划线）
        relName = strrep(thisFolder, [folderPath filesep], '');
        if isempty(relName)
            % 若文件就在根目录，使用根目录名作为字段名
            relName = filesep;
        end
        fieldName = matlab.lang.makeValidName(relName);        % 转换为合法字段名
        % 将对应的.mat文件路径列表存入结构体
        fileStruct.(fieldName) = fileList;
    end
end

% 整合多个子文件夹中的mat文件数据到一个统一的结构体中
function integratedData = integrateMatFilesData(folderPath)
    % 整合指定目录下所有子文件夹中的mat文件数据
    % 输入参数：
    %   folderPath - 根文件夹路径
    % 输出参数：
    %   integratedData - 整合后的结构体，按文件夹和文件名组织数据
    
    % 生成文件列表
    fileListStruct = generateFileListByFolder(folderPath, '.mat');
    
    % 初始化整合数据结构体
    integratedData = struct();
    
    % 获取所有文件夹字段名
    folderFields = fieldnames(fileListStruct);
    
    % 遍历每个文件夹
    for i = 1:length(folderFields)
        folderName = folderFields{i};
        fileList = fileListStruct.(folderName);
        
        % 为每个文件夹创建一个子结构体
        integratedData.(folderName) = struct();
        
        % 遍历该文件夹下的所有mat文件
        for j = 1:length(fileList)
            filePath = fileList{j};
            [~, fileName, ~] = fileparts(filePath);
            
            try
                % 加载mat文件数据
                fileData = load(filePath);
                
                % 获取mat文件中的所有变量
                fileVars = fieldnames(fileData);
                
                % 将文件名转换为合法的结构体字段名
                validFileName = matlab.lang.makeValidName(fileName);
                
                % 为每个文件创建一个子结构体
                integratedData.(folderName).(validFileName) = struct();
                
                % 保存原始文件名
                integratedData.(folderName).(validFileName).originalFileName = fileName;
                
                % 复制所有变量到整合结构体中
                for k = 1:length(fileVars)
                    varName = fileVars{k};
                    integratedData.(folderName).(validFileName).(varName) = fileData.(varName);
                end
                
                % 保存文件路径信息
                integratedData.(folderName).(validFileName).filePath = filePath;
                
            catch ME
                % 处理加载错误，记录错误信息但继续处理其他文件
                warning('无法加载文件 %s: %s', filePath, ME.message);
                validFileName = matlab.lang.makeValidName(fileName);
                integratedData.(folderName).(validFileName) = struct();
                integratedData.(folderName).(validFileName).originalFileName = fileName;
                integratedData.(folderName).(validFileName).loadError = ME.message;
                integratedData.(folderName).(validFileName).filePath = filePath;
            end
        end
    end
    
    % 添加元数据信息
    integratedData.metaData.integrationTime = datestr(now);
    integratedData.metaData.rootFolder = folderPath;
    integratedData.metaData.folderCount = length(folderFields);
    
    % 统计总文件数
    totalFiles = 0;
    for i = 1:length(folderFields)
        folderName = folderFields{i};
        totalFiles = totalFiles + length(fileListStruct.(folderName));
    end
    integratedData.metaData.totalFiles = totalFiles;
end

% 主程序示例
folderPath = 'F:\GDB';

% 创建日志文件（使用新文件名避免冲突）
logFileName = ['integration_log_', datestr(now, 'yyyymmdd_HHMMSS'), '.txt'];
logFile = fopen(logFileName, 'w');
fprintf(logFile, '开始执行数据整合程序...\n');
fprintf(logFile, '日志文件: %s\n', logFileName);

% 方法1：仅获取文件列表
fprintf(logFile, '\n1. 生成文件列表...\n');
fileList = generateFileListByFolder(folderPath, '.mat');
fprintf(logFile, '文件列表按文件夹分组结果：\n');
folderFields = fieldnames(fileList);
for i = 1:length(folderFields)
    folderName = folderFields{i};
    fprintf(logFile, '  文件夹: %s\n', folderName);
    fileCount = length(fileList.(folderName));
    fprintf(logFile, '    包含文件数: %d\n', fileCount);
    % 显示前3个文件作为示例
    for j = 1:min(3, fileCount)
        fprintf(logFile, '    - %s\n', fileList.(folderName){j});
    end
    if fileCount > 3
        fprintf(logFile, '    ... 等%d个文件\n', fileCount - 3);
    end
end

% 方法2：整合所有mat文件数据
fprintf(logFile, '\n2. 开始整合mat文件数据...\n');
try
    integratedData = integrateMatFilesData(folderPath);
    
    fprintf(logFile, '\n整合后的数据结构体信息：\n');
    fprintf(logFile, '总文件夹数: %d\n', integratedData.metaData.folderCount);
    fprintf(logFile, '总文件数: %d\n', integratedData.metaData.totalFiles);
    fprintf(logFile, '整合时间: %s\n', integratedData.metaData.integrationTime);
    
    % 显示整合结构体的层次结构
    fprintf(logFile, '\n整合结构体的层次结构：\n');
    hierarchyStr = structHierarchy(integratedData);
    fprintf(logFile, '%s', hierarchyStr);
    
    % 保存整合后的数据到mat文件
    save('integrated_railway_data.mat', 'integratedData');
    fprintf(logFile, '\n整合后的数据已保存到: integrated_railway_data.mat\n');
    
    % 显示部分数据内容示例
    fprintf(logFile, '\n3. 数据内容示例：\n');
    if length(folderFields) > 0
        firstFolder = folderFields{1};
        firstFolderFiles = fieldnames(integratedData.(firstFolder));
        if length(firstFolderFiles) > 0
            firstFile = firstFolderFiles{1};
            % 检查是否有原始文件名信息
            if isfield(integratedData.(firstFolder).(firstFile), 'originalFileName')
                fprintf(logFile, '示例文件: %s/%s (存储为: %s)\n', ...
                        firstFolder, integratedData.(firstFolder).(firstFile).originalFileName, firstFile);
            else
                fprintf(logFile, '示例文件: %s/%s\n', firstFolder, firstFile);
            end
            fileFields = fieldnames(integratedData.(firstFolder).(firstFile));
            fprintf(logFile, '  包含字段数量: %d\n', length(fileFields));
            fprintf(logFile, '  字段列表: ');
            for k = 1:length(fileFields)
                fprintf(logFile, '%s ', fileFields{k});
            end
            fprintf(logFile, '\n');
        end
    end
    
    fprintf(logFile, '\n数据整合完成！\n');
    
catch ME
    fprintf(logFile, '错误: %s\n', ME.message);
    fprintf(logFile, '错误堆栈: %s\n', getReport(ME));
end

fclose(logFile);

% 在命令窗口也显示一些基本信息
disp('数据整合程序已执行');
disp(['详细结果请查看: ', logFileName]);
disp('整合后的数据已保存到: integrated_railway_data.mat');

% 辅助函数：显示结构体层次结构
function hierarchy = structHierarchy(s, prefix)
    if nargin < 2
        prefix = '';
    end
    hierarchy = '';
    fields = fieldnames(s);
    for i = 1:length(fields)
        field = fields{i};
        hierarchy = [hierarchy, prefix, field];
        if isstruct(s.(field))
            hierarchy = [hierarchy, ' (结构体)\n'];
            hierarchy = [hierarchy, structHierarchy(s.(field), [prefix, '  '])];
        else
            hierarchy = [hierarchy, ' (', class(s.(field)), ')\n'];
        end
    end
end