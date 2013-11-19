%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% CHALLENGEEXAMPLE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Example of a Challenge submission. Loads the provided fluorescence file
%%% and performs the reconstruction (based on GTE). As output it generates
%%% a scoring matrix to be validated against the true network.

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

fluorescenceFile = ['challenge' filesep 'fluorescence_' baseFile '.txt'];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% DEFINE THE OUTPUT FILES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
scoresFile = ['challenge' filesep 'scores_' baseFile '.txt'];

%% Load the Fluorescence signal
F = load(fluorescenceFile);

%% Discretize the fluorescence signal
[D, G] = discretizeFluorescenceSignal(F, 'debug', true, 'conditioningLevel', 0.25, 'bins', [-10,0.12,10]);

%% Calculate the joint PDF
P = calculateJointPDFforGTE(D, G);

%% Calculate the GTE from the joint PDF
GTE = calculateGTEfromJointPDF(P);

%% Store the scoring matrix
%%% Since this matrix is never going to be sparse we save everything
scores = GTE;
dlmwrite(scoresFile, scores, ',');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
MSG = 'Challenge solved.';
disp([datestr(now, 'HH:MM:SS'), ' ', MSG]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

