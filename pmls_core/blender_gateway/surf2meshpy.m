function V = surf2meshpy( S )
%BIHARPNTSPY Summary of this function goes here
%   Detailed explanation goes here
disp(mfilename());
disp('input:');
S %#ok<NOPRT>
S = py2matlab(S);
[vt,elem]=surf2meshy( S.vt, S.tris, min(S.vt) - 0.2, max(S.vt) + 0.2, 1.0,1.0);
[elem,vt] = filterrefvertices( elem, vt );
T = triangulation(elem, vt);
edges = T.edges();
V = matlab2py( struct('vt', vt,...
                    'elem', elem, ...
                   'edges', edges, ...
               'pmls_type', 'vol_mesh', 'pmls_name', [S.pmls_name, '_vol']) );
disp('output:')
V %#ok<NOPRT>
end
