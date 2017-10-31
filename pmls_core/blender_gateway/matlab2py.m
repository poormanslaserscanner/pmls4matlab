function D = matlab2py( S )
%MATLAB2PY Summary of this function goes here
%   Detailed explanation goes here
dummyedg = int32(zeros(0,2));
if strcmp( S.pmls_type, 'hedgehog' )
    [S.base, S.rays, S.vid, ~, S.zeroshots] = truehedgehogs( S.base, S.rays, S.vid, dummyedg, S.zeroshots, 1 );    
    D.vid = S.vid;
    erays = cell(numel(S.rays),1);
    [ D.vt, D.bindices, D.vzindices, D.edges, ~, D.ezindices ] = hedges2py(  S.base, S.rays, erays, S.zeroshots );
    D.pmls_type = 'hedgehog';
elseif strcmp( S.pmls_type, 'ehedgehog' )
    [S.base, S.rays, S.vid, ~, S.zeroshots, S.erays] = truehedgehogs( S.base, S.rays, S.vid, dummyedg, S.zeroshots, 1, S.erays );    
    D.vid = S.vid;
    [ D.vt, D.bindices, D.vzindices, D.edges, D.extindices, D.ezindices ] = hedges2py(  S.base, S.rays, S.erays, S.zeroshots );
    D.pmls_type = 'ehedgehog';
elseif strcmp( S.pmls_type, 'mesh' )
    [D.vt, D.tris] = mesh2py(S.vt, S.tris);
    D.pmls_type = 'mesh';
    if isfield(S, 'selvt')
        D.selvt = int32(S.selvt) - 1;
    end
    
elseif strcmp( S.pmls_type, 'vol_mesh' )
    [D.vt, D.elements, D.edges] = volmesh2py(S.vt, S.elem, S.edges);
    D.pmls_type = 'vol_mesh';
elseif strcmp( S.pmls_type, 'deform_mesh' )
    h = false;
    if isfield(S, 'hedgehog')
        H = matlab2py(S.hedgehog);
        h = true;
    end
    a = false;
    if isfield(S, 'anchor')
        a = true;
        A = matlab2py(S.anchor);
    end
    S.pmls_type = 'mesh';
    D = matlab2py(S);
    if h
        D.hedgehog = H;
    end
    if a
        D.anchor = A;        
    end
    D.pmls_type = 'deform_mesh';
end
D.pmls_name = S.pmls_name;
end
