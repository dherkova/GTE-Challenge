function [AUC, FPR, TPR, TPRatMark, raw] = calculateROC(network, GTE,  varargin)
% CALCULATEROC calculates the ROC by comparing the GTE scores with the real
% network. The GTE scores are first thresholded and then a smooth curve is
% calculated through interpolation.
%
% USAGE:
%    [AUC, FPR, TPR, TPRatMark, raw] = calculateROC(network, GTE,  varargin)
%
% INPUT arguments:
%    network - A network structure containing the connectivity matrix
%
%    GTE - The GTE scores matrix
%
% INPUT optional arguments ('key' followed by its value): 
%    'plot' - true/false. If true plots the ROC on the current figure;
%
%    'points' - Number of points in the generated ROC curve (default 100).
%
%    'mark' - ratio of false positives to give a single value of TPR
%    (default 0.1).
%
%    'pointsThreshold' - Number of points to use in calculting the
%    thresholding curve (default 100).
%
% OUTPUT arguments:
%    AUC - Calculation of the Area Under the Curve.
%
%    FPR - Vector of false positive ratios.
%
%    TPR - Vector of true positive ratios.
%
%    TPRatMark - Returns the TPR at the specified mark
%
%    raw - Returns the raw data after thresholding (no smoothing applied).
%    This is a structure containing two vectors FPR and TPR.
%
% EXAMPLE:
%    [AUC, FPR, TPR] = calculateROC(network, GTE);
%
%    (Stetter 2013) Stetter, O., Battaglia, D., Soriano, J. & Geisel, T. 
%    Model-free reconstruction of excitatory neuronal connectivity from 
%    calcium imaging signals. PLoS Comput Biol 8, e1002653 (2012).

%%% Assign defuault values
params.plot = true;
params.pointsThreshold = 100;
params.points = 500;
params.mark = 0.1;
params = parse_pv_pairs(params,varargin); 

% Start with partial computations
RS = network.RS;
positivesMatrix = RS > 0;
negativesMatrix = RS == 0;
% Remove the diagonal elements
negativesMatrix(logical(eye(size(negativesMatrix)))) = 0;

[sortedScores, sortedIdx] = sort(GTE(:),'descend');

thresholdList = floor(linspace(1, numel(RS)-length(RS), params.pointsThreshold))';

truePositives = zeros(size(thresholdList));
falsePositives = zeros(size(thresholdList));

for i = 1:length(thresholdList)
    validCons = sortedIdx(1:thresholdList(i));
    thresholdedMatrix = RS.*0;
    thresholdedMatrix(validCons) = 1;

    truePositives(i) = sum(sum(thresholdedMatrix.*positivesMatrix));
    falsePositives(i) = sum(sum(thresholdedMatrix.*negativesMatrix));
end
        
falseRatio = falsePositives/sum(negativesMatrix(:));
trueRatio = truePositives/sum(positivesMatrix(:));

raw.FPR = falseRatio;
raw.TPR = trueRatio;


% Sort based on the false ratio
mat = [falseRatio, trueRatio, thresholdList/max(thresholdList)];
mat = sortrows(mat, 1);
mat = unique(mat, 'rows'); % Eliminate duplicates

falseRatio = mat(:,1);
trueRatio = mat(:,2);
TEThreshold = mat(:,3);

[~, fpos, ~] = unique(falseRatio, 'first');
[uniqueFalseRatio, lpos, ~] = unique(falseRatio, 'last');
uniqueTrueRatio = zeros(size(uniqueFalseRatio));
uniqueTEThreshold = zeros(size(uniqueFalseRatio));
for i = 1:length(uniqueTrueRatio)
    uniqueTrueRatio(i) = mean(trueRatio(fpos(i):lpos(i)));
    uniqueTEThreshold(i) = mean(TEThreshold(fpos(i):lpos(i)));
end

AUC = trapz(uniqueFalseRatio, uniqueTrueRatio);
FPR = linspace(0,1,params.points);
TPR = interp1(uniqueFalseRatio, uniqueTrueRatio, FPR);
TPRatMark = interp1(uniqueFalseRatio, uniqueTrueRatio, params.mark);

if(params.plot);
    plot(FPR,TPR);
    xlim([0 1]);
    ylim([0 1]);
    xlabel('False positive ratio');
    ylabel('True positive ratio');
    hold on;
    plot([1, 1]*params.mark,[0, TPRatMark],'k');
    plot([0, 1]*params.mark,[1, 1]*TPRatMark,'k');
    title(sprintf('AUC %.2f, TPRatMark %.2f', AUC, TPRatMark));
end

