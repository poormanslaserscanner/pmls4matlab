function [v, bb0, grs] = binunion( trisc, vtc, par, dist )
%BINUNION Summary of this function goes here
%   Detailed explanation goes here
if nargin < 3
    par = 3;
end
n = numel( trisc );
assert( n == numel( vtc ) );
bb0s = zeros(n,3);
bb1s = zeros(n,3);
for i = 1 : n
    bb0s(i,:) = [min(vtc{i}(:,1)), min(vtc{i}(:,2)),min(vtc{i}(:,3))];
    bb1s(i,:) = [max(vtc{i}(:,1)), max(vtc{i}(:,2)),max(vtc{i}(:,3))];
end
grs = par / 100.0;
bb0s = ( floor( bb0s / grs ) - 2 ) * grs;
bb1s = ( ceil(  bb1s / grs ) + 2 ) * grs;
bb0 = [min( bb0s(:,1)), min( bb0s(:,2)),min( bb0s(:,3))];
bb1 = [max( bb1s(:,1)), max( bb1s(:,2)),max( bb1s(:,3))];
xgi = bb0( 1 ) : grs  : bb1( 1 );
ygi = bb0( 2 ) : grs  : bb1( 2 );
zgi = bb0( 3 ) : grs  : bb1( 3 );
v = false( numel( xgi ), numel( ygi ), numel( zgi ) );
for i = 1 : n
    xgindex = int32( ( ( bb0s( i, 1 ) - bb0( 1 ) ) / grs + 1 ) : ( ( bb1s( i, 1 ) - bb0( 1 ) ) / grs + 1 ) );
    ygindex = int32( ( ( bb0s( i, 2 ) - bb0( 2 ) ) / grs + 1 ) : ( ( bb1s( i, 2 ) - bb0( 2 ) ) / grs + 1 ) );
    zgindex = int32( ( ( bb0s( i, 3 ) - bb0( 3 ) ) / grs + 1 ) : ( ( bb1s( i, 3 ) - bb0( 3 ) ) / grs + 1 ) );
    vi=surf2vol( vtc{i}, trisc{i}, xgi(xgindex), ygi(ygindex), zgi(zgindex) );
    vi = imfill(vi,6,'holes');
    if nargin > 3 && dist > 0
        D = bwdist(~vi);
        vi = (D > dist );
    end
    v( xgindex, ygindex, zgindex ) = v( xgindex, ygindex, zgindex ) | vi;
end


end

