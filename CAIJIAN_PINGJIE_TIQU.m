% 设置 ROI 文件夹和图片文件夹的路径
roiFolderbigsize = 'I:\20240424\DATA'; % 替换为实际的 ROI 文件夹路径
imageFolder1 = 'I:\20240424\DATA\DUIQI JIEHE\DOP'; % 替换为实际的图片文件夹路径
% 新文件夹路径-新建文件夹
A1=fullfile("I:\20240424\DATA\","caijian\DOP","\");

outputFolder1 = mkdir(A1);   

% 设置 单ROI 文件夹和图片文件夹的路径
roiFolderangle = 'I:\20240424\DATA\RoiSet100'; % 替换为实际的 ROI 文件夹路径
imageFolder2 = A1; % 替换为实际的图片文件夹路径

% 新文件夹路径
A2=fullfile("I:\20240424\DATA\","image intensity roi\DOP\1","\");

outputFolder2 = mkdir(A2);
A3=fullfile("I:\20240424\DATA\","image intensity roi\DOP\2","\");

outputFolder3 = mkdir(A3);
A4=fullfile("I:\20240424\DATA\","image intensity roi\DOP\3","\");

outputFolder4 = mkdir(A4);

%裁剪大ROI
% 获取 ROI 文件夹中的所有 .roi 文件列表
roiFiles1 = dir(fullfile(roiFolderbigsize, '*.roi'));

% 获取图片文件夹中的所有图片文件列表
imageFiles = dir(fullfile(imageFolder1, '*.tif'));

% numImages = numel(imageFiles);

roiPath = fullfile(roiFolderbigsize, roiFiles1(1).name);
roiInfo = ReadImageJROI(roiPath);
vnRectBounds = roiInfo.vnRectBounds; % 获取矩形边界信息

% 获取对应的图片文件名
imageFileNames = fullfile(imageFolder1, {imageFiles.name});

% 读取所有图片
images = cellfun(@imread, imageFileNames, 'UniformOutput', false);

% 转置图片
images = cellfun(@transpose, images, 'UniformOutput', false);

% 裁剪区域
rectRegions = cellfun(@(img) img(vnRectBounds(2)+1:vnRectBounds(4), vnRectBounds(1)+1:vnRectBounds(3)), images, 'UniformOutput', false);

% 转置裁剪后的图像数据
rectRegions = cellfun(@transpose, rectRegions, 'UniformOutput', false);

% 将裁剪后的图像数据存储在单元格中
imageData = cellfun(@single, rectRegions, 'UniformOutput', false);

% 构造保存图像的文件名
baseFileNames = cellfun(@(file) fileparts(file), imageFileNames, 'UniformOutput', false);
outputFileNames = cellfun(@(base) fullfile(A1, [base, '.tif']), baseFileNames, 'UniformOutput', false);

% 创建 Tiff 对象并保存图像
cellfun(@(img, file) saveastifffast(img, file),  rectRegions,outputFileNames);


%单ROI循环获取
% 获取 ROI 文件夹中的所有 .roi 文件列表
roiFiles2 = dir(fullfile(roiFolderangle, '*.roi'));

% 获取图片文件夹中的所有图片文件列表
imageFiles = dir(fullfile(imageFolder2, '*.tif'));

% 初始化结果cell数组
numROIs = numel(roiFiles2);
numImages = numel(imageFiles);

% 遍历每个 ROI 文件
% 读取 ROI 文件
roiPaths = fullfile(roiFolderangle, {roiFiles2.name});
roiInfos = arrayfun(@(path) ReadImageJROI(path), roiPaths);
vnRectBounds = arrayfun(@(info) info.vnRectBounds, roiInfos, 'UniformOutput', false);

% 获取图片文件名
imageFileNames = fullfile(imageFolder2, {imageFiles.name});

% 读取所有图片
images = cellfun(@imread, imageFileNames, 'UniformOutput', false);

% 计算矩形区域的平均灰度值
rectRegions = cellfun(@(img, bounds) img(bounds(1)+1:bounds(3), bounds(2)+1:bounds(4)), images, vnRectBounds, 'UniformOutput', false);
meanGrays = cellfun(@(region) mean(region(:)), rectRegions);

% 构造 GrayValues cell 数组
nameRegex = '\d+';
imageNames = cellfun(@(fileName) regexp(fileName, nameRegex, 'match'), imageFileNames, 'UniformOutput', false);
GrayValues = [imageNames', num2cell(meanGrays)];

% 将 GrayValues 转换为 table 并写入 CSV 文件
data_table = cell2table(GrayValues, 'VariableNames', {'ImageName', 'MeanGray'});
csvFileNames = arrayfun(@(i) fullfile(A2, sprintf('%d.csv', i)), 1:numROIs, 'UniformOutput', false);
arrayfun(@(fileName, table) writetable(table, fileName), csvFileNames, repmat({data_table}, 1, numROIs));


%输出scrubber适配格式
folder_path = A2;
unsorted_files = dir(fullfile(folder_path, '*.csv'));
%自然数排序
[~, order] = natsort({unsorted_files.name}) ; 
files = unsorted_files(order) ; 

% 获取文件数量
num_files = length(files);

% 获取文件名
file1 = fullfile(folder_path, {files.name});

% 获取数据,建立str表头
M = cellfun(@(file) xlsread(file), file1, 'UniformOutput', false);
y = cellfun(@(M) M(:, 2), M, 'UniformOutput', false);
x = cellfun(@(M) M(:, 1), M, 'UniformOutput', false);

A = cellfun(@(x) x - 1, x, 'UniformOutput', false);
B = y;

Z = cellfun(@(A, B) [A B], A, B, 'UniformOutput', false);
str = {'Vers 3.41', 'Data'; 'Conc1', '714E-9'; 'Start1', '0'; 'Stop1', '2500'; 'Time1', 'Data1'};

% 输出data为文件名+kon
G = cellfun(@(str, Z) [str; num2cell(Z)], str, Z, 'UniformOutput', false);
T = cellfun(@(G) cell2table(G(2:end, :), 'VariableNames', G(1, :)), G, 'UniformOutput', false);

% 文件名为原文件名加上'-1'，输出在新的文件夹 
file_name = cellfun(@(file) fullfile(A3, [file '.txt']), {files.name}, 'UniformOutput', false);
% 将数据保存为txt文件
cellfun(@(T, file_name) writetable(T, file_name, 'Delimiter', '\t'), T, file_name);

%绘画散点图
A = cellfun(@(x) x(:, 1), Z, 'UniformOutput', false);
B = cellfun(@(x) x(:, 2), Z, 'UniformOutput', false);

plot(A, B, 'ko', 'MarkerFaceColor', 'k') ; % 绘制原始数据（image intensity）
xlabel('Time(s)') ; 
ylabel('Image Intensity') ; 

file2_name = cellfun(@(file) fullfile(A4, [file '.jpg']), {files.name}, 'UniformOutput', false);
str1 = num2cell(1:num_files);
title(str1) ;

h1 = gcf;
%保存图片
cellfun(@(h1, file2_name) saveas(h1, file2_name), h1, file2_name);