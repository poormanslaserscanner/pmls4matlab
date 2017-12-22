function S = plcgalunionhdgs( H, premesh, apar, qpar, dpar )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
[S.vt, S.tris] = tetremeshunion(H.base,H.erays,H.zeroshots, premesh, apar, qpar, dpar );
S.hedgehog = H;
S.pmls_type = 'deform_mesh';
S.pmls_name = [H.pmls_name, '_union'];
end

