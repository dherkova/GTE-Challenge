function [T, F] = spikesToFluorescence(spikeTimes, varargin)
% Only for a given neuron

params.dt = 20e-3; % s
params.tau_Ca = 1; % s
params.A_Ca = 50; %uM
params.K_d = 300; % uM
params.noise_str = 0.03;
params.debug = false;
params.Trange = [];

params = parse_pv_pairs(params,varargin);

dt = params.dt;
tau_Ca = params.tau_Ca;
A_Ca = params.A_Ca;
K_d = params.K_d;
noise_str = params.noise_str;

% First create the time vector
if(isempty(params.Trange))
    T = (min(spikeTimes)-1):dt:(max(spikeTimes)+1); % With 1s offset
else
    T = params.Trange(1):dt:params.Trange(2);
end
Ca = zeros(size(T));

% Now iterate
i = 1;
step = 2;
nextSpike = spikeTimes(i);

while(step <= length(T))
    % While no spikes, iterate
    while(step <= length(T) && T(step) < nextSpike)
        Ca(step) = Ca(step-1)*(1 - dt/tau_Ca);
        step = step + 1;
    end
    if(step > length(T))
        break;
    end
    % Now we pass a spike, add it (this should work for multiple spikes in
    % the same bin
    Ca(step-1) = Ca(step-1) + A_Ca;
    i = i + 1;
    if(i < length(spikeTimes))
        nextSpike = spikeTimes(i+1);
    else
        nextSpike = inf;
    end
end

% Now create the fluorescence signal
F = Ca./(Ca+K_d)+noise_str*randn(size(Ca));

if(params.debug)
    createFigure(30,20);
    subaxis(2,1,1);
    plot(T, Ca);
    xlabel('Time (s)');
    ylabel('Calcium');
    subaxis(2,1,2);
    plot(T, F);
    xlabel('Time (s)');
    ylabel('Fluorescence');
end
