function S = remeshunionpy( H, vox, ext, cuda, marcube )
%REMESHUNIONPY Summary of this function goes here
%   Detailed explanation goes here
disp(mfilename());
disp('input:');
H %#ok<NOPRT>
vox %#ok<NOPRT>
ext %#ok<NOPRT>

H = py2matlab( H );
[S.tris,S.vt] = remeshunion(H.base,H.erays,H.zeroshots, vox, ext, cuda, marcube );

S.pmls_type = 'mesh';
S.pmls_name = [H.pmls_name, '_union'];
S = matlab2py(S);
disp('output')
S %#ok<NOPRT>
end

