function [nrayindices, counter, edges] = visiblepoints( allpnts, rayindices, base, nrayindices, zeroshots, edges, unionindices, trisc, vtc )
n = size( base,1 );
if nargin < 7
    unionindices = 1 : n;
end 
rays = indices2rays( allpnts, rayindices(unionindices) );
if nargin < 8
    [trisc, vtc ] = hedgehogs( base(unionindices,:), rays, zeroshots(unionindices,:) );
end
[v, bb0, grs] = binunion( trisc, vtc );
vsiz = size( v );
nn = numel(unionindices);
%allpnts = cell2mat( rays );
counter = zeros(n,1);
for ii = 1 : nn
    i = unionindices(ii);
    p0 = floor( ( base( i, : ) - bb0 ) / grs );
    for j = 1 : n
        if i == j
            continue;
        end
        extended = false;
        m = numel( rayindices{j} );
        for k = 1 : m
            pfiz = allpnts(rayindices{j}(k),:);
            p = floor( (pfiz - bb0) / grs );
            d = p-p0;
            N = max(abs(d));
            lin1 = round( linspace( p0(1), p(1), N ) );
            if any( lin1 > vsiz( 1 ) ) || any( lin1 <= 0 )
                continue
            end
            lin2 = round( linspace( p0(2), p(2), N ) ); 
            if any( lin2 > vsiz( 2 ) ) || any( lin2 <= 0 )
                continue
            end
            lin3 = round( linspace( p0(3), p(3), N ) );
            if any( lin3 > vsiz( 3 ) ) || any( lin3 <= 0 )
                continue
            end
            indices = sub2ind( vsiz, lin1, lin2, lin3 );
            if all( v( indices ) )
                actindex = rayindices{j}(k);
                if ~any( nrayindices{i} == actindex )
                    counter(i) = counter(i) + 1;
                    extended = true;
                    nrayindices{i} = [nrayindices{i},rayindices{j}(k)];
                end
            end
        end
        if extended
            edge = sort([i,j]);
            if ~any(edges(:,1) == edge(1,1) & edges(:,2) == edge(1,2) )
                edges = [edges;edge];
            end
        end
    end
end

end
