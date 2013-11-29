function visualizeFluorescenceMovie(network, F, varargin)
% VISUALIZEFLUORESCENCEMOVIE creates a movie from the fluorescence data
% similar to the one obtained in the experiments.
%
% USAGE:
%    visualizeFluorescenceMovie(network, F, fileName, varargin)
%
%
% INPUT arguments:
%    network - Network structure with the following elements:
%      network.RS - Sparse matrix of size NxN, being N the number of nodes.
%      Element RS(i,j) indicates the weight of the connection from i to j
%      (1 if unweighted).
%      network.X - Vector of length N with the X position of the nodes.
%      network.Y - Vector of length N with the Y position of the nodes.
%
%    F - Fluorescence data (each row a sample, each column a neuron).
%
%
% INPUT optional arguments ('key' followed by its value): 
%    fileName - Output movie file (mpg in mac, avi elsewhere). If fileName
%    is empty, it will not save the movie and only output it in the screen
%    (default 'movie');
%
%    'colorMode' - ('relative'/'absolute'). Relative: rescale the
%    colorbar to always represent the fluorescence range of the current
%    frame. Absolute: th colorbar is set by the overall minimum and maximum
%    fluorescence values (default 'absolute').
%
%    'movieMode' - ('standard'/'fast'). Standard: creates the movie based
%    on the matlab figure, with title and colorbar. Fast: creates the movie
%    with only the fluorescence data (default 'standard').
%
%    'cmap' - Colormap to use in the movie. A colormap is an m-by-3
%    matrix of real numbers between 0.0 and 1.0. Each row is an RGB vector
%    that defines one color. The kth row of the colormap defines the kth
%    color, where map(k,:) = [r(k) g(k) b(k)]) specifies the intensity of
%    red, green, and blue (see colormap function for details), (default
%    uses the jet colormap with 256 entries)
%
%    'fps' - Integer with the frames per second for the movie (default 15).
%
%    'imageSize' - vector of the form [w h] with the width and height of
%    the image in pixels (default [256 256]).
%
%    'figureSize' - vector of the form [w h] with the width and height of
%    the figure in pixels, not applicable to the fast mode (default [400
%    400]).
%
%    'samples' - vector containing the samples at which generate the image
%    (default 1:1000).
%
%    'cmap' - colormap to use (default jet(256)).
%
%    'gkSigmaXY' - since each neuron is spatially plotted as a gaussian
%    kernel, this sets its standard deviation in scaled units (similar to
%    the neuron's size), default (0.03).
%
%    'gkNXY' - multiple of standard deviations for the cutoff of the
%    gaussian kernel (default 3).
%
%    'absolutePrefactor' - if the absolute colorMode is used, this modifies
%    the maximum value for a given prefactor (default 0.85)
%
%
% OUTPUT arguments:
%    network - Network structure with the following elements:
%      network.RS - Sparse matrix of size NxN, being N the number of nodes.
%      Element RS(i,j) indicates the weight of the connection from i to j
%      (1 if unweighted).
%      network.X - Vector of length N with the X position of the nodes.
%      network.Y - Vector of length N with the Y position of the nodes.
%
%
% EXAMPLE:
%    network = YAMLToNetwork(yourFile.yaml);
%    spy(newtork.RS);
%    figure;
%    scatter(network.X, network.Y);
%

%%% Assign defuault values
params.fileName = 'movie';
params.colorMode = 'absolute';
params.movieMode = 'standard';
params.cmap = jet(256);
params.fps = 15;
params.imageSize = [256 256];
params.figureSize = [400 400];
params.samples = 1:1000;
params.gkSigmaXY = 0.03;
params.gkNXY = 3;
params.absolutePrefactor = 0.85;
params = parse_pv_pairs(params,varargin); 

% Redefine the params
fileName = params.fileName;
colorMode = params.colorMode;
movieMode = params.movieMode;
fps = params.fps;
imageSize = params.imageSize;
figureSize = params.figureSize;
samples = params.samples;
cmap = params.cmap;
gkSigmaXY = params.gkSigmaXY;
gkNXY = params.gkNXY;
absolutePrefactor = params.absolutePrefactor;


% Precompute the ranges and normalization factors of each neuron
xSize = max(network.X)-min(network.X);
ySize = max(network.X)-min(network.X);

xRange = [min(network.X), max(network.X)] + [-1, 1]*xSize/50;
yRange = [min(network.Y), max(network.Y)] + [-1, 1]*ySize/50;

xVector = linspace(xRange(1), xRange(2), imageSize(1));
yVector = linspace(yRange(1), yRange(2), imageSize(2));

% Generate the grid (image data points)
[gridX, gridY] = meshgrid(xVector,yVector);
gapX = diff(gridX(1,1:2));
gapY = diff(gridY(1:2,1));

spread = cell(length(network.X),1);

% Apply the gaussian kernel around each neuron to the grid. I think there's
% some error in the normalization, but it shouldn't matter.
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
    value = normpdf(gridX(rangeY,rangeX), nX, gkSigmaXY).*normpdf(gridY(rangeY,rangeX), nY, gkSigmaXY)/fullNorm;

    spread{idx}.rangeX = rangeX;
    spread{idx}.rangeY = rangeY;
    spread{idx}.value = value;
end

% Fast pass to get the min max fluorescence
if(strcmp(colorMode,'absolute'))
    disp('Doing a first pass to find the maximum fluorescence value...');
    minF = inf;
    maxF = -inf;

    for t = samples
        fluorescenceImg = zeros(size(gridX));
        for idx = 1:length(network.X)
            fluorescenceImg(spread{idx}.rangeY,spread{idx}.rangeX) = fluorescenceImg(spread{idx}.rangeY,spread{idx}.rangeX)+...
                F(t, idx)*spread{idx}.value;
        end
        minF = min([minF; fluorescenceImg(:)]);
        maxF = max([maxF; fluorescenceImg(:)]);
    end
    maxF = absolutePrefactor*maxF;
    disp('Done. Generating the movie...');
end

%%% Generate the movie structure
if(~isempty(fileName))
    if(ismac)
        R = VideoWriter(fileName,'MPEG-4');
    else
        R = VideoWriter(fileName,'Motion JPEG AVI');
    end
    R.FrameRate = fps;
    open(R);
end

% Some Plot options
FSIZE = 12;
barHeightFactor = 0.75;
barWidth = 0.025;

% Create the figure of the desired size
hfig = figure;
set(hfig,'units','pixels');
pos = get(hfig,'position');
set(hfig,'position',[pos(1:2), figureSize(1), figureSize(2)]);

for t = samples
    fluorescenceImg = zeros(size(gridX));

    for idx = 1:length(network.X)
        fluorescenceImg(spread{idx}.rangeY,spread{idx}.rangeX) = fluorescenceImg(spread{idx}.rangeY,spread{idx}.rangeX)+...
            F(t, idx)*spread{idx}.value;
    end
    
    %%% The plot itself
    clf;
    
    % For the fast movie mode
    if(strcmp(movieMode, 'fast'))
        if(strcmp(colorMode, 'absolute'))
            Findex = round((size(cmap,1)-1)*(fluorescenceImg-minF)/(maxF-minF)+1);
        else
            Findex = round((size(cmap,1)-1)*(fluorescenceImg-min(fluorescenceImg(:)))/(max(fluorescenceImg(:))-min(fluorescenceImg(:)))+1);
        end
        % Either directly save the move or show it on screen
        if(~isempty(fileName))
            writeVideo(R, ind2rgb(Findex, cmap));
        else
            imshow(Findex, cmap);
            drawnow;
        end
        continue;
    end
    
    
    pcolor(gridX, gridY, fluorescenceImg);
    axis xy;
    shading interp;
    colormap(cmap);
    
    set(gca,'units','normalized');
    axPos = get(gca,'position');
    cb = colorbar('location','WestOutside');
    cblabel('Fluorescence Intensity (absolute)');
    
    set(cb,'yaxisloc','left');
    
    barPosition(4) = axPos(4)*barHeightFactor;
    barPosition(3) = barWidth;
    barPosition(2) = axPos(2)+axPos(4)*(1-barHeightFactor)/2;
    barPosition(1) = axPos(1);
    
    naxPos = [axPos(1)+barWidth+0.025, axPos(2), axPos(3)-barWidth-0.025, axPos(4)];
    set(cb,'position',barPosition);
    set(gca, 'position', naxPos);
    
    %%% Set the axis limits
    xlim(xRange);
    ylim(yRange);
    if(strcmp(colorMode,'absolute'))
        caxis([minF, maxF]);
    else
        caxis([min(fluorescenceImg(:)), max(fluorescenceImg(:))])
    end
    cl = caxis;

    set(gca,'XTick',[]);
    set(gca,'YTick',[]);
    set(cb,'YTick', cl);
    set(cb,'YTickLabel', sprintf('%.0f|',get(cb,'YTick')));
    
    grid off;box on;
    axis square;

    set(gca,'Color','none');

    title(sprintf('sample = %d',t));
    
    %%% Final touches
    %set(findall(gcf,'-property','FontName'), 'FontName', FNAME);
    set(findall(gcf,'-property','FontSize'), 'FontSize', FSIZE);
    drawnow;
    
    % Record inside the movie
    if(~isempty(fileName))
        writeVideo(R, getframe(gcf));
    end
    
end

close(hfig);

if(~isempty(fileName))
    close(R);
    disp('Movie sucesfully recorded.');
end
