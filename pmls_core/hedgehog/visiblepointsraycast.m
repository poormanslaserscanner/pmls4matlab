function [nrayindices, counter, edges] = visiblepointsraycast( allpnts, rayindices, base, nrayindices, zeroshots, edges, hedgeindex )
n = size( allpnts,1 );
base = repmat( base(hedgeindex,:), n, 1 );
allpnts = allpnts - base;
rays = indices2rays( allpnts, rayindices(hedgeindex) );
[trisc, vtc ] = hedgehogs( [0,0,0], rays, zeroshots( hedgeindex,: ) );
tree=opcodemesh((vtc{1})',(trisc{1})');

%allpnts = cell2mat( rays );
n = numel(rayindices);
counter = zeros(n,1);
i = hedgeindex;
for j = 1 : n
    if i == j
        continue;
    end
    actray = allpnts(rayindices{j},:);
    offset = 0.05 * normr(actray);
    d = sqrt( dot(actray,actray,2) );
    indices = find( d > 0.06 );
    [hit,d] = raycast(tree, offset(indices,:), actray(indices,:), 1.0 );
    if numel( indices ) > 0
        indices = rayindices{j}( indices( hit & d > 1.0 ) );
        logind = ~ismember( indices, nrayindices{i} );
        if any(logind)
            counter(i) = counter(i) + nnz(logind);
            nrayindices{i} = [nrayindices{i},indices(logind)];             
            edge = sort([i,j]);
            if ~any(edges(:,1) == edge(1,1) & edges(:,2) == edge(1,2) )
                edges = [edges;edge];
            end

        end
    end
end
tree.delete();
end

