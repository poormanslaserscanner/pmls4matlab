function val = castrays( orig, allpnts, tris, vt )
%CASTRAYS Summary of this function goes here
%   Detailed explanation goes here

TR = TriRep(tris,vt);
tree = opcodemesh( vt', tris' );
m = size( allpnts, 1 );
inner = false(m,1);
pc = -(allpnts - orig);
[hit,~,trix] = tree.intersect( allpnts', pc' );
nn = faceNormals(TR, double(trix(hit)));
logind = ( dot( pc(hit,:),nn,2 ) >= 0 );
indices = find(hit);
hit(indices(logind)) = false;
inner(~hit ) = true;
outer = ~inner;
pc(inner,:) = -pc(inner,:);
[hit,d] = tree.intersect( allpnts', pc' );
nn = sqrt( dot(pc,pc,2));
val = -ones(m,1);
d(hit) = d(hit) ./ nn(hit);
d(hit & outer) = -d( hit & outer );
val(hit) = d(hit) + 1.0;
end

