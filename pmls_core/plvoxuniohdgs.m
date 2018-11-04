function S = plvoxuniohdgs( H, vox, ext, cuda, marcube, shorten )
%PLVOXUNIOHDGS Summary of this function goes here
%   Detailed explanation goes here
if nargin < 6
    shorten = 0.7;
end
[S.tris,S.vt] = remeshunion(H.base,H.erays,H.zeroshots, vox, ext, cuda, marcube, shorten, {H.base, H.rays} );
%[S.tris,S.vt] = remeshunion(H.base,H.erays,H.zeroshots, vox, ext, cuda, marcube, shorten, {} );
S.hedgehog = H;
S.pmls_type = 'deform_mesh';
S.pmls_name = [H.pmls_name, '_union'];
end

