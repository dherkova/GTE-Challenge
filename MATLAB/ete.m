%% Calculating ETE main script

% Load Spikes
cd('~/Research/Neurons/ETE/');
path(path,'~/Research/Neurons/Matlab');
path(path,'~/Research/Neurons/Matlab/YAMLMatlab');

networkFolder = '~/Projects/te_data/networks/rgraph/';
folder = '~/Projects/te_data/nest/rgraph/inh_switch/';

baseFile = 'uniN100a0125c03inh02_';
%baseFile = 'uniN100a035c04inh02_';
iteration = 1;
tagname = '_0_2-oldtry-15sec-inh-diffneu2spk';
idxFile = strcat(baseFile,num2str(iteration),tagname,'_s_index.dat');
timeFile = strcat(baseFile,num2str(iteration),tagname,'_s_times.dat');

N = load(strcat(folder, idxFile))+1;
T = load(strcat(folder, timeFile))*1e-3;

yamlFile = strcat(networkFolder, baseFile, num2str(iteration),'.yaml');
networkstruct = YAMLToConnectivityMatrix(yamlFile);
RS = networkstruct.RS;

%% Define some variables and paramters
Nneurons = 50;
X_k = 2; % Markov order of X
Y_k = 2; % Markov order of Y
CL = []; % If the CL is not defined we choose it later interactively
%samples = 300001; % If the samples are not defined, we use all of them
samples = 150001; % If the samples are not defined, we use all of them
offsetsamples = 1000; % To avoid the first points
highPassFilterData = true; % Using the difference of the Fluorescence
dataBins = 3; % Discretization of the signal
globalBins = 2; % This is for the CL and Dynamical States

if(~isempty(samples) && globalBins ~= 2)
    warning('CL defined and globalBins ~= 2. Using CL and globalBins = 2'); %#ok<WNTAG>
    globalBins = 2;
end
firstSample = 1+max([X_k, Y_k]);

%% Generate The global signal
T = firings.T;
N = firings.N;
RS = network.RS;
Trange = [min(T), max(T)];
% Dummy signal to get vector sizes
[t, ~] = spikesToFluorescence(T(N == 1), 'Trange', Trange);
F = zeros(size(t));
minsignal = inf;
maxsignal = -inf;
%progressbar('Generating Global Fluorescence signal...');
for i = 1:Nneurons;
    [~, tmpF] = spikesToFluorescence(T(N == i), 'Trange', Trange);
    if(highPassFilterData)
        tmpx = diff(tmpF);
    else
        tmpx = tmpF; %#ok<UNRCH>
    end
    minsignal = min([tmpx, minsignal]);
    maxsignal = max([tmpx, maxsignal]);
    F = F + tmpF;
 %   progressbar(i/Nneurons);
end
F = F/length(RS);
if(isempty(samples))
    samples = length(F)-offsetsamples;
end

if(offsetsamples+samples > length(F))
    error('Number of samples bigger than the original signal');
end
t = t(offsetsamples+1:offsetsamples+samples);
F = F(offsetsamples+1:offsetsamples+samples);


% Select the CL
%createFigure(20,10);
figure;
FSIZE = 14;
histbins = sshist(F);
[a, b] = hist(F, histbins);
bar(b, a);
set(gca, 'YScale', 'log');

if(isempty(CL) && globalBins == 2)
    [CL, ~]=ginput(1);
    disp('Please, select the Conditioning Level');
    disp(sprintf('CL Selected = %.3f', CL));
end

dataBinsEdges = linspace(minsignal, maxsignal, dataBins+1);
dataBinsEdges(1) = -inf; % Just in case
dataBinsEdges(end) = inf; % Just in case
disp(strcat(sprintf('Data signal limits = '),sprintf(' %.2f ', dataBinsEdges)));

% Either we have CL and 2 bins, or we have N bins
if(~isempty(CL))
    globalBinsEdges = [-inf, CL, inf];
else
    globalBinsEdges = linspace(min(F), max(F), globalBins+1);
    globalBinsEdges(1) = -inf; % Just in case
    globalBinsEdges(end) = inf; % Just in case
end
disp(strcat(sprintf('Global signal limits = '),sprintf(' %.2f ', globalBinsEdges)));

hold on;
yl = ylim;
for i =2:length(globalBinsEdges)-1
    plot([1, 1]*globalBinsEdges(i), yl, 'k--');
end

% Now we can already define the G vector
G = zeros(size(t));
for i = 1:length(globalBinsEdges)-1
    G(F > globalBinsEdges(i) & F <= globalBinsEdges(i+1)) = i;
end
% If we use the filter we need to remove the last sample
if(highPassFilterData)
    G = G(1:end-1);
end
%% Now we can already compute the TE !!
Nneurons = 50;
% First, load all the Fluorescence data into memory (might run into
% problems)
% Problems so far, we're computing the whole Fluorescence signal
Fdata = zeros(Nneurons, length(G));

%progressbar('Generating Fluorescence signals...');
for i = 1:Nneurons
    [~, F] = spikesToFluorescence(T(N == i), 'Trange', Trange);
    F = F(offsetsamples+1:offsetsamples+samples);
    if(highPassFilterData)
        x = diff(F);
    else
        x = F; %#ok<UNRCH>
    end
    % Discretize the signal
    Y = zeros(size(x));
    for k = 1:length(dataBinsEdges)-1
        Y(x > dataBinsEdges(k) & x <= dataBinsEdges(k+1)) = k;
    end
    Fdata(i,:) = Y;
 %   progressbar(i/Nneurons);
end
tic
[originalTE, originalH, TEfull] = TEfunction(Fdata, G, Nneurons, globalBins, dataBins, X_k, Y_k, firstSample);
GTE = squeeze(originalTE(:,:,1));
toc

%% 
globalBins = 2;
dataBins = 3;
X_k = 2;
Y_k = 2;
firstSample = 3;
Fdata = D';
G = G';
Nneurons = 50;
tic
[originalTE, originalH, TEfull] = TEfunction(Fdata, G, Nneurons, globalBins, dataBins, X_k, Y_k, firstSample);
GTE = squeeze(originalTE(:,:,1));
toc



%% With bootstrap
% Lets try with a subset of neurons
Nneurons = 20;
bootstrapRuns = 20;
fullTE = zeros(Nneurons, Nneurons, globalBins+1, bootstrapRuns);

if(highPassFilterData)
    originalFdata = zeros(Nneurons, length(G)+1);
else
    originalFdata = zeros(Nneurons, length(G)); %#ok<UNRCH>
end

progressbar('Generating Fluorescence signals...');
for i = 1:Nneurons
    [~, F] = spikesToFluorescence(T(N == i), 'Trange', Trange);
    originalFdata(i, :) = F(offsetsamples+1:offsetsamples+samples);
    progressbar(i/Nneurons);
end

% The bootstrap itself
tic
progressbar('Running bootstrap sampling...','Calculating TE...');
for bs = 1:bootstrapRuns
    bootstrapData = bootstrapTE(originalFdata, 'type', 'jackknife', 'silent', true, 'blockRange', [1 10],'ACLength', 2000);
    if(highPassFilterData)
        Fdata = zeros(Nneurons, size(bootstrapData,2)-1);
    else
        Fdata = zeros(Nneurons, size(bootstrapData,2));
    end
    for i = 1:Nneurons
        if(highPassFilterData)
            x = diff(bootstrapData(i,:));
        else
            x = bootstrapData(i,:); %#ok<UNRCH>
        end
        % Discretize the signal
        Y = zeros(size(x));
        for k = 1:length(dataBinsEdges)-1
            Y(x > dataBinsEdges(k) & x <= dataBinsEdges(k+1)) = k;
        end
        Fdata(i,:) = Y;
    end
    [fullTE(:, :, :, bs), ~] = TEfunction(Fdata, G(1:size(Fdata,2)), Nneurons, globalBins, dataBins, X_k, Y_k, firstSample);
    
    progressbar(bs/bootstrapRuns,[])
end
toc

%%
meanTE = mean(fullTE,4);
stdTE = std(fullTE,0, 4);
meanTE = meanTE(:,:,1);
stdTE = stdTE(:,:,1);
originalTE = originalTE(:,:,1);
%%
[~, sortedidx] = sort(meanTE(:),'descend');
plot(meanTE(sortedidx),'.');
hold on;
plot(meanTE(sortedidx)+stdTE(sortedidx),'.r');
plot(meanTE(sortedidx)-stdTE(sortedidx),'.r');
%%
figure;
h = ciplot(meanTE(sortedidx)-stdTE(sortedidx),meanTE(sortedidx)+stdTE(sortedidx),...
    1:length(sortedidx),[0.8, 0.8, 0.8]*0.8);
set(h,'EdgeColor','none');
hold on;
h = ciplot(meanTE(sortedidx)-stdTE(sortedidx)/sqrt(size(fullTE,4)),...
           meanTE(sortedidx)+stdTE(sortedidx)/sqrt(size(fullTE,4)),...
           1:length(sortedidx),[0.8, 0.8, 0.8]*0.5);
set(h,'EdgeColor','none');
plot(meanTE(sortedidx),'k');
plot(originalTE(sortedidx),'b');
yl = ylim;
set(gca,'XTick', 1:length(sortedidx));
set(gca,'XTickLabel', num2str(sortedidx));
plot([(1:length(meanTE(:))).*~~networkstruct.RS(sortedidx)'; (1:length(meanTE(:))).*~~networkstruct.RS(sortedidx)'],[yl(1)*ones(length(meanTE(:)),1),yl(2)*ones(length(meanTE(:)),1)]','-k');

%%
TE = originalTE(:,:, 1);
[~, sortedidx] = sort(TE(:),'descend');
plot(TE(sortedidx),'k');
yl = ylim;
hold on;
set(gca,'XTick', 1:length(sortedidx));
set(gca,'XTickLabel', num2str(sortedidx));
plot([(1:length(TE(:))).*~~networkstruct.RS(sortedidx)'; (1:length(TE(:))).*~~networkstruct.RS(sortedidx)'],[yl(1)*ones(length(TE(:)),1),yl(2)*ones(length(TE(:)),1)]',':k');

%%
siz = size(zeros([dataBins*[1, ones(1,X_k), ones(1,Y_k)], globalBins]));
ndx = 20;
nout = 6;

%% The ROC curve

x = linspace(0, 1, 1000);

trueLinks_F = sum(sum(~~networkstruct.RS));
trueLinks_E = sum(sum(networkstruct.RS > 0));
trueLinks_I = sum(sum(networkstruct.RS < 0));
falseLinks = length(networkstruct.RS)^2-length(networkstruct.RS)-trueLinks_F;

A_F = ~~networkstruct.RS;
A_E = networkstruct.RS > 0;
A_I = networkstruct.RS < 0;
A_FL = ~networkstruct.RS-diag(diag(~networkstruct.RS));

TPR_F_Ton = zeros(size(x));
TPR_E_Ton = zeros(size(x));
TPR_I_Ton = zeros(size(x));
FPR_Ton = zeros(size(x));


TEThreshold_Inh_on = (max(max(TE(:)))-min(min(TE(:))))*x+min(min(TE(:)));

[inhNeurons, ~]  = find(networkstruct.RS < 0);
inhNeurons = unique(inhNeurons);
excNeurons = setxor(inhNeurons, 1:length(networkstruct.RS));

for i = 1:length(x)

    Ton = (TE(:,:,1) >= TEThreshold_Inh_on(i));

    TPR_F_Ton(i) = sum(sum(Ton.*A_F))/sum(sum(A_F));
    TPR_E_Ton(i) = sum(sum(Ton.*A_E))/sum(sum(A_E));
    TPR_I_Ton(i) = sum(sum(Ton.*A_I))/sum(sum(A_I));
    FPR_Ton(i)   = sum(sum(Ton.*A_FL))/sum(sum(A_FL));
end

%% Now the plots for the IR
figure;
hold on;
plot(FPR_Ton, TPR_F_Ton,'-k');
plot(FPR_Ton, TPR_E_Ton,'-r');
plot(FPR_Ton, TPR_I_Ton,'-b');


%% Bootstrap tests

[TF, F] = spikesToFluorescence(T(N == 5), 'Trange', Trange);
Fsubset = F((offsetsamples+1):(offsetsamples+samples));
Tsubset = TF((offsetsamples+1):(offsetsamples+samples));

%% Xcorr
[c, lags] = xcorr(Fsubset, 'unbiased');
shiftc = fftshift(c);
Nlags = 10000;
plot((1:Nlags)*20e-3,shiftc(1:Nlags));

%% Now the block size
ACLength = 2000; % in ms
blockRange = [1, 5]*floor(ACLength/20);

%% Now assign block size for each point
blockSizes = randi(blockRange, size(Fsubset));
selectedPoints = randi(length(Fsubset), size(Fsubset));
cumBlockSum = cumsum(blockSizes(selectedPoints));
lastBlock = find(cumBlockSum <= length(Fsubset),1,'last'); 
selectedPoints = selectedPoints(1:lastBlock);
bootstrapSignal = Fsubset;
currPoint = 1;
for i = 1:length(selectedPoints)
    bootstrapSignal(currPoint:currPoint+blockSizes(selectedPoints(i))-1) = ...
        F(selectedPoints(i):selectedPoints(i)+blockSizes(selectedPoints(i))-1);
    currPoint = currPoint+blockSizes(selectedPoints(i))-1;
end
%% Subplot
Nsamples = 500;
plot(Tsubset(1:Nsamples), Fsubset(1:Nsamples));
hold on;
plot(Tsubset(1:Nsamples), bootstrapSignal(1:Nsamples),'r');

%% Xcorr comparison
Nlags = 5000;
[c, lags] = xcorr(bootstrapSignal, 'unbiased');
shiftc = fftshift(c);
plot((1:Nlags)*20e-3,shiftc(1:Nlags));
hold on;
[c, lags] = xcorr(Fsubset, 'unbiased');
shiftc = fftshift(c);
plot((1:Nlags)*20e-3,shiftc(1:Nlags),'r');
%%

plot(TF(offsetsamples:offsetsamples+Nlags), F(offsetsamples:offsetsamples+Nlags));

%% The bootstrap function
bootstrapData = bootStrapTE(Fdata,'type','disjoint');


%% Verification
figure;
hold on;
plot(Fdata(1,:),'r');
plot(Fdata(2,:),'g');



%% Some more check on bootstrapping
bootstrapData = bootstrapTE(originalFdata, 'type', 'joint',...,
    'silent', true, 'blockRange', [2 2],'ACLength', 2000);

figure;
hold on;
plot(originalFdata(1,1:1000)+0.01);
plot(bootstrapData(1,1:1000),'r');



