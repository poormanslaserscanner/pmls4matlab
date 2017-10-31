function D = py2matlab( S )
%PY2MATLAB Summary of this function goes here
%   Detailed explanation goes here
if strcmp( S.pmls_type, 'hedgehog' )
    D.vid = S.vid;
    [D.base, D.rays, D.zeroshots] = py2hedges( S.verts, S.base_i, S.rays_i, S.zeroshots_i );    
    D.pmls_type = 'hedgehog';
elseif strcmp( S.pmls_type, 'ehedgehog' )
    D.vid = S.vid;
    [D.base, D.rays, D.zeroshots, D.erays] = py2hedges( S.verts, S.base_i, S.rays_i, S.zeroshots_i, S.erays_i );    
    D.pmls_type = 'ehedgehog';
elseif strcmp( S.pmls_type, 'mesh' )
    D.vt = (S.verts)';
    D.tris = double((S.tris)' + 1);
    D.pmls_type = 'mesh';
elseif strcmp( S.pmls_type, 'deform_mesh' )
    h = false;
    if isfield(S, 'hedgehog')
        H = py2matlab(S.hedgehog);
        h = true;
    end
    a = false;
    if isfield(S, 'anchor')
        a = true;
        A = py2matlab(S.anchor);
    end
    S.pmls_type = 'mesh';
    D = py2matlab(S);
%    D.vt = round(D.vt,3);
%    [D.tris, D.vt] = filterrefvertices(D.tris, D.vt);
%    [D.vt,D.tris]=meshcheckrepair(D.vt,D.tris,'meshfix');
    
    if h
        D.hedgehog = H;
    end
    if a
        D.anchor = A;        
    end
    if isfield(S, 'anchor_i')
        D.anchorvt = D.vt(S.anchor_i, :);
    end
    D.pmls_type = 'deform_mesh';
end
D.pmls_name = S.pmls_name;



end

