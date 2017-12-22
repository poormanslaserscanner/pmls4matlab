function S = plvolumedeform( S, vox, ext, cuda, marcube, unilap, premesh )
%PLVOLUMEDEFORM Summary of this function goes here
%   Detailed explanation goes here
trisc = {S.tris};
vtc = {S.vt};
H = S.hedgehog;
if isfield(S, 'anchor')
    A = S.anchor;
else
    A = 0;
end
[ntris,nvt] = remeshunionbiharc( H.base, H.rays, trisc, vtc, vox, ext, cuda, marcube, premesh, unilap );
name = S.pmls_name;
S = struct('tris', ntris, 'vt', nvt, 'pmls_type', 'deform_mesh', 'pmls_name', [name, '_vox']);
S.hedgehog = H;
if isstruct( A )
    S.anchor = A;
end
end


