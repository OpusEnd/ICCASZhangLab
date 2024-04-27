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
    numImages = numel(imageFiles);
    
    roiPath = fullfile(roiFolderbigsize, roiFiles1(1).name);
    roiInfo = ReadImageJROI(roiPath);
    vnRectBounds = roiInfo.vnRectBounds; % 获取矩形边界信息
    
    % 创建用于保存图像数据的单元格数组
    imageData = cell(numImages, 1);
    
    % 遍历每张图片
    for j = 1:numImages
    % 获取对应的图片文件名
    imageFileName = fullfile(imageFolder1, imageFiles(j).name);
    
    % 读取图片  
    img = imread(imageFileName);
    img = img';
    
    % 裁剪区域
    rectRegion = img(vnRectBounds(2)+1:vnRectBounds(4), vnRectBounds(1)+1:vnRectBounds(3));
    rectRegion = rectRegion';
    
    % 将裁剪后的图像数据存储在单元格中
    imageData{j} = single(rectRegion);
    
    % 构造保存图像的文件名
    [~, baseFileName, ~] = fileparts(imageFileName);
    outputFileName = fullfile(A1, [baseFileName, '.tif']);
    % 创建 Tiff 对象
    t = Tiff(outputFileName, 'w');
    % 设置 TIFF 文件属性
    tagstruct.ImageLength = size(rectRegion, 1);
    tagstruct.ImageWidth = size(rectRegion, 2);
    tagstruct.Photometric = Tiff.Photometric.MinIsBlack;
    tagstruct.BitsPerSample = 32;
    tagstruct.SamplesPerPixel = 1;
    tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
    tagstruct.SampleFormat = Tiff.SampleFormat.IEEEFP;
    t.setTag(tagstruct);
    % 写入图像数据
    t.write(rectRegion);
    % 关闭 TIFF 文件
    t.close();
    end

%单ROI循环获取
    % 获取 ROI 文件夹中的所有 .roi 文件列表
    roiFiles2 = dir(fullfile(roiFolderangle, '*.roi'));
    % 获取图片文件夹中的所有图片文件列表
    imageFiles = dir(fullfile(imageFolder2, '*.tif'));
    
    % 初始化结果cell数组
    numROIs = numel(roiFiles2);
    numImages = numel(imageFiles);
    GrayValues = cell(numImages, 2);
    
    % 遍历每个 ROI 文件
    for i = 1:numROIs
        % 读取 ROI 文件
        roiPath = fullfile(roiFolderangle, roiFiles2(i).name);
        roiInfo = ReadImageJROI(roiPath);
        vnRectBounds = roiInfo.vnRectBounds; % 获取矩形边界信息
    
        % 遍历每张图片
        for j = 1:numImages
            % 获取对应的图片文件名
            imageFileName = fullfile(imageFolder2, imageFiles(j).name);
    
            % 读取图片
            img = imread(imageFileName);
    
            % 计算矩形区域的平均灰度值
            rectRegion = img(vnRectBounds(1)+1:vnRectBounds(3), vnRectBounds(2)+1:vnRectBounds(4));
            meanGray = mean(rectRegion(:));
            
            % 将平均灰度值和图片名保存到 GrayValues cell数组中
            name = regexp(imageFiles(j).name, '\d+', 'match');
            GrayValues{j, 1} = name;
            GrayValues{j, 2} = meanGray;
        end
        
        % 将GrayValues转换为table并写入CSV文件
        data_table = cell2table(GrayValues, 'VariableNames', {'ImageName', 'MeanGray'});
        csvFileName = fullfile(A2, sprintf('%d.csv', i));
        writetable(data_table, csvFileName);
    end


%输出scrubber适配格式
    folder_path = A2;
    unsorted_files = dir(fullfile(folder_path, '*.csv'));
    %自然数排序
    [~, order] = natsort({unsorted_files.name}) ; 
    files = unsorted_files(order) ; 
    
    num_files = length(files) ; 
    % 获取文件数量
    num_files = length(files);
    
    % 循环处理每个文件
    for i = 1:num_files
        % 获取文件名
        file1 = fullfile(folder_path, files(i).name);
        
        % 获取数据,建立str表头
        M = xlsread(file1);
        y=M (:, 2 );
        x=M(:,1);
        %x(378:380,:)=[];
        A=x-1;
       % y(97:99,:)=[];
        B=y;
        %B=y*100000;
    %     A=[0;
    % 5.35;
    % 10.7;
    % 16.05;
    % 21.4;
    % 26.75;
    % 32.1;
    % 37.45;
    % 42.8;
    % 48.15;
    % 53.5;
    % 58.85;
    % 64.2;
    % 69.55;
    % 74.9;
    % 80.25;
    % 85.6;
    % 90.95;
    % 96.3;
    % 101.65;
    % 107;
    % 112.35;
    % 117.7;
    % 123.05;
    % 128.4;
    % 133.75;
    % 139.1;
    % 144.45;
    % 149.8;
    % 155.15;
    % 160.5;
    % 165.85;
    % 171.2;
    % 176.55;
    % 181.9;
    % 187.25;
    % 192.6;
    % 197.95;
    % 203.3;
    % 208.65;
    % 214;
    % 219.35;
    % 224.7;
    % 230.05;
    % 235.4;
    % 240.75;
    % 246.1;
    % 251.45;
    % 256.8;
    % 262.15;
    % 267.5;
    % 272.85;
    % 278.2;
    % 283.55;
    % 288.9;
    % 294.25;
    % 299.6;
    % 304.95;
    % 310.3;
    % 315.65;
    % 321;
    % 326.35;
    % 331.7;
    % 337.05;
    % 342.4;
    % 347.75;
    % 353.1;
    % 358.45;
    % 363.8;
    % 369.15;
    % 374.5;
    % 379.85;
    % 385.2;
    % 390.55;
    % 395.9;
    % 401.25;
    % 406.6;
    % 411.95];
    Z=[A B];
    str = {'Vers 3.41', 'Data'; 'Conc1', '714E-9'; 'Start1', '0'; 'Stop1', '2500'; 'Time1', 'Data1'};
        
        % 输出data为文件名+kon
        G = [str; num2cell(Z)];  % 将B转换为元胞数组，以便与str连接
        T = cell2table(G(2:end, :), 'VariableNames', G(1, :));  % 指定变量名
        
       % 文件名为原文件名加上'-1'，输出在新的文件夹 
        [~, file_name, ext] = fileparts(files(i).name); 
        file_name = fullfile(A3, [file_name '.txt'])
        % 将数据保存为txt文件
        writetable(T, file_name, 'Delimiter', '\t');


%绘画散点图
    plot(A,B,'ko','MarkerFaceColor','k') ; % 绘制原始数据（image intensity）
    xlabel('Time(s)') ; 
    ylabel('Image Intensity') ; 
     [~, file_name, ext] = fileparts(files(i).name); 
     file2_name = fullfile(A4, [file_name '.jpg']);
    str1 = i ;  
    title(str1) ;
    h1=gcf;
    %保存图片
    saveas (h1 ,file2_name) ; 
    end