# 铁路信号数据处理系统

## 项目概述

本项目是一个专门用于处理铁路轨道板信号数据的MATLAB工具集，能够高效整合、处理和分析分布在多个文件夹中的.mat数据文件。系统具备强大的错误处理、进度保存和大文件优化功能，确保在处理大规模数据时的稳定性和可靠性。

## 主要功能

- **数据整合**：递归查找并整合指定文件夹及其子文件夹中的所有.mat文件
- **进度保存**：支持处理中断时保存当前进度，便于从中断点恢复
- **大文件优化**：对超过指定大小的文件采用部分加载策略，避免内存溢出
- **自动保存**：支持将整合结果自动保存为.mat文件，使用-v7.3格式确保大文件兼容性
- **详细日志**：记录完整的处理过程、错误信息和统计数据
- **错误处理**：单个文件处理失败不影响整体流程，自动记录失败原因
- **批处理支持**：完全自动化处理，无需人工干预

## 系统要求

- MATLAB R2018a或更高版本（推荐R2020a+）
- 至少4GB可用内存（处理大文件时建议8GB以上）
- Windows、macOS或Linux操作系统

## 核心函数说明

### `integrateMatFiles` - 主要数据整合函数

```matlab
integratedData = integrateMatFiles(rootFolder, '参数名', 参数值, ...)
```

**输入参数：**

- `rootFolder` - 字符串，表示要搜索.mat文件的根文件夹路径
- `'SaveToFile'` - 可选，逻辑值，指定是否自动保存结果（默认false）
- `'SaveFileName'` - 可选，字符串，指定保存文件名（默认自动生成）
- `'MaxFileSize'` - 可选，数值，指定最大处理文件大小（MB，默认无限制）
- `'ProgressSave'` - 可选，逻辑值，是否启用进度保存（默认true）

**输出参数：**

- `integratedData` - 结构体，整合后的数据，按文件夹和文件组织

## 使用方法

### 基本使用示例

```matlab
% 基本整合，不保存结果
data = integrateMatFiles('F:\\GDB');

% 整合并自动保存结果
data = integrateMatFiles('F:\\GDB', 'SaveToFile', true);

% 指定保存文件名
data = integrateMatFiles('F:\\GDB', 'SaveToFile', true, 'SaveFileName', 'railway_data.mat');

% 启用大文件处理优化（处理超过50MB的文件时使用优化策略）
data = integrateMatFiles('F:\\GDB', 'MaxFileSize', 50);

% 禁用进度保存功能
data = integrateMatFiles('F:\\GDB', 'ProgressSave', false);
```

### 高级使用示例

```matlab
% 同时使用多个参数配置
data = integrateMatFiles('F:\\GDB', ...
    'SaveToFile', true, ...
    'SaveFileName', 'processed_data.mat', ...
    'MaxFileSize', 100, ...
    'ProgressSave', true);

% 访问整合后的数据
if isfield(data, 'k13') && isfield(data.k13, 'K13_047')
    vibData = data.k13.K13_047.vib_data;
    % 进行数据分析...
end

% 查看元数据信息
disp(['处理文件夹数: ', num2str(data.metaData.folderCount)]);
disp(['处理文件总数: ', num2str(data.metaData.totalFiles)]);
disp(['成功处理: ', num2str(data.metaData.successCount)]);
disp(['失败处理: ', num2str(data.metaData.failCount)]);
```

## 辅助脚本说明

### example_usage.m

示例使用脚本，展示基本功能的调用方法。

### test_complete_function.m

全面测试脚本，验证所有功能是否正常工作，包括：

- 创建测试数据
- 调用整合函数
- 验证保存结果
- 清理测试文件

### test_fix.m

语法验证脚本，专门用于验证代码语法结构是否正确。

### test_new_function.m

新功能测试脚本，专注于测试保存功能和进度管理。

## 输出文件说明

### 整合后的数据文件

默认格式为MATLAB .mat文件，使用-v7.3格式确保大文件兼容性。

### 日志文件

- `integration_process_log.txt` - 详细的处理日志，包含：
    - 处理开始和结束时间
    - 文件夹和文件处理情况
    - 成功和失败统计
    - 错误详细信息
    - 保存操作记录

### 进度文件

- `integration_progress.mat` - 处理中断时自动保存的进度文件（正常完成时会自动删除）

## 数据结构说明

整合后的数据结构如下：

```
integratedData
├── metaData                 % 元数据信息
│   ├── rootFolder           % 根文件夹路径
│   ├── integrationTime      % 整合时间
│   ├── folderCount          % 处理的文件夹数
│   ├── totalFiles           % 处理的文件总数
│   ├── successCount         % 成功处理的文件数
│   ├── failCount            % 失败处理的文件数
│   ├── failedFiles          % 失败文件列表
│   └── startTime/endTime    % 处理开始和结束时间
├── [文件夹名1]              % 按文件夹组织的数据
│   ├── [文件名1]           % 按文件组织的数据
│   │   ├── originalFileName % 原始文件名
│   │   ├── filePath         % 文件完整路径
│   │   └── [数据字段]        % 原始.mat文件中的数据
│   └── [文件名2]
└── [文件夹名2]
```

## 故障排除

### 常见问题及解决方案

1. **内存不足错误**

   - 症状：日志中显示"内存不足"错误
   - 解决：使用`MaxFileSize`参数设置合理的阈值，例如`'MaxFileSize', 50`
1. **文件读取失败**

   - 症状：日志中显示"无法读取文件"错误
   - 解决：检查文件是否损坏，或权限是否正确
1. **保存失败**

   - 症状：无法保存整合结果
   - 解决：确保有足够的磁盘空间，或尝试使用基本格式保存
1. **处理中断**

   - 症状：程序意外终止
   - 解决：重新运行程序，系统会尝试从保存的进度文件恢复

## 注意事项

- 文件名和文件夹名中的非法MATLAB标识符字符会被自动转换
- 原始文件名信息会被保留在`originalFileName`字段中
- 处理大量或大型文件时，建议增加系统内存或使用`MaxFileSize`参数
- 日志文件会覆盖之前的内容，如需保留历史记录请提前备份

## 许可证

本项目仅供内部使用，未经授权不得用于商业用途。

## 联系方式

202300401080@stumail.sztu.edu.cn

---

更新日期：2025年11月4日