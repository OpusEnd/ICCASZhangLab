% 指定文件路径
originFolder45 = strcat(uigetdir('F:\2\45\','Choose the folder for 45image'),'\');
originFolder135 = strcat(uigetdir('F:\2\135\','Choose the folder for 135image'),'\');
processedFolder45 = strcat(uigetdir('F:\Data\Imagesequence\processed\output\45m\','Choose the folder for registered 45image'),'\');
processedFolder135 = strcat(uigetdir('F:\Data\Imagesequence\processed\output\135m\','Choose the folder for registered 135image'),'\');
% maskFolder = 'F:\Data\Imagesequence\processed\output\';
% maskPath = fullfile(maskFolder, 'mask.tif');
addFolder = strcat(uigetdir('F:\Data\Imagesequence\processed\output\calculated\add\','Choose the folder for added image'),'\');
divFolder = strcat(uigetdir('F:\Data\Imagesequence\processed\output\calculated\divide\','Choose the folder for divided image'),'\');
subFolder = strcat(uigetdir('F:\Data\Imagesequence\processed\output\calculated\sub\','Choose the folder for substracted image'),'\');
polarFolder = strcat(uigetdir('F:\Data\Imagesequence\processed\output\calculated\pol','Choose the folder for polarcontrast image'),'\');

fileList45 = dir(fullfile(originFolder45, '*.tif')); 
fileList135 = dir(fullfile(originFolder135, '*.tif')); 



file45Name = [originFolder45, fileList45(3).name];
file135Name = [originFolder135, fileList135(3).name];

        % 对比度插值
        fixed=imread(file45Name);    
        I=double(fixed);
        I=40*(log(I+1));
        file45Gray=uint8(I);
        moving = imread(file135Name);    
        J=double(moving);
        J=40*(log(J+1));
        file135Gray=uint8(J);
        
        % 获取配准矩阵
        [optimizer, metric] = imregconfig('multimodal');
        optimizer.MaximumIterations = 300;
        optimizer.InitialRadius = 0.0009;
        tform = imregtform(file135Gray, file45Gray, "affine", optimizer, metric);
        registered = imwarp(file135Gray, tform, 'OutputView', imref2d(size(file135Gray)));
        disp(optimizer);
        disp(metric);
        imshowpair(file45Gray,registered,"Scaling","joint");

        % 计算两个图像非零像素的交集作为重叠区域的掩码
        overlapMask = fixed > 0 & registered > 0;
        % 找到二值化图像中非零像素的位置
        [row, col] = find(overlapMask);
        % 获取非零像素的最小和最大坐标，以确定覆盖所有非零像素的矩形区域
        minRow = min(row);
        maxRow = max(row);
        minCol = min(col);
        maxCol = max(col);
        % 基于上述矩形区域生成方形掩码
        % 创建一个与原图大小相同的全零矩阵
        mask = zeros(size(overlapMask));
        % 将矩形区域内的像素值设置为1
        mask(minRow:maxRow, minCol:maxCol) = 1;
        % imwrite(mask,maskPath,'tif')
         disp('mask is created.');

%以较短的fileList做计数
if length(fileList45) < length(fileList135)
    shorterList = length(fileList45);
else
    shorterList = length(fileList135);
end

for fileCount = 1 : shorterList
   
     file45Name = [originFolder45, fileList45(fileCount).name];
     file135Name = [originFolder135, fileList135(fileCount).name];
    
    masked45 = imread(file45Name);
    masked45(~mask) = 0;  % 将非重叠部分设置为0 
    masked135 = imread(file135Name);
    registered135 = imwarp(masked135, tform, 'OutputView', imref2d(size(masked135)));
    registered135(~mask) = 0;  % 将非重叠部分设置为0
   
    
   
       
    % 为 overlapFixed 图像保存为 TIFF 文件
    
    fixedFilePath = fullfile(processedFolder45, fileList45(fileCount).name);
    registeredFilePath = fullfile(processedFolder135, fileList135(fileCount).name);
    saveastifffast(single(masked45), fixedFilePath)
    saveastifffast(single(registered135), registeredFilePath)
    
   
end

fileProcessedList45 = dir(fullfile(processedFolder45, '*.tif'));
fileProcessedList135 = dir(fullfile(processedFolder135, '*.tif'));

for fileProcessedCount = 1 : length(fileProcessedList45)
     calculate45Name = [processedFolder45, fileProcessedList45(fileProcessedCount).name];
     calculate135Name = [processedFolder135, fileProcessedList135(fileProcessedCount).name];
     calculate45 = imread(calculate45Name);
     calculate135 = imread(calculate135Name);
     addImage = imadd(calculate45,calculate135);
     divImage = imdivide(calculate45,calculate135);
     subImage = imsubtract(calculate45,calculate135);
     polImage = imdivide(subImage,addImage);
    
    addFilePath = fullfile(addFolder, fileProcessedList45(fileProcessedCount).name);
    subFilePate = fullfile(subFolder, fileProcessedList45(fileProcessedCount).name);
    divFilePath = fullfile(divFolder, fileProcessedList45(fileProcessedCount).name);
    polFilePath = fullfile(polarFolder,fileProcessedList45(fileProcessedCount).name);


    saveastifffast(single(addImage),addFilePath)
    saveastifffast(single(divImage),divFilePath)
    saveastifffast(single(subImage),subFilePate)
    saveastifffast(single(polImage),polFilePath)
   
    disp(['Image-',num2str(fileProcessedCount),'calculation is finished.']);
    
end
