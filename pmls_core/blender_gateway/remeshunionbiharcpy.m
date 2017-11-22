function S = remeshunionbiharcpy( Hc, vox, ext, cuda, marcube, unilap, premesh )
%REMESHUNIONPY Summary of this function goes here
%   Detailed explanation goes here
disp(mfilename());
disp('input:');
n = numel(Hc);
for i = 1 : n
    Hc{i} %#ok<NOPRT>
end
vox %#ok<NOPRT>
ext %#ok<NOPRT>
unilap %#ok<NOPRT>
premesh %#ok<NOPRT>
[trisc, vtc, H, A] = py2deformmesh(Hc);

[ntris,nvt] = remeshunionbiharc( H.base, H.rays, trisc, vtc, vox, ext, cuda, marcube, premesh, unilap );
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

% S = matlab2py(S);
% if n == 1
%     S.hedgehog = false;
%     if isstruct( A )
%         S.anchor = A;
%     else
%         S.anchor = false;
%     end
% end
disp('output:');
S %#ok<NOPRT>

end
