% 超简单的MATLAB保存测试脚本

% 显示基本信息
disp('=== 简单保存测试 ===');
disp('当前时间: ');
disp(datestr(now));

% 创建简单测试数据
disp('\n创建测试数据...');
testStruct.field1 = rand(100);
testStruct.field2 = '测试字符串';
testStruct.timestamp = datestr(now);

% 生成文件名
timestamp = datestr(now, 'yyyymmdd_HHMMSS');
testFileName = ['simple_test_', timestamp, '.mat'];
disp(['\n准备保存到: ', testFileName]);

% 尝试保存
try
    save(testFileName, 'testStruct', '-v7.3');
    disp('✓ 保存命令执行成功');
    
    % 检查文件是否存在
    if exist(testFileName, 'file') == 2
        fileInfo = dir(testFileName);
        disp(['✓ 文件已创建，大小: ', num2str(fileInfo.bytes/1024, '%.2f'), ' KB']);
        
        % 尝试读取文件
        try
            disp('\n尝试读取文件...');
            loadedData = load(testFileName);
            disp('✓ 文件读取成功！');
            disp(['验证数据: ', loadedData.testStruct.field2]);
            disp('✓ 测试完全成功！MATLAB保存和读取功能正常！');
        catch readError
            disp(['✗ 读取失败: ', readError.message]);
        end
    else
        disp('✗ 错误: 文件未创建');
    end
    
catch saveError
    disp(['✗ 保存失败: ', saveError.message]);
    disp(['错误ID: ', saveError.identifier]);
end

disp('\n测试完成。');