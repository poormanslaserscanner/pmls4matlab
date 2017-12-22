function [v, bb0, grs] = binunion( trisc, vtc, par, dist, with_cuda, Hc )
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
%vbound = v;
actbb = zeros(3,2);
% if numel(Hc) == 2
%     n = 0;
% end
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
     vin = imfill(vi,6,'holes');
%     vin = imfill(vi,18,'holes');
%     vin = imfill(vi,26,'holes');
     if numel(Hc) == 2
         vin(vi) = false;
     end
     if nargin > 3
         if dist > 0.01
             D = bwdist(~vin);
             vin = (D > dist );
         elseif dist < -0.01
             D = bwdist(vin);
             vin = (D > -dist );
         end
     end
%     se = ones(2,2,2);
%     vi = imopen(vi,se);
     v( xgindex, ygindex, zgindex ) = v( xgindex, ygindex, zgindex ) | vin;
%     vbound( xgindex, ygindex, zgindex ) = vbound( xgindex, ygindex, zgindex ) | vi;
%    v = vi;
end
if numel(Hc) == 2
    base = Hc{1};
    rays = Hc{2};
    n = numel(rays);
    base = base / grs - repmat(bb0,n,1);
    for i = 1 : n
        rays{i} = rays{i} / grs - repmat(bb0, size(rays{i},1), 1);
        m = size(rays{i},1);
        P0 = repmat(base(i,:), m, 1);
        d = rays{i} - P0; 
        Ni = floor(max(abs(d),[],2));
        Ni(Ni<1) = 1;
        d = d ./ repmat(Ni,1,3);
        Ni = Ni - 2;
        Ni(Ni < 0) = 0;
        N = max(Ni);
        for j = 0 : N
            log = j <= Ni;
            nd = d(log,:);
            kn = 8;
            for kk = 0 : kn-1
                subx = floor(P0(log,:) + (j + kk / kn) * nd - 0.5) + 1;

                v(sub2ind(size(v), subx(:,1), subx(:,2), subx(:,3))) = true;
                v(sub2ind(size(v), subx(:,1) + 1, subx(:,2), subx(:,3))) = true;
                v(sub2ind(size(v), subx(:,1), subx(:,2) + 1, subx(:,3))) = true;
                v(sub2ind(size(v), subx(:,1), subx(:,2), subx(:,3) + 1)) = true;
                v(sub2ind(size(v), subx(:,1) - 1, subx(:,2), subx(:,3))) = true;
                v(sub2ind(size(v), subx(:,1), subx(:,2) - 1, subx(:,3))) = true;
                v(sub2ind(size(v), subx(:,1), subx(:,2), subx(:,3) - 1)) = true;
            end
        end
    end
end
if numel(Hc) == 2
    v = imopen( v, strel('cube',2) );
end
%vbound(v) = false;
%v = v | vbound;
%v = imopen( v | (vbound & imdilate( ~(vbound|v), strel('cube',3) ) ), strel('cube',2));
if ~with_cuda
    bb0 = bb0 + 0.5;
end
bb0 = bb0 * grs;


end

