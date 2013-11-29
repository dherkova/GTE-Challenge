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
path(path, challengeFolder);
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

%% Visualize a single neuronal pair
figure;
h = visualizePair(network, F, 10, 14, 'offset', 0.5,'samples',1:1000);

%% Save the newtork as a GEXF file for visualization
outputFile = 'test_network.gexf';
networkToGEXF(network, outputFile);

% Now you can open the GEXF file with Gephi to visualize the network



%% Fluorescence movie, 1 in every 10 samples and no saving
cmap = hot(256);
visualizeFluorescenceMovie(network, F, 'colorMode', 'absolute','samples',1:10:1000, 'fileName',[],'cmap', cmap);



%% Save the movie, but only the fluorescence data
visualizeFluorescenceMovie(network, F, 'colorMode', 'absolute','movieMode','fast','samples',1:1000, 'fileName','newMovie');


