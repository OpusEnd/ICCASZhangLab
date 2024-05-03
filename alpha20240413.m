



originFolder = 'F:\Data\segment&extraction\';
fileList = dir(fullfile(originFolder, '*.tif')); 
cellPosition = cell(1,length(fileList));
cellFigure = cell(1,length(fileList));

parfor fileCount = 1:length(fileList)
     %对比度增强
     fileName = [originFolder, fileList(fileCount).name];
     disp(fileName)
     
       
    
        originImg=uint8(imread(fileName));
        imshow(originImg)
        I2 = imtophat(originImg,strel('disk',5));
        imshow(I2)
        g = gscale(I2,'minmax',0,1);
        imshow(g)
        


          

        [~,threshold] = edge(g,'sobel');
        fudgeFactor = 0.8;
        BWs = edge(g,'sobel',threshold * fudgeFactor);
        imshow(BWs)
        se90 = strel('line',4,90);
        se0 = strel('line',4,0);
        BWsdil = imdilate(BWs,[se90 se0]);
        imshow(BWsdil)
        title('Dilated Gradient Mask')
        BWdfill = imfill(BWsdil,'holes');
        imshow(BWdfill)
        title('Binary Image with Filled Holes')
        BWnobord = imclearborder(BWdfill,4);
        imshow(BWnobord)
        title('Cleared Border Image')

        
        seD = strel('diamond',1);
        BWfinal = imerode(BWnobord,seD);
        BWfinal = imerode(BWfinal,seD);
        imshow(BWfinal)
        seO = strel('disk', 5);
        BWfianl = bwareaopen(BWfinal,1000);
        imshow(BWfianl);

        title('Segmented Image');
        imshow(labeloverlay(g,BWfianl))
        title('Mask Over Original Image')

       
%轮廓获取
        [B, L] = bwboundaries(BWfianl, 'noholes');

        cen = regionprops(L, g,'Centroid');

        % 定义放大比例
        scale = 1.2;
        
        % 放大边界坐标
        scaledB = cellfun(@(b) scaleBoundary(b, scale), B, 'UniformOutput', false);
        
        cellPosition{fileCount} = cat(1,cen.Centroid); 
        cellFigure{fileCount} = cat(1,scaledB);
        
 
    
    
end
save('cellPos-AllFrames.mat','cellPosition')
save('cellFigure-AllFrames.mat','cellFigure')
function scaledBoundary = scaleBoundary(boundary, scale)
    % 计算中心点
    center = mean(boundary, 1);

    % 将边界坐标减去中心点
    centeredBoundary = bsxfun(@minus, boundary, center);

    % 放大边界坐标
    scaledCenteredBoundary = centeredBoundary * scale;

    % 将结果加上中心点
    scaledBoundary = bsxfun(@plus, scaledCenteredBoundary, center);
end

