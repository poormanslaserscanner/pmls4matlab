function [v, bb0, grs] = binunion( trisc, vtc, par, dist, with_cuda )
%BINUNION Summary of this function goes here
%   Detailed explanation goes here
if nargin < 3
    par = 3;
end
if nargin < 5
    with_cuda = false;
end
if with_cuda
    if gpuDeviceCount > 0
        dev = gpuDevice;
        fprintf( 'Voxelize on cuda device: %s\n', dev.Name );
    else
        warning( 'Cuda device not found. Voxelize on CPU.' );
        with_cuda = false;
    end
end
n = numel( trisc );
assert( n == numel( vtc ) );
bb0s = zeros(n,3);
bb1s = zeros(n,3);
grs = par / 100.0;
for i = 1 : n
    vtc{i} = vtc{i} / grs;
    bb0s(i,:) = [min(vtc{i}(:,1)), min(vtc{i}(:,2)),min(vtc{i}(:,3))];
    bb1s(i,:) = [max(vtc{i}(:,1)), max(vtc{i}(:,2)),max(vtc{i}(:,3))];
end
%grs = 1.0;
bb0s = floor( bb0s ) - 2;
bb1s = ceil(  bb1s ) + 2;
bb0 = [min( bb0s(:,1)), min( bb0s(:,2)),min( bb0s(:,3))] - 10;
bb1 = [max( bb1s(:,1)), max( bb1s(:,2)),max( bb1s(:,3))] + 10;
%v = false(int32((bb1 - bb0) / grs + 1));
xgi = bb0( 1 ) : bb1( 1 );
ygi = bb0( 2 ) : bb1( 2 );
zgi = bb0( 3 ) : bb1( 3 );
v = false( numel( xgi ), numel( ygi ), numel( zgi ) );
actbb = zeros(3,2);
for i = 1 : n
    fprintf('Voxelizing mesh %d of %d\n', i, n);
    if with_cuda
        actbb(1,1) = xgi(int32( ( ( bb0s( i, 1 ) - bb0( 1 ) ) + 1 )));
        actbb(2,1) = ygi(int32( ( ( bb0s( i, 2 ) - bb0( 2 ) ) + 1 )));
        actbb(3,1) = zgi(int32( ( ( bb0s( i, 3 ) - bb0( 3 ) ) + 1 )));
        actbb(1,2) = xgi(int32( ( ( bb1s( i, 1 ) - bb0( 1 ) ) + 1 )));
        actbb(2,2) = ygi(int32( ( ( bb1s( i, 2 ) - bb0( 2 ) ) + 1 )));
        actbb(3,2) = zgi(int32( ( ( bb1s( i, 3 ) - bb0( 3 ) ) + 1 )));
        [vi,translate] = cudavox(vtc{i}, trisc{i}, actbb);
        from = (translate - bb0) + 1;
        from = int32(round(from));
        to = from + int32(size(vi)) - 1;
        to = int32(round(to));
        xgindex = int32( from(1) : to(1) );
        ygindex = int32( from(2) : to(2) );
        zgindex = int32( from(3) : to(3) );        
    else
        xgindex = int32( ( ( bb0s( i, 1 ) - bb0( 1 ) ) + 1 ) : ( ( bb1s( i, 1 ) - bb0( 1 ) ) + 1 ) );
        ygindex = int32( ( ( bb0s( i, 2 ) - bb0( 2 ) ) + 1 ) : ( ( bb1s( i, 2 ) - bb0( 2 ) ) + 1 ) );
        zgindex = int32( ( ( bb0s( i, 3 ) - bb0( 3 ) ) + 1 ) : ( ( bb1s( i, 3 ) - bb0( 3 ) ) + 1 ) );
        vi=surf2vol( vtc{i}, trisc{i}, xgi(xgindex), ygi(ygindex), zgi(zgindex) );
    end
    vi = imfill(vi,6,'holes');
    if nargin > 3
        if dist > 0.01
            D = bwdist(~vi);
            vi = (D > dist );
        elseif dist < -0.01
            D = bwdist(vi);
            vi = (D > -dist );
        end
    end
    se = ones(2,2,2);
    vi = imopen(vi,se);
    v( xgindex, ygindex, zgindex ) = v( xgindex, ygindex, zgindex ) | vi;
%    v = vi;
end
if ~with_cuda
    bb0 = bb0 + 0.5;
end
bb0 = bb0 * grs;


end

