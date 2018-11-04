function eraysmin = minvisible( base, rays, erays, zeroshots )
%MINVISIBLE Summary of this function goes here
%   Detailed explanation goes here
n = size( base, 1 );
eraysmin = cell(n,1);
for i = 1: n
%     w = getCurrentWorker;
%     if ~isempty(w)
%         disp(class(w.ProcessId));
%     end
    eraysmin{i} = mineray( base(i,:), rays{i}, erays{i}, zeroshots{i} );
%    disp( i );
end

end

function eraymin = mineray( bpnt, ray, eray, angles )
n = size(ray,1);
base = repmat(bpnt,n,1);
ray = ray - base;
n = size(eray,1);
base = repmat(bpnt,n,1);
eray0 = eray - base;
DT = DelaunayTri( eray0 );
eray0 = DT.X;
n = size(eray0,1);
d = sqrt( dot(eray0,eray0,2) );
[sd,dIX] = sort(d,1);
eray0 = eray0(dIX,:);
logind = false(n,1);
[PI,D] = nearestNeighbor( DT, ray );
indices = PI((D < 0.005 ));
logind(indices) = true;
logind = logind(dIX);
            if numel( angles > 0 )
                 [tris,vt] = hedgehog( eray0(logind,:), [0,0,0], angles(1,2), angles(1,3)  );
            else
                [tris,vt] = hedgehog( eray0(logind,:), [0,0,0] );
            end
tree=opcodemesh(vt',tris');
offset = 0.05 * normr(eray0);
for i = 1 : n
%     if mod(i,100) == 0
%         disp( i );
%     end
    if ~logind(i) && sd(i) > 0.06
        [hit,d] = raycast(tree, offset(i,:), eray0(i,:), 1.0 );
        if hit && d > 1.0
            logind(i) = true;
            if numel( angles > 0 )
                 [tris,vt] = hedgehog( eray0(logind,:), [0,0,0], angles(1,2), angles(1,3)  );
            else
                [tris,vt] = hedgehog( eray0(logind,:), [0,0,0] );
            end
            tree.delete();
            tree=opcodemesh(vt',tris');
        end
    end
end
eraymin = eray0(logind,:);
n = size(eraymin,1);
base = repmat(bpnt,n,1);
eraymin = eraymin + base;
end

