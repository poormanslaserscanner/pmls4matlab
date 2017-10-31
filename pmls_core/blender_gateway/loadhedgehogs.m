function data = loadhedgehogs( path )
%LOADHEDGEHOGS Summary of this function goes here
%   Detailed explanation goes here
S = load(path);
if isfield(S, 'file_type') && strcmp(S.file_type, 'bpy_data')
    S = struct2cell(S);
    n = numel( S );
    data = cell(n,1);
    logind = true(n,1);
    for i = 1 : n
        if ~isstruct(S{i})
            logind(i) = false;
            continue
        end
        data{i} = matlab2py( S{i} );
    end
    data = data(logind);
    return
else
    data = cell(0,1);
end
if isfield(S,'vid')
    D.vid = S.vid;
    if isfield(S,'erays')
        [ D.vt, D.bindices, D.vzindices, D.edges, D.extindices, D.ezindices ] ...
            = hedges2py(  S.base, S.rays, S.erays, S.zeroshots );
        D.pmls_type = 'ehedgehog';
    else
        erays = cell(numel(S.rays),1);
        [ D.vt, D.bindices, D.vzindices, D.edges, ~, D.ezindices ] ...
            = hedges2py(  S.base, S.rays, erays, S.zeroshots );
        D.pmls_type = 'hedgehog';
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
    D.pmls_name = [fp, '_hdg'];
    data = [data;{D}];
end
if isfield(S, 'tris') && isfield(S, 'vt')
    [ D.vt, D.tris ] = mesh2py(  S.vt, S.tris );
    D.pmls_type = 'mesh';
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
    D.pmls_name = fp;
    data = [data;{D}];
    
end
if isfield(S, 'feszpnts')
    tris = zeros(0,3);
    [ D.vt, D.tris ] = mesh2py(  S.feszpnts, tris );
    D.pmls_type = 'mesh';
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
    D.pmls_name = [fp, '_fp'];
    data = [data;{D}];
    
end
end
