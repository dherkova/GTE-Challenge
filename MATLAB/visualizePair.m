function h = visualizePair(network, F, I, J, varargin)
% VISUALIZEPAIR plots the time series of a pair of neurons I and J and
% tells you the I->J and J->I connetion weights.
%
% USAGE:
%    h = visualizePair(F, varargin)
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
%    I - Index of the first neuron
%
%    J - Index of the second neuron
%
% INPUT optional arguments ('key' followed by its value): 
%
%    'samples' - Vector containing the samples to plot (default 1:1000).
%
%    'offset' - Adds an offset to the fluorescence signal to  beable to
%    distinguish the traces more clearly (default 0).
%
% OUTPUT arguments:
%    h - (set of) axis handle(s). The last one will be the average (if it
%    exists)
%
%
% EXAMPLE:
%    h = visualizePair(network, F, 10, 14, 'offset', 0.5,'samples', 1:1000);
%

%%% Assign defuault values
params.samples = 1:5000;
params.offset = 0;
params = parse_pv_pairs(params,varargin); 

%%% Some renaming
samples = params.samples;
offset = params.offset;

h = [];

hold on;
h = [h; plot(samples, F(samples, I), 'r')];
h = [h; plot(samples, F(samples, J)+offset, 'b')];
xlim([samples(1)-0.5 samples(end)+0.5]);
xlabel('sample nunmber');
ylabel('Fluorscence signal');
legend('I', 'J');
title(sprintf('Weights: I->J: %.2f, J->I: %.2f', full(network.RS(I,J)), full(network.RS(J,I))));
