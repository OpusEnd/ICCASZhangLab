% 选择文件路径

sources = strcat(uigetdir('F:\Data\segment&extraction\JIEHE\', 'Choose the folder for sources'),'\');%源路径
springConst = strcat(uigetdir('F:\Data\segment&extraction\k\', 'Choose the folder for SpringConst output'),'\');%Springconst输出
GibbsEnrg = strcat(uigetdir('F:\Data\segment&extraction\g\', 'Choose the folder for Gibbs output'),'\');%Gibbs能输出

%参数获取与定义
fileList = dir(sources);
fileLength = size(fileList);
picNum = fileLength(1)-2;%
period = 100;
round = picNum/period;
binNum = 20;


fileList = dir(sources);
disp(fileList)
fileName = [sources, fileList(3).name];


imgSize = size(imread(fileName));
width = imgSize(2);
height = imgSize(1);




%函数句柄定义

histFunc = @(x) histcounts(x,binNum);%序列延时间直方图统计
vecMean = @(x) (x(1:end-1) + x(2:end)) / 2;%bin中值计算
binDens = @(x) log((period-2) ./ x(1:end));%bin对应密度计算
noinfFind = @(x) ~isinf(x);%非inf值判断
infRemove = @(x) x(~isinf(x));%Inf值剔除
vecLengthCheck = @(x) size(x,1);%直方图bar计数
cellValueExtract = @(x, y) y(x) ;%依照逻辑值向量提取元素
springConstGibbsZFit = @(x, y) polyfit(x.^2, y, 2);%对bin中心值的平方进行拟合（G0+1/2k*z^2),注意结果需*2


for roundCount = 1:round
tic
%批量读入文件   
    read_image = @(imgCount1) imread(strcat(sources, fileList(period * (roundCount - 1) + imgCount1 + 2).name));
    I = arrayfun(read_image, 1:period, 'UniformOutput', false);
    I = cat(3, I{:});




    %图像对数差，获得z位移步长
    logRatio = zeros(height, width, period-1);
    for imgCount2 = 1:period-1
        logRatio(:,:,imgCount2) = 100*log(imdivide(double(I(:, :, imgCount2)),double(I(:, :, imgCount2+1))));

    end



    %重构数组进行直方图统计
    I = reshape(logRatio, [], size(logRatio,3));
    clear logRatio;
    [N, edges] = cellfun(histFunc, num2cell(I,2), 'UniformOutput', false);

    clear I;

    %对直方图进行处理得到bin中心值及频数分布
    meanEdges = cellfun(vecMean, edges, 'UniformOutput', false);
    freqDens = cellfun(binDens, N, 'UniformOutput', false);


    clear N edges;

    %剔除inf
    freqLogNoInf = cellfun(infRemove, freqDens, 'UniformOutput', false);
    vecLengthIndex = cellfun(@length, freqLogNoInf, 'UniformOutput', true);


    %拟合非inf位置频数及中心值
    infLocations = cellfun(noinfFind, freqDens, 'UniformOutput', false);
    fitDens = cellfun(cellValueExtract, infLocations, freqDens, 'UniformOutput', false);
    fitEdges = cellfun(cellValueExtract, infLocations, meanEdges, 'UniformOutput', false);
    result =  cellfun(springConstGibbsZFit, fitEdges, fitDens, 'UniformOutput', false);

    clear meanEdges freqDens fitDens fitEdges infLocations

    %填充SpringConstant与Gibbs到对应数组
    SConst = cellfun(@(x) x(2)*2, result);
    Gibbs = cellfun(@(x) x(1), result);

    clear result
    
    ind1 = find(vecLengthIndex==1);%对数后直方图数量大于1的位置索引
    SConst(ind1) = 0;
    Gibbs(ind1) = 0;

    clear vecLengthIndex ind1

    %重塑数组为图像
    SConst = reshape(SConst,height,width);
    Gibbs = reshape(Gibbs,height,width);



    % 文件保存
    countStr = sprintf('%07d',roundCount);
    SConstPath = strcat(springConst,countStr,'_polyfitSConst.tif');
    GibbsPath = strcat(GibbsEnrg,countStr,'_polyfitG.tif');
    saveastifffast(single(SConst),SConstPath);
    saveastifffast(single(Gibbs),GibbsPath);
    
toc
    clear SConst Gibbs;
end

