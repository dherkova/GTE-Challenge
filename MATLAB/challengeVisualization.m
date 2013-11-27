%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% CHALLENGEVISUALIZATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Example of the various functions available to visualize the Challenge
%%% data.

clear all;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% DEFINE THE CHALLENGE FOLDER
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if(ismac || isunix)
    challengeFolder = '~/Dropbox/Projects/GTE-Challenge/MATLAB/';
elseif(ispc)
    challengeFolder = 'C:\Users\Dherkova\Dropbox\Projects\GTE-Challenge\MATLAB\';
end

% 'Pathify'
cd(challengeFolder);
path(path, [challengeFolder]);
path(path, [challengeFolder 'external']);
path(path, [challengeFolder 'external' filesep 'YAMLMatlab']);
path(path, [challengeFolder 'external' filesep 'cm_and_cb_utilities']);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% DEFINE THE INPUT FILES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
baseFile = 'iNet1_Size100_CC03';

networkFile = ['../topologies' filesep 'topology_' baseFile '.yaml'];
fluorescenceFile = ['challenge' filesep 'fluorescence_' baseFile '.txt'];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% PRELOAD THE DATA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% Load the Fluorescence signal
F = load(fluorescenceFile);

%%% Load the newtork
network = YAMLToNetwork(strcat(challengeFolder,networkFile));

%% Plot the average of the whole time series
figure;
h = visualizeFluorescenceTimeSeries(F, 'samples', 1:size(F,1));

%% Plot all the individual traces separated
figure;
h = visualizeFluorescenceTimeSeries(F, 'type', 'single','offset',0.02, 'neuronList', 1:size(F,2));

%% Let's save the newtork as a GEXF file for visualization
outputFile = 'test_network.gexf';
networkToGEXF(network, outputFile);

% Now you can open the GEXF file with GEPHI to visualize the network


%%

%- laying out the neurons and representing the connectivity
%- representing the time series DONE
%- representing the neurons in action
%- browsing through the pairs of signals and displaying the "truth values" of the connections.


%% Precompute the ranges and normalization factors of each neuron


imageSize = [256, 256];

%gkSigmaXY = 0.15; % Value of the std deviation of the spatial gaussian kernel
gkSigmaXY = 0.03; % Value of the std deviation of the spatial gaussian kernel
gkNXY = 3; % Number of sigmas for the cutoff of the spatial gaussian kernel

xSize = max(network.X)-min(network.X);
ySize = max(network.X)-min(network.X);

xRange = [min(network.X), max(network.X)] + [-1, 1]*xSize/10;
yRange = [min(network.Y), max(network.Y)] + [-1, 1]*ySize/10;

xVector = linspace(xRange(1), xRange(2), imageSize(1));
yVector = linspace(yRange(1), yRange(2), imageSize(2));

[gridX, gridY] = meshgrid(xVector,yVector);
gridZ = zeros(size(gridX));
gapX = diff(gridX(1,1:2));
gapY = diff(gridY(1:2,1));

spread = cell(length(network.X),1);
% Forget the gaussian kernel and apply a flat filter for now
for idx = 1:length(network.X)
    nX = network.X(idx);
    nY = network.Y(idx);
    % Get the set of points that are N sigma apart
    % For each neuron apply the gaussian kernel around the closest point
    [~, minX] = min(abs(nX-gkNXY*gkSigmaXY-xVector));
    [~, maxX] = min(abs(nX+gkNXY*gkSigmaXY-xVector));
    [~, minY] = min(abs(nY-gkNXY*gkSigmaXY-yVector));
    [~, maxY] = min(abs(nY+gkNXY*gkSigmaXY-yVector));


    rangeX = minX:maxX;
    rangeY = minY:maxY;
    
    valid = gridX(rangeY,rangeX) >= 0 & gridX(rangeY,rangeX) <= 1 & gridY(rangeY,rangeX) >= 0 & gridY(rangeY,rangeX) <= 1;
    fullNorm = sum(sum(normpdf(gridX(rangeY,rangeX).*valid, nX, gkSigmaXY).*normpdf(gridY(rangeY,rangeX).*valid, nY, gkSigmaXY)*gapX*gapY));

    %fullNorm = 1;
    value = normpdf(gridX(rangeY,rangeX), nX, gkSigmaXY).*normpdf(gridY(rangeY,rangeX), nY, gkSigmaXY)/fullNorm;
    %value = 1;
    spread{idx}.rangeX = rangeX;
    spread{idx}.rangeY = rangeY;
    spread{idx}.value = value;
end

%% Generate the movie frames
clear RF;
% Now let's start by creating the image grid

samples = 1:20:10000;
imageSize = [256, 256];

colorRelative = true; % easy hack to avoid out of scale data

xSize = max(network.X)-min(network.X);
ySize = max(network.X)-min(network.X);

xRange = [min(network.X), max(network.X)] + [-1, 1]*xSize/10;
yRange = [min(network.Y), max(network.Y)] + [-1, 1]*ySize/10;

xVector = linspace(xRange(1), xRange(2), imageSize(1));
yVector = linspace(yRange(1), yRange(2), imageSize(2));

[gridX, gridY] = meshgrid(xVector,yVector);
fluorescenceImg = zeros(size(gridX));

% Plot options
cmap = jet;

contourLines = 7;
ticks = 5;
FSIZE = 10;
barWidthFactor = 0.5;
barHeightFactor = 0.95;

hfig = figure;

frameNumber = 1;

for t = samples
    fluorescenceImg = zeros(size(gridX));
    currentImg = zeros(size(gridX));
    for idx = 1:length(network.X)
        nX = network.X(idx);
        nY = network.Y(idx);

        fluorescenceImg(spread{idx}.rangeY,spread{idx}.rangeX) = fluorescenceImg(spread{idx}.rangeY,spread{idx}.rangeX)+...
            F(t, idx)*spread{idx}.value;
    end
    
    %%% The plot itself

    clf;

    %imagesc(xVector, yVector,fluorescenceImg);
    pcolor(gridX, gridY, fluorescenceImg);
    axis xy;
    shading interp;
    colormap(cmap);

    cb = colorbar('location','WestOutside');
    cblabel('Fluorescence Intensity (absolute)');
    
    set(cb,'yaxisloc','left');
    barPosition = get(cb,'position');
    barPosition = barPosition - [0.01, 0, 0, 0]; %%%%%%%%

    barPosition(1) = barPosition(1)+barPosition(3)*(1-barWidthFactor)/2;
    barPosition(2) = barPosition(2)+barPosition(4)*(1-barHeightFactor)/2;
    barPosition(3) = barPosition(3)*barWidthFactor;
    barPosition(4) = barPosition(4)*barHeightFactor;

    set(cb,'position',barPosition);
        
    %%% Set the axis limits
    xlim(xRange);
    ylim(yRange);
    %caxis([0 250])
    caxis([min(fluorescenceImg(:)), max(fluorescenceImg(:))])
    cl = caxis;
    set(gca,'XTick',[]);
    set(gca,'YTick',[]);
    set(cb,'YTick', cl);
    set(cb,'YTickLabel', sprintf('%.0f|',get(cb,'YTick')));
    
    %set(gca, 'XTickLabel', []);
    %set(gca, 'YTickLabel', []);


    grid off;box on;
    axis square;

    set(gca,'Color','none');

    title(sprintf('sample = %d',t));
    
    %%% Final touches
    %set(findall(gcf,'-property','FontName'), 'FontName', FNAME);
    set(findall(gcf,'-property','FontSize'), 'FontSize', FSIZE);
    drawnow;
    
    RF(frameNumber) = getframe(gcf);
    
    frameNumber = frameNumber+1;
end

close(hfig);
%R = close(R);
%close(R);
disp('Frames stored');
save('frameData','F');


%% Generate the movie frames using IMSHOW
clear RF;
% Now let's start by creating the image grid

samples = 1:20:1000;
imageSize = [256, 256];

colorRelative = true; % easy hack to avoid out of scale data

xSize = max(network.X)-min(network.X);
ySize = max(network.X)-min(network.X);

xRange = [min(network.X), max(network.X)] + [-1, 1]*xSize/10;
yRange = [min(network.Y), max(network.Y)] + [-1, 1]*ySize/10;

xVector = linspace(xRange(1), xRange(2), imageSize(1));
yVector = linspace(yRange(1), yRange(2), imageSize(2));

[gridX, gridY] = meshgrid(xVector,yVector);
fluorescenceImg = zeros(size(gridX));

% Plot options
cmap = jet(128);

contourLines = 7;
ticks = 5;
FSIZE = 10;
barWidthFactor = 0.5;
barHeightFactor = 0.95;

%hfig = figure;

frameNumber = 1;

for t = samples
    fluorescenceImg = zeros(size(gridX));
    currentImg = zeros(size(gridX));
    for idx = 1:length(network.X)
        nX = network.X(idx);
        nY = network.Y(idx);

        fluorescenceImg(spread{idx}.rangeY,spread{idx}.rangeX) = fluorescenceImg(spread{idx}.rangeY,spread{idx}.rangeX)+...
            F(t, idx)*spread{idx}.value;
    end
    
    %%% The plot itself
 %   clf;cla;

    %imagesc(xVector, yVector,fluorescenceImg);
    %pcolor(gridX, gridY, fluorescenceImg);
    Findex = (size(cmap,1)-1)*(fluorescenceImg-min(fluorescenceImg(:)))/(max(fluorescenceImg(:))-min(fluorescenceImg(:)))+1;
    imshow(Findex, cmap);
    
    
  %  drawnow;
    
    RF(frameNumber) = getframe(gca);
    [I,map] = frame2im(RF(frameNumber));
    fprintf('Size = %d,%d,%d\n',size(I));
      
    frameNumber = frameNumber+1;
end

close(hfig);
%R = close(R);
%close(R);
disp('Frames stored');
save('frameData','F');

%%
visualizeFluorescenceMovie(network, F);

%% Try to save just the movie
fps = 15;

load('frameData');
%load('frames');
if(ismac)
    R = VideoWriter('movies/test4','MPEG-4');
else
    R = VideoWriter('movies/test4','Motion JPEG AVI');
end
R.FrameRate = fps;
open(R);

tic
for t = 1:length(RF)
    
    writeVideo(R, RF(t));
end
toc
%R = close(R);
close(R);
disp('Movie recorded.');



%% Generate the movie frames using IMSHOW all together
fps = 15;
rescaleFluorescence = false;
absolutePrefactor = 0.8;
% Create the movie structure
if(ismac)
    R = VideoWriter('movies/test4','MPEG-4');
else
    R = VideoWriter('movies/test4','Motion JPEG AVI');
end
R.FrameRate = fps;
open(R);


% Now let's start by creating the image grid

samples = 1:1:1000;
imageSize = [256, 256];
cmap = jet(256);

colorRelative = true; % easy hack to avoid out of scale data

xSize = max(network.X)-min(network.X);
ySize = max(network.X)-min(network.X);

xRange = [min(network.X), max(network.X)] + [-1, 1]*xSize/10;
yRange = [min(network.Y), max(network.Y)] + [-1, 1]*ySize/10;

xVector = linspace(xRange(1), xRange(2), imageSize(1));
yVector = linspace(yRange(1), yRange(2), imageSize(2));

[gridX, gridY] = meshgrid(xVector,yVector);
fluorescenceImg = zeros(size(gridX));



% Fast pass to get the min max fluorescence
minF = inf;
maxF = -inf;

if(~rescaleFluorescence)
    for t = samples
        fluorescenceImg = zeros(size(gridX));
        currentImg = zeros(size(gridX));
        for idx = 1:length(network.X)
            nX = network.X(idx);
            nY = network.Y(idx);

            fluorescenceImg(spread{idx}.rangeY,spread{idx}.rangeX) = fluorescenceImg(spread{idx}.rangeY,spread{idx}.rangeX)+...
                F(t, idx)*spread{idx}.value;
        end
        minF = min([minF; fluorescenceImg(:)]);
        maxF = max([maxF; fluorescenceImg(:)]);
    end
    maxF = absolutePrefactor*maxF;
end

for t = samples
    fluorescenceImg = zeros(size(gridX));
    currentImg = zeros(size(gridX));
    for idx = 1:length(network.X)
        nX = network.X(idx);
        nY = network.Y(idx);

        fluorescenceImg(spread{idx}.rangeY,spread{idx}.rangeX) = fluorescenceImg(spread{idx}.rangeY,spread{idx}.rangeX)+...
            F(t, idx)*spread{idx}.value;
    end
    % Generate the index vlaue
    if(rescaleFluorescence)
        Findex = round((size(cmap,1)-1)*(fluorescenceImg-min(fluorescenceImg(:)))/(max(fluorescenceImg(:))-min(fluorescenceImg(:)))+1);
    else
        Findex = round((size(cmap,1)-1)*(fluorescenceImg-minF)/(maxF-minF)+1);
    end

    writeVideo(R, ind2rgb(Findex, cmap));
    frameNumber = frameNumber+1;
end

disp('Movie recorded');
close(R);


%% Try to save just the movie
fps = 15;

load('frameData');
%load('frames');
if(ismac)
    R = VideoWriter('movies/test4','MPEG-4');
else
    R = VideoWriter('movies/test4','Motion JPEG AVI');
end
R.FrameRate = fps;
open(R);

tic
for t = 1:length(RF)
    
    writeVideo(R, RF(t));
end
toc
%R = close(R);
close(R);
disp('Movie recorded.');
