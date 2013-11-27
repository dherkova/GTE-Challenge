function h = visualizeFluorescenceTimeSeries(F, varargin)
% VISUALIZEFLUORESCENCETIMESERIES plots in the current figure the
% fluorescence time series. See the options for a detailed usage.
%
% USAGE:
%    h = visualizeFluorescenceData(F, varargin)
%
% INPUT arguments:
%    F - Fluorescence data (each row a sample, each column a neuron).
%
% INPUT optional arguments ('key' followed by its value): 
%    'type' - ('average', 'single', 'both'). 'average' plots the averaged fluorescence
%    signal. 'single', plots the individual series (see neuronList). 'both'
%    plots everything (default average).
%
%    'neuronList' - vector containing the neuron indices to plot. If empty
%    it will plot all of them (default 1:5).
%
%    'offset' - Adds an offset to the fluorescence signal to  beable to
%    distinguish the traces more clearly (default 0).
%
%    'samples' - Vector containing the samples to plot (default 1:1000).
%
%    'cmap' - Colormap to use in each time series. A colormap is an m-by-3
%    matrix of real numbers between 0.0 and 1.0. Each row is an RGB vector
%    that defines one color. The kth row of the colormap defines the kth
%    color, where map(k,:) = [r(k) g(k) b(k)]) specifies the intensity of
%    red, green, and blue (see colormap function for details), (default
%    uses the jet colormap)
%
%
% OUTPUT arguments:
%    h - (set of) axis handle(s). The last one will be the average (if it
%    exists)
%
%
% EXAMPLE:
%    To plot all neurons together with a little offset:
%    h = visualizeFluorescenceTimeSeries(F, 'type', 'single','offset',0.02, 'neuronList', 1:size(F,2))
%    To plot just the average of the whole time series
%    h = visualizeFluorescenceTimeSeries(F, 'samples', 1:size(F,1));
%

%%% Assign defuault values
params.type = 'average';
params.neuronList = 1:5;
params.offset = 0;
params.samples = 1:5000;
params.cmap = [];
params = parse_pv_pairs(params,varargin); 

%%% Some renaming
samples = params.samples;
cmap = params.cmap;
offset = params.offset;

%%% Create the average signal
if(strcmp(params.type, 'average') || strcmp(params.type, 'both'))
    avgF = mean(F(samples, :),2);
end

%%% Set the colormap
if(isempty(params.cmap))
    cmap = jet(length(params.neuronList));
end

%%% Create the subset signals
if(strcmp(params.type, 'single') || strcmp(params.type, 'both'))
    subF = F(samples, params.neuronList);
    hold on; % Can go here
else
    subF = avgF;
    cmap = [0, 0, 0];
end


h = [];
%%% With the previous definitions we always plot subF and only avgF if
%%% 'both' is chosen.
for i = 1:size(subF,2)
    h = [h; plot(samples, subF(:, i)+offset*(i-1), 'Color', cmap(i, :))];
end
if(strcmp(params.type, 'both'))
    h = [h; plot(samples, avgF, 'Color', [0 0 0])];
end

xlim([samples(1)-0.5 samples(end)+0.5]);
xlabel('sample nunmber');
ylabel('Fluorscence signal');

