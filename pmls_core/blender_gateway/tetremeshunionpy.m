function S = tetremeshunionpy( H, premesh, apar, qpar, dpar )
%REMESHUNIONPY Summary of this function goes here
%   Detailed explanation goes here
disp(mfilename());
disp('input:');
H %#ok<NOPRT>
premesh %#ok<NOPRT>
apar %#ok<NOPRT>
qpar %#ok<NOPRT>
dpar %#ok<NOPRT>

H = py2matlab( H );
[S.vt, S.tris] = tetremeshunion(H.base,H.erays,H.zeroshots, premesh, apar, qpar, dpar );

S.pmls_type = 'mesh';
S.pmls_name = [H.pmls_name, '_union'];
S = matlab2py(S);
disp('output')
S %#ok<NOPRT>
end

