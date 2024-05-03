
clear all;
load('cellPos-AllFrames.mat');
load('cellFigure-AllFrames.mat');
distThd = 10; % unit:pixel
minTraceLength = 1; % cell has to exist at least 5 frames

ii = 1;
traceNum = 1;
cellTrace = [];

while ii < length(cellPosition) % traverse all frames
    tmpTrace = [];
    tmpFrame = cellPosition{ii}; % cells of current frame
    if isempty(tmpFrame) % if all cells in this frame were linked, go to next frame
        disp(['frame-',num2str(ii),' finished.']);
        ii = ii + 1;
        continue;
    end
    % set the first center point as seed
    tmpSeed = [tmpFrame(1,:),ii]; % save as [x y t]
    tmpTrace(1,:) = tmpSeed; % set current seed as trace start
    cellPosition{ii}(1,:) = []; % once seed is linked, remove it
    
    % search every frame after that seed
    for jj = ii+1:length(cellPosition)
        nextFrame = cellPosition{jj};
        [minDist,cellIdx] = min(pdist2(tmpSeed(1:2),nextFrame)); % search the closest cell
        if minDist < distThd % the next cell is close enough, the seed can be linked
            tmpSeed = [nextFrame(cellIdx,:),jj]; % set this cell as new seed
            tmpTrace = cat(1,tmpTrace,tmpSeed); % add this cell to the trace
            cellPosition{jj}(cellIdx,:) = []; % remove the linked seed
        else % if the trace is finished, stop searching
            break;
        end
    end
    
    if size(tmpTrace,1) >= minTraceLength % trace filtering
        cellTrace{traceNum} = tmpTrace;
        traceNum = traceNum + 1;
    end

end



originMarked = uint8(imread("F:\Data\segment&extraction\0000001.tif"));
g = gscale(originMarked,'minmax',0,0.5);
imshow(g)
hold on
colors=['b' 'g' 'r' 'c' 'm' 'y'];

for cellCount = 1: length(cellFigure{1})

cidx = mod(cellCount,length(colors))+1;
plot(cellFigure{1}{cellCount}(:,2), cellFigure{1}{cellCount}(:,1),...
       colors(cidx),'LineWidth',2);
hold on
end
for cellCount = 1:length(cellTrace)
    cidx = mod(cellCount,length(colors))+1;
plot(cellTrace{cellCount}(:,1),cellTrace{cellCount}(:,2),...
       colors(cidx),'LineWidth',2);
hold on
end
saveas(gcf,'markerd');
save('cellTrace.mat','cellTrace');