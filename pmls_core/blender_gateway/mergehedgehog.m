function [vid, base, rays, erays, zeroshots] = mergehedgehog( vid, base, rays, erays, zeroshots, ovid, obase, orays, oerays, ozeroshots )
n = numel( ovid );
for i = 1 : n
    index = find( strcmp(ovid{i}, vid) );
    if isempty( index )
        next = numel(vid) + 1;
        vid{next,1} = ovid{i};
        base(next, :) = obase(i,:);
        rays{next,1} = orays{i};
        erays{next,1} = oerays{i};
        zeroshots{next,1} = ozeroshots{i};
    else
        siz = size( orays{i}, 1 );
        rays{ index } = [ rays{index}; ( orays{i} - repmat( obase(i,:), siz, 1) + repmat( base(index,:), siz, 1 ) ) ];
        siz = size( oerays{i}, 1 );
        erays{ index } = [ erays{index}; ( oerays{i} - repmat( obase(i,:), siz, 1) + repmat( base(index,:), siz, 1 ) ) ];
        if isempty(zeroshots{index})
            zeroshots{index} = ozeroshots{i};
        end
    end
end
end
