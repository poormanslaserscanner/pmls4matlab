function plexport(fname, H)
%PLEXPORT Summary of this function goes here
%   Detailed explanation goes here
if isfield(H,'tris') && isfield(H,'vt')
    writePLY([fname,'.ply'], H.vt, H.tris);
end
if isfield(H,'hedgehog')
    H = H.hedgehog;
end
if isfield(H,'rays') && isfield(H,'base')
    hedgehogs2dxf(H.base,H.rays,[fname,'.dxf']);
end
