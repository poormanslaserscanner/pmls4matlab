function [ vt, bindices, vzindices, edges, extindices, ezindices, DT ] = hedges2py(  base, rays, erays, zeroshots )
%LOADHEDGEHOGS Summary of this function goes here
%   Detailed explanation goes here
n = numel( rays );
bth = false;
for i = 1 : n
    if isempty(erays{i})
        erays{i} = zeros(0,3);
    end
    if size(erays{i},1) < size(rays{i},1)
        bth = true;
    end
end
if bth
    vt = [base; cell2mat(rays); cell2mat(erays)];
else
    vt = [base; cell2mat(erays)];
end
DT = delaunayTriangulation(vt);
vt = DT.Points;
bindices = int32(nearestNeighbor(DT, base));
assert( numel( bindices ) == unique( numel( bindices ) ) );
edges = int32(zeros(0,2));
extedges = edges;
n = numel( rays );
ze=zeros(0,2);
for i = 1 : n
    ray = rays{i};
    rindices = int32(unique( nearestNeighbor(DT, ray) ));
    rindices = rindices( rindices ~= bindices(i) );
    nedges = int32(zeros( numel( rindices ), 2 ));
    nedges(:,1) = bindices(i);
    nedges(:,2) = rindices;
    edges = [edges;nedges];
    eray = erays{i};
    if ~isempty(eray)
        erindices = int32(unique( nearestNeighbor(DT, eray) ));
        erindices = setdiff( erindices, rindices );

        erindices = erindices( erindices ~= bindices(i) );
        
        nedges = int32(zeros( numel( erindices ), 2 ));
        nedges(:,1) = bindices(i);
        nedges(:,2) = erindices;
        extedges = [extedges;nedges];
    end
end
e2 = edges(:,2);
[e2,I] = sort(e2);
log = ~logical(e2 - [0;e2(1:end-1)]);
%n = size( edges, 1 );
n = size( vt, 1 );
m = nnz(log);
vt = [vt; vt(e2(log),:)];
e2(log) = (n+1:n+m)';
edges = [edges(I,1),e2];
n = numel(rays);
nvt = size(vt,1);
for i = 1 : n
    zeroshot = zeroshots{i};
    if ~isempty(zeroshot)
        [x,y,z] = sph2cart(zeroshot(1,2), zeroshot(1,3), 1);
        vt = [vt; [x,y,z] + vt(bindices(i),:)];
        ze = [ze;[bindices(i),size(vt,1)]];
    end
end
n = size( edges, 1 );
m = size( extedges, 1 );
edges = [edges;extedges];
extindices = int32((n+1:n+m)');
vzindices = int32((nvt+1:size(vt,1))');
edges = [edges;ze];
ezindices = int32((n+m+1:n+m+size(ze,1))');
if any( edges(:,1) == edges(:,2) )
    aaa = nnz(edges(:,1) == edges(:,2));
end
bindices = bindices - 1;
edges = edges - 1;
if numel( extindices ) > 0
    extindices = extindices - 1;
end
if numel( vzindices ) > 0
    vzindices = vzindices - 1;
end
if numel( ezindices ) > 0
    ezindices = ezindices - 1;
end

end

