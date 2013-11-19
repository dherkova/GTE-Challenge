%==========================================================================
% Reads YAML file, converts YAML sequences to MATLAB cell columns and YAML
% mappings to MATLAB structs
%
%  filename ... name of yaml file to be imported
%  verbose  ... verbosity level (0 or absent = no messages, 
%                                          1 = notify imports)
%==========================================================================
function result = ReadYamlRaw(filename, verbose, nosuchfileaction)
    if ~exist('verbose','var')
        verbose = 0;
    end;
    
    [pth,~,~] = fileparts(mfilename('fullpath'));       
    javaaddpath([pth filesep 'external' filesep 'snakeyaml-1.9.jar']); % javaaddpath clears global variables...!?
    
    setverblevel(verbose);
    % import('org.yaml.snakeyaml.Yaml'); % import here does not affect import in load_yaml ...!?
    result = load_yaml(filename, nosuchfileaction);
end

%--------------------------------------------------------------------------
% Actually performs YAML load. 
%  - If this is a first call during recursion it changes cwd to the path of
%  given filename and stores the old path. Then it calls the YAML parser
%  and runs the recursive transformation. After transformation or when an
%  error occurs, it sets cwd back to the stored value.
%  - Otherwise just calls the parser and runs the transformation.
%
function result = load_yaml(inputfilename, nosuchfileaction)

    global nsfe;

    if isempty(nsfe)
        nsfe = nosuchfileaction;
    end;


    yaml = org.yaml.snakeyaml.Yaml(); % It appears that Java objects cannot be persistent...!?
    
    [filepath, filename, fileext] = fileparts(inputfilename);
    if isempty(filepath)
        pathstore = cd();
    else
        pathstore = cd(filepath);
    end;
    try
        result = scan(yaml.load(fileread([filename, fileext])));
    catch ex
        cd(pathstore);
        switch ex.identifier
            case 'MATLAB:fileread:cannotOpenFile'
                if nsfe
                    error('MATLAB:MATYAML:FileNotFound', ['No such file to read: ',filename]);
                else
                    warning('MATLAB:MATYAML:FileNotFound', ['No such file to read: ',filename]);
                    result = struct();
                    return;
                end;
        end;
        rethrow(ex);
    end;
    cd(pathstore);    
end

%--------------------------------------------------------------------------
% Determine node type and call appropriate conversion routine. 
%
function result = scan(r)
    if isa(r, 'char')
        result = scan_string(r);
    elseif isa(r, 'double')
        result = scan_numeric(r);
    elseif isa(r, 'java.util.Date')
        result = scan_datetime(r);
    elseif isa(r, 'java.util.List')
        result = scan_list(r);
    elseif isa(r, 'java.util.Map')
        result = scan_map(r);
    else
        error(['Unknown data type: ' class(r)]);
    end;
end

%--------------------------------------------------------------------------
% Transforms Java String to MATLAB char
%
function result = scan_string(r)
    result = char(r);
end

%--------------------------------------------------------------------------
% Transforms Java double to MATLAB double
%
function result = scan_numeric(r)
    result = double(r);
end

%--------------------------------------------------------------------------
% Transforms Java Date class to MATLAB DateTime class
%
function result = scan_datetime(r)
    result = DateTime(r);
end

%--------------------------------------------------------------------------
% Transforms Java List to MATLAB cell column running scan(...) recursively
% for all ListS items.
%
function result = scan_list(r)
    result = cell(r.size(),1);
    it = r.iterator();
    ii = 1;
    while it.hasNext()
        i = it.next();
        result{ii} = scan(i);
        ii = ii + 1;
    end;
end

%--------------------------------------------------------------------------
% Transforms Java Map to MATLAB struct running scan(...) recursively for
% content of every Map field.
% When there is field, which is recognized to be the >import keyword<, an
% attempt is made to import file given by the field content.
%
% The result of import is so far stored as a content of the item named 'import'.
%
function result = scan_map(r)
    it = r.keySet().iterator();
    while it.hasNext()
        next = it.next();
        i = next;
        ich = char(i);
        if iskw_import(ich)
            result.(ich) = perform_import(r.get(java.lang.String(ich)));
        else
            result.(ich) = scan(r.get(java.lang.String(ich)));
        end;
    end;
end

%--------------------------------------------------------------------------
% Determines whether r contains a keyword denoting import.
%
function result = iskw_import(r)
    result = isequal(r, 'import');
end

%--------------------------------------------------------------------------
% Transforms input hierarchy the usual way. If the result is char, then
% tries to load file denoted by this char. If the result is cell then tries
% to do just mentioned for each cellS item. 
% 
function result = perform_import(r)
    r = scan(r);
    if iscell(r) && all(cellfun(@ischar, r))
        result = cellfun(@load_yaml, r, 'UniformOutput', 0);
    elseif ischar(r)
        result = {load_yaml(r)};
    else
        disp(r);
        error(['Importer does not unterstand given filename. '...
               'Invalid node displayed above.']);
    end;
end

%--------------------------------------------------------------------------
% Sets verbosity level for all load_yaml infos.
%
function setverblevel(level)
    global verbose_readyaml;
    verbose_readyaml = 0;
    if exist('level','var')
        verbose_readyaml = level;
    end;
end

%--------------------------------------------------------------------------
% Returns current verbosity level.
%
function result = getverblevel()
    global verbose_readyaml; 
    result = verbose_readyaml;
end

%--------------------------------------------------------------------------
% For debugging purposes. Displays a message as level is more than or equal
% the current verbosity level.
%
function info(level, text, value_to_display)
    if getverblevel() >= level
        fprintf(text);
        if exist('value_to_display','var')
            disp(value_to_display);
        else
            fprintf('\n');
        end;
    end;
end
%==========================================================================

