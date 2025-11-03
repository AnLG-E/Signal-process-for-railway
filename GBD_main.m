% 生成一个顺序读取的文件列表-erPath, fileExtension)
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

    % 按文件夹分组
    folderNames = unique({files.folder});                       % 获取唯一文件夹名
    fileStruct = struct();                                      % 初始化输出结构体
    for i = 1:numel(folderNames)                                % 遍历每个文件夹
        idx = strcmp({files.folder}, folderNames{i});           % 找出属于当前文件夹的文件
        % 以当前文件夹的名称创建文件列表
        fileList = fullfile({files(idx).folder}, {files(idx).name});
        % 使用文件夹名作为字段名（非法字符替换为下划线）
        fieldName = matlab.lang.makeValidName(folderNames{i});  % 转换为合法字段名
        % 将所文件存入结构体
        fileStruct.(fieldName) = fileList;
    end
end

% 用法:
% 如果我有多个.mat文件存放一个根目录“C:\Users\Liluo\Desktop\轨道板数据”，
% 然后分别放在不同的子文件夹中，我应该怎么调用这个函数来生成一个包含所有.mat文件路径的列表？
folderPath = 'C:\Users\Liluo\Desktop\轨道板数据';
fileExtension = '.mat';
fileList = generateFileListByFolder(folderPath, fileExtension);
disp(fileList);