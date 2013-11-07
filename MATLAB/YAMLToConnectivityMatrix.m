function network = YAMLToConnectivityMatrix(fileName, varargin)
% YAMLTOCONNECTIVITYMATRIX converts a YAML network structure from 
% (Stetter 2013) to a MATLAB network structure.
%
% USAGE:
%    network = YAMLToConnectivityMatrix(fileName, varargin)
%
% INPUT arguments:
%    fileName - YAML file
%
% INPUT optional arguments ('key' followed by its value): 
%    'weighted' - true/false. True if the connections have weights (default
%    is false)
%
% OUTPUT arguments:
%    network - Network structure with the following elements:
%      network.RS - Sparse matrix of size NxN, being N the number of nodes.
%      Element RS(i,j) indicates the weight of the connection from i to j
%      (1 if unweighted).
%      network.X - Vector of length N with the X position of the nodes.
%      network.Y - Vector of length N with the Y position of the nodes.
%
% EXAMPLE:
%    network = YAMLToConnectivityMatrix(yourFile.yaml);
%    spy(newtork.RS);
%    figure;
%    scatter(network.X, network.Y);
%
%    (Stetter 2013) Stetter, O., Battaglia, D., Soriano, J. & Geisel, T. 
%    Model-free reconstruction of excitatory neuronal connectivity from 
%    calcium imaging signals. <b>PLoS Comput Biol</b> 8, e1002653 (2012).

%%% Assign defuault values
params.weighted = false;
params = parse_pv_pairs(params,varargin); 

%%% Load the file
YamlNetwork = ReadYaml(fileName);

if(params.weighted)
    weighted = YamlNetwork.weighted;
else
    weighted = false;
end
N = YamlNetwork.size;
network = [];

network.X = zeros(N, 1);
network.Y = zeros(N, 1);

%%% Iterate through all the connections to create the sparse list
cons = YamlNetwork.cons;
currentCon = 1;
conList = zeros(cons, 3);
for i = 1:N
    node = YamlNetwork.nodes{i};
    network.X(i) = node.pos{1};
    network.Y(i) = node.pos{2};
    for j = 1:length(node.connectedTo);
        if(weighted)
            weight = node.weights{j};
        else
            weight = 1;
        end
        conList(currentCon, :) = [i, node.connectedTo{j}, weight];
        currentCon = currentCon+1;
    end
end

%%% Create the sparse matrix
network.RS = sparse(conList(:,1), conList(:,2), conList(:,3), N, N);


