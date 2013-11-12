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
networkFile = ['topologies' filesep 'topology_iNet1_Size50_CC03.yaml'];
indicesFile = ['spikes' filesep 'indices_iNet1_Size50_CC03.dat'];
timesFile = ['spikes' filesep 'times_iNet1_Size50_CC03.dat'];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% DEFINE THE OUTPUT FILES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
outputNetworkFile = ['challenge' filesep 'network_iNet1_Size50_CC03.txt'];
outputNetworkPositionskFile = ['challenge' filesep 'networkPositions_iNet1_Size50_CC03.txt'];
outputFluorescenceFile = ['challenge' filesep 'fluorescence_iNet1_Size50_CC03.txt'];
outputCommentsFile = ['challenge' filesep 'comments_iNet1_Size50_CC03.txt'];

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
MSG = 'Done!';
disp([datestr(now, 'HH:MM:SS'), ' ', MSG]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

