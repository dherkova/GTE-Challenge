function [F, T] = firingsToFluorescence(firings, network, varargin)
% FIRINGSTOFLUORESCENCE converts a MATLAB firings structure to a
% fluorescence signal.
%
% USAGE:
%    [F,T] = firingsToFluorescence(firings, network, varargin)
%
% INPUT arguments:
%    firings - Firings structure (see nestToFirings).
%
%    network - Network structure (see YAMLToConnectivityMatrix), will only
%    be used if lightScattering is true.
%
% INPUT optional arguments ('key' followed by its value): 
%    'dt' - Time step (default 20e-3s).
%
%    'tau_Ca' - Time constant of the Ca signal decay (default 1s).
%
%    'A_Ca' - Increase in Ca after a spike (default 50 uM).
%
%    'K_d' - Ca saturation concentration (default 300 uM).
%
%    'noise_str' - Strength of the white noise in the Fluorescence signal
%    (default 0.03).
%
%    'lightScattering - true/false. Defines if light scattering is added to
%    the fluorescence signal (default false).
%
%    'amplitudeScatter' - Amplitude of light scattering (in mm).
%
%    'sigmaScatter' - Correlation length of light scattering (in mm).
%
%    'Trange' - Vector with values [Tmin Tmax]. Discretizes the signal
%    between Tmin and Tmax (if empty Tmin and Tmax are the minimum and
%    maximum spike times).
%
% OUTPUT arguments:
%    F - The fluorescence signal.
%    T - The discretized time vector (If Trange is given this is just
%    Tmin:dt:Tmax).
%
% EXAMPLE:
%     [F, T] = firingsToFluorescence(firings, network);
%     figure;
%     hold on;
%     plot(T,F(:,1),'b');
%     plot(T,F(:,2),'r');
%     plot(T,mean(F,2),'k');
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
params.lightScattering = true;
params.amplitudeScatter = 0.15;
params.sigmaScatter = 0.05;
params.Trange = [];
params = parse_pv_pairs(params,varargin); 

%%% Create the time vector
if(isempty(params.Trange))
    T = (min(firings.T)):params.dt:(max(firings.T));
else
    T = params.Trange(1):params.dt:params.Trange(2);
end

%%% Generate the set structure that will be passed to the other
%%% fluorescence function
set.dt = params.dt;
set.tau_Ca = params.tau_Ca;
set.A_Ca = params.A_Ca;
set.K_d = params.K_d;
set.noise_str = params.noise_str;
set.Trange = [T(1) T(end)];


%%% Generate the Fluorescence data for each neuron
F = zeros(length(T), length(network.RS));
for i = 1:length(network.RS);
    F(:,i) = spikeTimesToFluorescence(firings.T(firings.N == i), 'set', set);
end

%%% Apply Light Scattering
% Define the Light Scattering amplitudes
if(params.lightScattering)
    LSAmplitudes = zeros(size(network.RS));
    FS = F;
    for i = 1:length(network.RS);
        dist = sqrt((network.X-network.X(i)).^2+(network.Y-network.Y(i)).^2);
        for j = (i+1):length(network.RS);
            LSAmplitudes(i,j) = params.amplitudeScatter*exp(-(dist(j)/params.sigmaScatter)^2);
            LSAmplitudes(j,i) = LSAmplitudes(i,j);
        end
    end
    for i = 1:length(network.RS);
        for j = 1:length(network.RS);
           FS(:, i) =  FS(:, i)+F(:,j)*LSAmplitudes(i,j);
        end
    end
    F = FS;
end
