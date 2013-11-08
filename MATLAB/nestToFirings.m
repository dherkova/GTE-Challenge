function firings = nestToFirings(indicesFile, timesFile, varargin)
% NESTTOFIRINGS loads and converts the output of nest (an indices file and
% a times file to a MATLAB firings structure.
%
% USAGE:
%    firings = nestToFirings(indicesFile, timesFile, varargin)
%
% INPUT arguments:
%    indicesFile - NEST indices file (single column with indices).
%    timesFile - NEST times file (single column with times, in ms).
%
% INPUT optional arguments ('key' followed by its value): 
%    'offset' - Add a given offset to the neuron index (default 1 is
%    required, since NEST labels neurons from 0 to N-1 and MATLAB from 1 to
%    N).
%
% OUTPUT arguments:
%    firings - Structure with the following elements:
%      firings.N - Vector containing the spike indices.
%      firings.T - Vector containing the spike times (now in s).
%
% EXAMPLE:
%    firings = nestToFirings(indices.dat, times.dat);
%    plot(firings.T, firings.N, '.');
%
%    (Stetter 2013) Stetter, O., Battaglia, D., Soriano, J. & Geisel, T. 
%    Model-free reconstruction of excitatory neuronal connectivity from 
%    calcium imaging signals. PLoS Comput Biol 8, e1002653 (2012).

%%% Assign defuault values
params.offset = 1;
params = parse_pv_pairs(params,varargin); 

%%% Load the data
firings.N = load(indicesFile)+params.offset;
firings.T = load(timesFile)*1e-3;
