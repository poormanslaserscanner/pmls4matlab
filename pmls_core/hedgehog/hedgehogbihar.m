function [K, v, rays] = hedgehogbihar( pnts, orig, th, ph )
%HEDGEHOG Summary of this function goes here
%   Detailed explanation goes here
assert( size(orig,1) == 1 );
siz = size( pnts, 1 );
porigs = repmat( orig, siz, 1 );
cpnts = pnts - porigs;
lens = sqrt( dot( cpnts, cpnts, 2 ) );
cpnts = cpnts( lens >= 0.1, : );
x0 = 0;
y0 = 0;
z0 = 0;
if nargin > 2
    [x0,y0,z0] = sph2cart( th, ph, 1.0 );
end
XYZ = [[x0,y0,z0]; normr( cpnts )];
cpntse = [[0,0,0]; cpnts ];
VBih = subdivided_sphere(4);
n = size(XYZ,1);
allvt = [XYZ;VBih];
try
    K = convhull( allvt );
catch err
%    warning( err.message );
    K = zeros(0,3);
    v = zeros(0,3);
    return;
end
nlen = sqrt(dot(cpntse,cpntse,2));
alllen = deformunilap(K,allvt,(1:n)',[nlen,nlen,nlen], 2 );
%alllen = laplacian_smooth(allvt,K,'uniform',zeros(0,1), 0.7, 'implicit', alllen(:,1), 1);
alllen = alllen(:,1);
alllen(alllen < 0.05) = 0.05;
cpntse = allvt .* [alllen,alllen,alllen];
[K,cpntse] = filterrefvertices( K, cpntse );


%siz = size( cpntse, 1 );
%porigs = repmat( orig, siz, 1 );
%v = cpntse + porigs;
%displaymeshes({K},{v},[]);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% [~, np] = udistpntmesh( [0,0,0], K, cpntse );
% if norm( np ) > 0.02
%     cpntse = [np; cpnts ];
%     XYZ = normr( cpntse );
%     K = convhull( XYZ );
%     [K,cpntse] = filterrefvertices( K, cpntse );
%     cpntse(1,:) = [0,0,0];
% end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
siz = size( cpntse, 1 );
porigs = repmat( orig, siz, 1 );
v = cpntse + porigs;

end

