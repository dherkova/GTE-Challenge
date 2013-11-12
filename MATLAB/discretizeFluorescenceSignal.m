function [D, G] = discretizeFluorescenceSignal(F, varargin)
% DISCRETIZEFLUORESCENCESIGNAL discretizes the fluorescence signal so it
% can be used to compute the joint PDF. If conditioning is applied, the
% entries above the conditioning level are returned in the G vector.
%
% USAGE:
%    D = discretizeFluorescenceSignal(F, varargin)
%
% INPUT arguments:
%    F - Fluorescence data (each row a sample, each column a neuron).
%
% INPUT optional arguments ('key' followed by its value): 
%    'bins' - Number of bins to use in the discretization (before
%    conditioning). If the entry is a vector, it will define the bin edges
%    (default 3).
%
%    'relativeBins' - (true/false). If true the bins are defined based on
%    the min and max values of each sample. If false, they are defined
%    based on the absolute limits (default false).
%
%    'conditioningLevel' - Value used for conditioning. If the
%    value is 0 the level is guessed (for now, the peak of the histogram
%    plus 0.1). Set it to inf to avoid conditioning (default 0).
%
%   'highPassFilter' - (true/false). Apply a high pass filter to the
%   fluorescence signal, i.e., work with the derivative (default true).
%
%    'debug' - true/false. Show additional partial information (default
%    false).
%
%
% OUTPUT arguments:
%    D - The discretized signal (each row a sample, aech column a neuron).
%
%    G - Vector defining the global conditioning level of the signal at
%    that given time (for now 1 and 2 for below and above the level).
%
% EXAMPLE:
%    D = discretizeFluorescenceSignal(F, 'bins', 3, 'debug', true);
%
%    (Stetter 2013) Stetter, O., Battaglia, D., Soriano, J. & Geisel, T. 
%    Model-free reconstruction of excitatory neuronal connectivity from 
%    calcium imaging signals. PLoS Comput Biol 8, e1002653 (2012).

%%% Assign defuault values
params.bins = 3;
params.relativeBins = false;
params.conditioningLevel = 0;
params.debug = false;
params.highPassFilter = true;
params = parse_pv_pairs(params,varargin); 

epsilon = 1e-3; % To avoid weird effects at bin edges

%%% Get the conditioning level
avgF = mean(F,2);
if(params.conditioningLevel == 0)
    [hits, pos] = hist(avgF, 100);
    [~, idx] = max(hits);
    CL = pos(idx)+0.1;
    fprintf('Best guess for conditioning found at: %.2f\n', CL);
else
    CL = params.conditioningLevel;
end

%%% Apply the conditioning
G = (avgF >= CL)+1;

%%% Show the result of conditioning
if(params.debug)
    figure;
    h = plotFluorescenceHistogram(F,'bins',100);
    hold on;
    yl = ylim;
    hCL = plot([1, 1]*CL, yl,'k');
    legend([h, hCL], 'Average F histogram', 'Conditioning Level');
    xlabel('Fluorescence');
    ylabel('hits');
end

%%% Apply the high pass filter
if(params.highPassFilter)
    F = diff(F);
    G = G(1:end-1);
end

%%% Discretize the signal
D = NaN(size(F));
if(length(params.bins) > 1)
    params.relativeBins = false; % Just in case
end
%max(F(:));
if(params.relativeBins)
    for i = 1:size(F, 2)
        binEdges = linspace( min(F(:, i))-epsilon, max(F(:, i))+epsilon, params.bins+1);
        for j = 1:(length(binEdges)-1)
            hits = F(:,i) >= binEdges(j) & F(:,i) < binEdges(j+1);
            D(hits, i) = j;
        end
    end        
else
    if(length(params.bins) == 1)
        binEdges = linspace(min(F(:))-epsilon, max(F(:))+epsilon, params.bins+1);
    else
        binEdges = params.bins;
    end
    for j = 1:(length(binEdges)-1)
        hits = F >= binEdges(j) & F < binEdges(j+1);
        D(hits) = j;
    end
    if(params.debug)
        fprintf('Global bin edges set at: (');
        for j = 1:(length(binEdges)-1)
            fprintf('%.2f,', binEdges(j));
        end
        fprintf('%.2f).\n', binEdges(end));
    end
end
