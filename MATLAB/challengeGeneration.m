%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% CHALLENGEGENERATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% This script generates the data for the challenge (fluorescence and
%%% network structure). Note: The network and spike data have been created
%%% a priori.

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
baseFile = 'iNet1_Size100_CC03';

networkFile = ['../topologies' filesep 'topology_' baseFile '.yaml'];
indicesFile = ['../spikes' filesep 'indices_' baseFile '.dat'];
timesFile = ['../spikes' filesep 'times_' baseFile '.dat'];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% DEFINE THE OUTPUT FILES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
outputNetworkFile = ['challenge' filesep 'network_' baseFile '.txt'];
outputNetworkPositionskFile = ['challenge' filesep 'networkPositions_' baseFile '.txt'];
outputFluorescenceFile = ['challenge' filesep 'fluorescence_' baseFile '.txt'];
outputCommentsFile = ['challenge' filesep 'comments_' baseFile '.txt'];

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


%% Store the data

%%% Store the network (each row of the form [i,j,w] denoting a connection from i
%%% to j with wegiht w). This format allows a direct load of the network
%%% through the sparse function
[i,j,w] = find(network.RS);
networkData = [i, j, w];
dlmwrite(outputNetworkFile, networkData, ',');

%%% Store the neurons positions
positionsData = [network.X, network.Y];
dlmwrite(outputNetworkPositionskFile, positionsData, ',');

%%% Store the fluorescence signal (each row a sample, each column a neuron)
dlmwrite(outputFluorescenceFile, F, ',');

%%% Store some comments
fID = fopen(outputCommentsFile, 'w');
fprintf(fID, '# Neurons: %d\n', length(network.X));
fprintf(fID, '# Fluorescence discretization step: %d ms\n', 20);
fclose(fID);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
MSG = 'Challenge generated.';
disp([datestr(now, 'HH:MM:SS'), ' ', MSG]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

