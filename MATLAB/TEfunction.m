function varargout = TEfunction(Fdata, G, Nneurons, globalBins, dataBins, X_k, Y_k, firstSample)

TE = zeros(Nneurons, Nneurons, globalBins+1);
H = zeros(Nneurons, Nneurons, globalBins+1);
% Dimensions of the probability matrix
P = zeros([dataBins*[1, ones(1,X_k), ones(1,Y_k)], globalBins]);
if(nargout >= 3)
    TEfull = zeros([Nneurons, Nneurons, dataBins*[1, ones(1,X_k), ones(1,Y_k)], globalBins]);
end

sizp= size(P);
indexMultiplier = [1 cumprod(sizp(1:end-1))]';

iteration = 0;
totalIterations = Nneurons^2-Nneurons;
%progressbar('Calculating TE...');
for i = 1:Nneurons
    % Analyzing link i->j (Y->X)
    Y = Fdata(i, :);
    % Now the loop through the output links
    for j = 1:Nneurons
        if(i == j)
            continue
        end
        X = Fdata(j, :);
        
        Pij = P;
        Hij = P;
        % Now fill the probability matrix
%         for k = firstSample:length(X)
%            coords = [X([k, k-(1:X_k)]), Y(k+1-(1:Y_k)), G(k)];
%            indx = (coords-1)*indexMultiplier+1;
%            Pij(indx) = Pij(indx) + 1;
%         end
        k = firstSample:length(X);
        multX = zeros(length(k), X_k+1);
        multY = zeros(length(k), Y_k);
        multX(:, 1) = X(firstSample:end);
        for l = 1:X_k
            multX(:, l+1) = X(firstSample-l:end-l);
        end
        for l = 1:Y_k
            multY(:, l) = Y(firstSample-l+1:end-l+1);
        end
        coords = [multX, multY, G(firstSample:end)'];
        indx = (coords-1)*indexMultiplier+1;
% Using histograms
%         [b, a] = hist(indx,0:numel(Pij)+1);
%         if(b(end) > 0)
%             warning('We have a problem...');
%         end
%         b = b(2:end-1);
%         Pij(:) = Pij(:) + b';
% Using accumarray
%        accumvals = accumarray(indx, 1);
%        Pij(1:length(accumvals)) = accumarray(indx, 1);
% Using histc (faster for now)
        Pij(:) = Pij(:) + histc(indx, 1:numel(Pij));
        
        % Normalization
        Pij = Pij/(length(X)-firstSample+1);
        % Now to convert to TE
        Pij_sumJnow = squeeze(sum(Pij,1));
        Pij_sumI = squeeze(sum(Pij, X_k+2));
        for k = 2:Y_k
            Pij_sumI = squeeze(sum(Pij_sumI, X_k+2));
        end
        Pij_sumJnowI = squeeze(sum(Pij_sumI, 1));
        TEij = zeros(size(Pij));
        %indx=cell(1,ndims(Pij));
        validPij = find(Pij);
        %for k = 1:numel(Pij)
        for k = validPij'
            % Only the valid entries (to avoid infs in the log)
            %if(~Pij(k))
            %    continue
            %end
            indx=cell(1,ndims(Pij));
            %[indx{:}] = ind2sub(size(Pij),k);
            ndx = k;
            %indx = zeros(length(ndims(Pij):-1:1),1);
            for l = ndims(Pij):-1:1,
              vi = rem(ndx-1, indexMultiplier(l)) + 1;         
              vj = (ndx - vi)/indexMultiplier(l) + 1; 
              indx{l} = vj; 
              ndx = vi;     
            end
            
            TEij(k) = Pij(indx{:})*(log(Pij(indx{:}))-log(Pij_sumJnow(indx{2:end}))...
                -log(Pij_sumI(indx{1:X_k+1}))+log(Pij_sumJnowI(indx{2:X_k+1})));
            Hij(k) = -Pij(indx{:})*(log(Pij_sumI(indx{1:X_k+1}))-log(Pij_sumJnowI(indx{2:X_k+1})));
        end
        if(nargout >= 3)
            TEfull(i,j, :) = TEij(:)/log(2);
        end
        tmpTE = squeeze(sum(TEij,1));
        tmpH = squeeze(sum(Hij,1));
        for l = 2:ndims(TEij)-1
            tmpTE = squeeze(sum(tmpTE,1));
            tmpH = squeeze(sum(tmpH,1));
        end
        TE(i,j, 1:end-1) = tmpTE/log(2);
        TE(i,j, end) = sum(tmpTE)/log(2);
        H(i,j, 1:end-1) = tmpH/log(2);
        H(i,j, end) = sum(tmpH)/log(2);
        % The conditional on CL
        for l = 1:(size(TE,3)-1)
            if(~sum(G(firstSample:end) == l))
                TE(i,j, l) = TE(i,j, l)*length(G(firstSample:end))/sum(G(firstSample:end) == l);
                H(i,j, l) = H(i,j, l)*length(G(firstSample:end))/sum(G(firstSample:end) == l);
            end
        end
        iteration = iteration+1;
    end
end

varargout{1} = TE;
varargout{2} = H;
if(nargout >= 3)
    varargout{3} = TEfull;
end