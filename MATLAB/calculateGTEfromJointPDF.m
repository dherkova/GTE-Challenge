function GTE = calculateGTEfromJointPDF(P, varargin)
% CALCULATEGTEFROMJOINTPDF calculates GTE from the joint PDF.
%
% USAGE:
%    GTE = calculateGTEfromJointPDF(P, varargin)
%
% INPUT arguments:
%    P - The joint PDF.
%
% INPUT optional arguments ('key' followed by its value): 
%    'returnFull' - (true/false). If true returns all the GTE computations
%    based on the conditioning levels. If false, only returns a single
%    score, the one in the first level (default false).
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
params.debug = true;
params.returnFull = false;
params = parse_pv_pairs(params,varargin);

if(params.debug)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    MSG = 'Calculating Generalized Transfer Entropy from the joint PDFs';
    disp([datestr(now, 'HH:MM:SS'), ' ', MSG]);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end

% Find previous variables
ndimsP = ndims(P);
bins = size(P,3);
k = (ndimsP-4)/2;

%%% Start generating the partial sums
% Notation I->J
Jnow = sum(P,3);
tmpRepmat = ones(1,ndimsP);
tmpRepmat(3) = bins;
Jnow = repmat(Jnow, tmpRepmat);

Ipast = P;
for dim = 1:k
    Ipast = sum(Ipast,ndimsP+1-dim-1);
end

tmpRepmat = ones(1,ndimsP);
tmpRepmat((end-k+1-1):end-1) = bins;
Ipast = repmat(Ipast, tmpRepmat);

JnowIpast = sum(Ipast,3);
tmpRepmat = ones(1,ndimsP);
tmpRepmat(3) = bins;
JnowIpast = repmat(JnowIpast, tmpRepmat);

%%% Now that we have all the partial sums we can calculate all the products
GTE = P.*log2(P.*JnowIpast./Jnow./Ipast);
% To fix divisions by 0 due to 0 samples
GTE(isnan(GTE)) = 0;
% Now sum over all the dimensions
for dim = (ndimsP-1):-1:3
    GTE = sum(GTE, dim);
end
GTE = squeeze(GTE);

% Now normalize based on the conditioning
for i = 1:size(GTE,3)
    normFactor = P;
    for k = 3:(ndimsP-1);
        normFactor = sum(normFactor,k);
    end
    normFactor = squeeze(normFactor);
    normFactor = 1/(normFactor(1,2,i));
    GTE(:,:,i) = GTE(:,:,i)*normFactor;
end
if(~params.returnFull)
    GTE = GTE(:,:,1);
end

if(params.debug)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    MSG = 'Done!';
    disp([datestr(now, 'HH:MM:SS'), ' ', MSG]);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end
