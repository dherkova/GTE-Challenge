function P = calculateJointPDFforGTE(D, G, varargin)
% CALCULATEJOINTPDFFORGTE calculates the joint PDF required for the GTE
% computation. Entires are of the form P(i,j,j_now,j_past,i_past). Same
% order as in the paper.
%
% USAGE:
%    P = calculateJointPDFforGTE(D, varargin)
%
% INPUT arguments:
%    D - A vector containing the binned  signal (rows for
%    samples, columns for neurons)
%    G - A vector containing the binned average signal based on the
%    conditioning level, i.e., 1 if the average signal is below CL and 2 if
%    above.
%
% INPUT optional arguments ('key' followed by its value): 
%    'markovOrder' - Markov Order of the process (default 2).
%
%    'IFT' - true/false. If true includes IFT (Instant Feedback Term)
%    (default true).
%    'Nsamples' - Number of samples to use. If empty, it will use the whole
%    vector (default empty).
%
%    'debug' true/false. Prints out some useful information (default true).
%
%
% OUTPUT arguments:
%    P - The joint PDF (unnormalized, divide sum(P(i,j,:)) to normalize.
%
% EXAMPLE:
%    P = calculateJointPDFforGTE(D);
%
%    (Stetter 2013) Stetter, O., Battaglia, D., Soriano, J. & Geisel, T. 
%    Model-free reconstruction of excitatory neuronal connectivity from 
%    calcium imaging signals. PLoS Comput Biol 8, e1002653 (2012).

%%% Assign defuault values
params.markovOrder = 2;
params.IFT = true;
params.debug = true;
params.Nsamples = [];
params = parse_pv_pairs(params,varargin);

% Just in case
if(params.IFT)
    IFT = 1;
else
    IFT = 0;
end
k = params.markovOrder;

% Redefine the vectors based on the number of samples
if(~isempty(params.Nsamples))
    D = D(1:Nsamples, :);
    G = G(1:Nsamples);
end

bins = length(unique(D(~isnan(D))));

% Calculate the amount of dimensions
dims = 2*k;
if(IFT)
    dims = dims + 1;
end
dims = [size(D,2), size(D,2), bins*ones(1, dims), length(unique(G))];

% Create the multidimensional array to store the probability distribution
% Structure: (I, J, Jnow, Jpast, Ipast, G) Past goes in reverse order: now,
% now-1, now-2, ... Although it doesn't really matter, since all
% sums extend over all the past entries.
P = zeros(dims);
sizeP = double(size(P));
ndimsP = ndims(P);
% To access the matrix with a single index
multipliers = [1 cumprod(sizeP(1:end-1))]';

% Define some internal variables
totalEntries = (size(D,2).^2-size(D,2))/2;
currentEntry = 0;
firstSample = k+1;
if(params.debug)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    MSG = 'Generating the joint probability distribution...';
    disp([datestr(now, 'HH:MM:SS'), ' ', MSG]);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end
for i = 1:size(D,2)
    Di = D(:, i);
    for j = (i+1):size(D,2)
        Dj = D(:,j);
        validSamples = firstSample:size(D,1);
        multDi = zeros(length(validSamples), k+1);
        multDj = zeros(length(validSamples), k+1);
        % multD stores the delayed version of D, with columns (Di, Di-1,
        % Di-2...) to have it ready for the probabilities
        multDi(:, 1) = Di(firstSample:end);
        multDj(:, 1) = Dj(firstSample:end);
        for l = 1:k
            multDi(:, l+1) = Di((firstSample-l):(end-l));
            multDj(:, l+1) = Dj((firstSample-l):(end-l));
        end
        coordsIJ = [i*ones(size(multDi,1),1), j*ones(size(multDi,1),1), multDj(:,1:end), multDi(:,(2-IFT):(end-IFT)), G(validSamples)];
        indxIJ = (coordsIJ-1)*multipliers+1;
        P(:) = P(:) + histc(indxIJ, 1:numel(P));
        coordsJI = [j*ones(size(multDj,1),1), i*ones(size(multDi,1),1), multDi(:,1:end), multDj(:,(2-IFT):(end-IFT)), G(validSamples)];
        indxJI = (coordsJI-1)*multipliers+1;
        P(:) = P(:) + histc(indxJI, 1:numel(P));

        currentEntry = currentEntry+1;
        if(params.debug && (mod(currentEntry, floor(totalEntries/10)) == 0));
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            MSG = sprintf('%d%%...', round(currentEntry/totalEntries*100));
            disp([datestr(now, 'HH:MM:SS'), ' ', MSG]);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        end
    end
end
fprintf('\n');

if(params.debug)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    MSG = 'Done!';
    disp([datestr(now, 'HH:MM:SS'), ' ', MSG]);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end

