function h = plotFluorescenceHistogram(F, varargin)
% PLOTFLUORESCENCEHISTOGRAM plots the fluorescence histogram
%
% USAGE:
%    h = plotFluorescenceHistogram(F, varargin)
%
% INPUT arguments:
%    F - Fluorescence data (each row a sample, each column a neuron).
%
% INPUT optional arguments ('key' followed by its value): 
%    'bins' - Bins for the histogram (three possible formats):
%        Integer <= 0 - The function sshist is used for an automatic guess 
%        on the number of bins. If the data is large (>10^5) sshist can
%        take quite a while.
%        Integer > 0 - Number of bins.
%        Vector - position of the bin centers.
%
%    'axisScale' - ('linear', 'semilogx', 'semilogy', 'loglog'). Type of
%    scale used for the axis (default semilogy).
%
%    'average' - (true/false). True averages the fluorescence signal over all
%    neurons (default true).
%
%    'plotMode' - ('line','bar'). Type of plot (default line).
%
% OUTPUT arguments:
%    h - axis handle.
%
% EXAMPLE:
%    figure;
%    h = plotFluorescenceHistogram(F, 'axisScale', 'linear');
%    set(h, 'Color', 'k');
%
%    (Stetter 2013) Stetter, O., Battaglia, D., Soriano, J. & Geisel, T. 
%    Model-free reconstruction of excitatory neuronal connectivity from 
%    calcium imaging signals. PLoS Comput Biol 8, e1002653 (2012).

%%% Assign defuault values
params.bins = 0;
params.axisScale = 'semilogy';
params.average = true;
params.plotMode = 'line';
params = parse_pv_pairs(params,varargin); 

%%% Average the fluorescence data (if required)
if(params.average)
    newF = mean(F,2);
else
    newF = F(:);
end

%%% Define the bins
if(length(params.bins) == 1 && params.bins <= 0)
    bins = sshist(newF);
    fprintf('Best guess on bin number: %d\n', bins);
else
    bins = params.bins;
end

%%% Perform the histogram
[hits, pos] = hist(newF, bins);

%%% Plot
if(strcmp(params.plotMode,'line'))
    h = plot(pos, hits);
elseif(strcmp(params.plotMode,'bar'))
    h = bar(pos, hits);
else
    error('plotMode invalid. Valid options are: ''line'' and ''bar''.');
end

%%% Change the scale
if(strcmp(params.axisScale,'linear'))
    set(gca,'XScale','linear');
    set(gca,'YScale','linear');
elseif(strcmp(params.axisScale,'semilogx'))
    set(gca,'XScale','log');
    set(gca,'YScale','linear');
elseif(strcmp(params.axisScale,'semilogy'))
    set(gca,'XScale','linear');
    set(gca,'YScale','log');
elseif(strcmp(params.axisScale,'loglog'))
    set(gca,'XScale','log');
    set(gca,'YScale','log');
else
    error('axisScale invalid. Valid options are: ''linear'', ''semilogx'', ''semilogy'' and ''loglog''.');
end

%%% Add some text
xlabel('Fluorescence');
ylabel('hits');
