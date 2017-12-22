function S = plvoxuniohdgs( H, vox, ext, cuda, marcube )
%PLVOXUNIOHDGS Summary of this function goes here
%   Detailed explanation goes here
[S.tris,S.vt] = remeshunion(H.base,H.erays,H.zeroshots, vox, ext, cuda, marcube, 0.7, {H.base, H.rays} );
S.hedgehog = H;
S.pmls_type = 'deform_mesh';
S.pmls_name = [H.pmls_name, '_union'];
end

