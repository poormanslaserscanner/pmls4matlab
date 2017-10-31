function S = remeshunioncpy( Hc, vox, ext )
%REMESHUNIONPY Summary of this function goes here
%   Detailed explanation goes here
disp(mfilename());
disp('input:');
n = numel(Hc);
for i = 1 : n
    Hc{i} %#ok<NOPRT>
end
vox %#ok<NOPRT>
ext %#ok<NOPRT>end
[trisc, vtc, H, A] = py2deformmesh(Hc);
for i = 1 : n
    [vtc{i},trisc{i}]=meshcheckrepair(vtc{i},trisc{i},'meshfix');

    [trisc{i}, vtc{i}] = filterrefvertices( trisc{i}, vtc{i} );
    
end
[ntris,nvt] = remeshunionc( trisc, vtc, vox, ext );
name = '';
for i = 1 : n
    name = [name, Hc{i}.pmls_name, '_'];
end
S = struct('tris', ntris, 'vt', nvt, 'pmls_type', 'mesh', 'pmls_name', [name, '_vox']);
S.pmls_type = 'deform_mesh';
if n > 1
    S.hedgehog = H;
    if isstruct( A )
        S.anchor = A;
    end
end
if n == 1 && isstruct( A )
    S.anchor = A;
end
S = matlab2py(S);
if n == 1
    S.hedgehog = false;
    if ~isstruct( A )
        S.anchor = false;
    end
end
disp('output:');
S %#ok<NOPRT>

