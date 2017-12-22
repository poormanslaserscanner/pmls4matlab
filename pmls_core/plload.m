function plload( path )
%PLLOAD Summary of this function goes here
%   Detailed explanation goes here
S = load(path);
if isfield(S, 'file_type') && strcmp(S.file_type, 'bpy_data')
    S = struct2cell(S);
    n = numel( S );
    for i = 1 : n
        if isstruct(S{i})
            D = S{i};
            assignin('caller', D.pmls_name, D);        
        end
    end
    return
end
if isfield(S,'vid')
    if isfield(S,'erays')
        S.pmls_type = 'ehedgehog';
    else
        S.pmls_type = 'hedgehog';
    end
    fp = path;
    if any(fp=='\')
        i = find(fp == '\');
        i = i(end);
        fp = fp(i+1:end);
    end
    if any(fp=='.')
        i = find(fp == '.');
        i = i(end);
        fp = fp(1:i-1);
    end
    S.pmls_name = [fp, '_hdg'];
    assignin('caller', S.pmls_name, S);        
end
if isfield(S, 'tris') && isfield(S, 'vt')
    S.pmls_type = 'mesh';
    fp = path;
    if any(fp=='\')
        i = find(fp == '\');
        i = i(end);
        fp = fp(i+1:end);
    end
    if any(fp=='.')
        i = find(fp == '.');
        i = i(end);
        fp = fp(1:i-1);
    end
    S.pmls_name = fp;
    assignin('caller', S.pmls_name, S);        
end
if isfield(S, 'feszpnts')
    S.pmls_type = 'mesh';
    fp = path;
    if any(fp=='\')
        i = find(fp == '\');
        i = i(end);
        fp = fp(i+1:end);
    end
    if any(fp=='.')
        i = find(fp == '.');
        i = i(end);
        fp = fp(1:i-1);
    end
    S.pmls_name = [fp, '_fp'];
    assignin('caller', S.pmls_name, S);        
    
end
end

