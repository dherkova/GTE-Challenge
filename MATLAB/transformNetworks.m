%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% TRANSFORMNETWORKS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% This script reads fully excitatory YAML networks, transforms a given
%%% percentage of neurons to inhibitory and saves the result as a new YAML
%%% network

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% DEFINE THE INPUT FILES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
baseFile = 'iNet1_Size100_CC0?';

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

%% Main script

iterator1 = 1:6; % List of network CCs
%iterator1 = 1;
inhibitoryFraction = 0.2;

for it1 = 1:length(iterator1);
    % Load the network
    currFile = strrep(networkFile, '?', num2str(iterator1(it1)));
    network = YAMLToNetwork(strcat(challengeFolder,currFile));
    % Get the number of inhibitory neurons
    Ni = floor(inhibitoryFraction*length(network.X));
    Ni = poissrnd(Ni,1);
    % Get their indices
    idx = randperm(length(network.X));
    idx = idx(1:Ni);
    % Turn these neurons into inhibitory neurons
    for i = idx
        network.RS(i,:) = -1*network.RS(i,:);
    end
    % Now save the network
    YamlNetwork = ReadYaml(strcat(challengeFolder,currFile));
    YamlNetwork.modifiedAt = datestr(now,'mmmm dd, yyyy HH:MM:SS');
    YamlNetwork.weighted = 1;
    for i = 1:length(network.RS);
        cons = find(network.RS(i,:));
        for j = 1:length(cons)
            YamlNetwork.nodes{i}.weights{j} = network.RS(i,cons(j));
        end
    end
    YamlNetwork = orderfields(YamlNetwork,[1 2 3 8 4 5 7 6]);
    oFile = strcat(challengeFolder,strrep(currFile,'.yaml','inh.yaml'));
    WriteYaml(oFile, YamlNetwork);
end





%%