%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% RECONSTRUCTION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% This script goes from the NEST data up to the reconstruction and the
%%% ROC curves.


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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% DEFINE THE INPUT FILES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
baseFile = 'iNet1_Size50_CC03';

networkFile = ['topologies' filesep 'topology_' baseFile '.yaml'];
indicesFile = ['spikes' filesep 'indices_' baseFile '.dat'];
timesFile = ['spikes' filesep 'times_' baseFile '.dat'];

%% Load spiking data and generate the fluorescence signal

% Load the network
network = YAMLToNetwork(strcat(challengeFolder,networkFile));

% Load the firings
firings = nestToFirings(strcat(challengeFolder,indicesFile), strcat(challengeFolder,timesFile));

% Generate the fluorescence signal
[F, T] = firingsToFluorescence(firings, network);

% Remove the first 10 seconds
minT = find(T > 10, 1, 'first');
T = T(minT:end);
F = F(minT:end, :);


%% Discretize the fluorescence signal
[D, G] = discretizeFluorescenceSignal(F, 'debug', true, 'conditioningLevel', 0.25, 'bins', [-10,0.12,10]);

%% Calculate the joint PDF
P = calculateJointPDFforGTE(D, G);

%% Calculate the GTE from the joint PDF
GTE = calculateGTEfromJointPDF(P);

%% Calculate the ROC curve and plot it
figure;
[AUC, FPR, TPR, TPRatMark, raw] = calculateROC(network, GTE, 'plot', true);

