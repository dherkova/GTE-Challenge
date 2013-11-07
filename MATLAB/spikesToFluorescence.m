function [F, T] = spikesToFluorescence(spikeTimes, varargin)
% SPIKESTOFLUORESCENCE converts a vector with spike times to a
% fluorescence signal (Stetter 2013).
%
% USAGE:
%    [F,T] = spikesToFluorescence(spikeTimes, varargin)
%
% INPUT arguments:
%    spikeTimes - a vector containing spike times
%
% INPUT optional arguments ('key' followed by its value): 
%    'dt' - time step (default 20e-3s)
%    'tau_Ca' - time constant of the Ca signal decay (default 1s)
%    'A_Ca' - increase in Ca after a spike (default 50 uM)
%    'K_d' - Ca saturation concentration (defualt 300 uM)
%    'noise_str' - strength of the white noise in the Fluorescence signal
%    'Trange' - vector with values [Tmin Tmax]. Discretizes the signal
%    between Tmin and Tmax (if empty Tmin and Tmax are the minimum and
%    maximum spike times)
%
% OUTPUT arguments:
%    F - The fluorescence signal
%    T - The discretized time vector (If Trange is given this is just
%    Tmin:dt:Tmax)
%
% EXAMPLE:
%    spikeTimes = cumsum(exprnd(1, 100, 1));
%    [F, T] = spikesToFluorescence(spikeTimes, 'Trange', [0 30]);
%    plot(T,F);
%
%    (Stetter 2013) Stetter, O., Battaglia, D., Soriano, J. & Geisel, T. 
%    Model-free reconstruction of excitatory neuronal connectivity from 
%    calcium imaging signals. PLoS Comput Biol 8, e1002653 (2012).

%%% Assign defuault values
params.dt = 20e-3; % s
params.tau_Ca = 1; % s
params.A_Ca = 50; % uM
params.K_d = 300; % uM
params.noise_str = 0.03;
params.Trange = [];
params = parse_pv_pairs(params,varargin);

dt = params.dt;
tau_Ca = params.tau_Ca;
A_Ca = params.A_Ca;
K_d = params.K_d;
noise_str = params.noise_str;

%%% Create the time vector
if(isempty(params.Trange))
    T = (min(spikeTimes)):dt:(max(spikeTimes));
else
    T = params.Trange(1):dt:params.Trange(2);
end
Ca = zeros(size(T));

%%% Iterate through all the spikes
% Not the best code, but hey. TODO: This can be calculated exactly.
i = 1;
nextSpike = spikeTimes(i);
for step = 2:length(T)
    Ca(step) = Ca(step-1)*(1 - dt/tau_Ca);
    % If this dt we have a spike, update the Ca signal accordingly
    if(T(step) > nextSpike)
        Ca(step) = Ca(step-1) + A_Ca;
        i = i+1;
        if(i < length(spikeTimes))
            nextSpike = spikeTimes(i+1);
        else
            nextSpike = inf;
        end
    end
end

%%% Now create the fluorescence signal
F = Ca./(Ca+K_d)+noise_str*randn(size(Ca));

