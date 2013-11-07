%==========================================================================
% Recursively walks through a Matlab hierarchy and converts it to the
% hierarchy of java.util.ArrayListS and java.util.MapS. Then calls
% Snakeyaml to write it to a file.
%=========================================================================
function WriteYaml(filename, data)
    [pth,~,~] = fileparts(mfilename('fullpath'));
    javaaddpath([pth filesep 'external' filesep 'snakeyaml-1.9.jar']);
    import('org.yaml.snakeyaml.*');
    javastruct = scan(data);
    dumperopts = DumperOptions();
    dumperopts.setLineBreak(...
        javaMethod('getPlatformLineBreak',...
        'org.yaml.snakeyaml.DumperOptions$LineBreak'));
    yaml = Yaml(dumperopts);
    
    output = yaml.dump(javastruct);
    fid = fopen(filename,'w');
    fprintf(fid,'%s',char(output) );
    fclose(fid);
end

%--------------------------------------------------------------------------
%
%
function result = scan(r)
    if ischar(r)
        result = scan_char(r);
    elseif iscell(r)
        result = scan_cell(r);
    elseif isord(r)
        result = scan_ord(r);
    elseif isstruct(r)
        result = scan_struct(r);                
    elseif isnumeric(r)
        result = scan_numeric(r);
    elseif isa(r,'DateTime')
        result = scan_datetime(r);
    else
        error(['Cannot handle type: ' class(r)]);
    end
end

%--------------------------------------------------------------------------
%
%
function result = scan_numeric(r)
    if isempty(r)
        result = java.util.ArrayList();
    else
        result = java.lang.Double(r);
    end
end

%--------------------------------------------------------------------------
%
%
function result = scan_char(r)
    result = java.lang.String(r);
end

%--------------------------------------------------------------------------
%
%
function result = scan_datetime(r)
    % datestr 30..in ISO8601 format
    %java.text.SimpleDateFormat('yyyymmdd'T'HH:mm:ssz" );
    
    [Y, M, D, H, MN,S] = datevec(double(r));            
	result = java.util.GregorianCalendar(Y, M-1, D, H, MN,S);
	result.setTimeZone(java.util.TimeZone.getTimeZone('UTC'));
    
    %tz = java.util.TimeZone.getTimeZone('UTC');
    %cal = java.util.GregorianCalendar(tz);
    %cal.set
    %result = java.util.Date(datestr(r));
end

%--------------------------------------------------------------------------
%
%
function result = scan_cell(r)
    if(isrowvector(r))  
        result = scan_cell_row(r);
    elseif(iscolumnvector(r))
        result = scan_cell_column(r);
    elseif(ismymatrix(r))
        result = scan_cell_matrix(r);
    elseif(issingle(r));
        result = scan_cell_single(r);
    elseif(isempty(r))
        result = java.util.ArrayList();
    else
        error('Unknown cell content.');
    end;
end

%--------------------------------------------------------------------------
%
%
function result = scan_ord(r)
    if(isrowvector(r))
        result = scan_ord_row(r);
    elseif(iscolumnvector(r))
        result = scan_ord_column(r);
    elseif(ismymatrix(r))
        result = scan_ord_matrix(r);
    elseif(issingle(r))
        result = scan_ord_single(r);
    elseif(isempty(r))
        result = java.util.ArrayList();
    else
        error('Unknown ordinary array content.');
    end;
end

%--------------------------------------------------------------------------
%
%
function result = scan_cell_row(r)
    result = java.util.ArrayList();
    for ii = 1:size(r,2)
        result.add(scan(r{ii}));
    end;
end

%--------------------------------------------------------------------------
%
%
function result = scan_cell_column(r)
    result = java.util.ArrayList();
    for ii = 1:size(r,1)
        tmp = r{ii};
        if ~iscell(tmp)
            tmp = {tmp};
        end;
        result.add(scan(tmp));
    end;    
end

%--------------------------------------------------------------------------
%
%
function result = scan_cell_matrix(r)
    result = java.util.ArrayList();
    for ii = 1:size(r,1)
        i = r(ii,:);
        result.add(scan_cell_row(i));
    end;
end

%--------------------------------------------------------------------------
%
%
function result = scan_cell_single(r)
    result = java.util.ArrayList();
    result.add(scan(r{1}));
end

%--------------------------------------------------------------------------
%
%
function result = scan_ord_row(r)
    result = java.util.ArrayList();
    for i = r
        result.add(scan(i));
    end;
end

%--------------------------------------------------------------------------
%
%
function result = scan_ord_column(r)
    result = java.util.ArrayList();
    for i = 1:size(r,1)
        result.add(scan_ord_row(r(i)));
    end;
end

%--------------------------------------------------------------------------
%
%
function result = scan_ord_matrix(r)
    result = java.util.ArrayList();
    for i = r'
        result.add(scan_ord_row(i'));
    end;
end

%--------------------------------------------------------------------------
%
%
function result = scan_ord_single(r)
    result = java.util.ArrayList();
    for i = r'
        result.add(r);
    end;
end


%--------------------------------------------------------------------------
%
%
function result = scan_struct(r)
    result = java.util.LinkedHashMap();
    for i = fields(r)'
        key = i{1};
        val = r.(key);
        result.put(key,scan(val));
    end;
end











