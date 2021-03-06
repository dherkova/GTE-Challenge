%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% CHALLENGEVALIDATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Example of a Challenge validation. Compares the provided scores matrix
%%% with the true topology using the ROC curve.

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

networkFile = ['challenge' filesep 'network_' baseFile '.txt'];
scoresFile = ['challenge' filesep 'scores_' baseFile '.txt'];


%% Load the network and the scores
networkData = load(networkFile);
N = max(max(networkData(:,1:2)));
network.RS = sparse(networkData(:,1), networkData(:,2), networkData(:,3), N, N);

scores = load(scoresFile);


%% Calculate the ROC curve and plot it
figure;
[AUC, FPR, TPR, TPRatMark, raw] = calculateROC(network, scores, 'plot', true);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
MSG = 'Challenge validated.';
disp([datestr(now, 'HH:MM:SS'), ' ', MSG]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%