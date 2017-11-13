function points2ply( pnts, fname )
%POINTS2PLY Summary of this function goes here
%   Detailed explanation goes here
DATA.vertex.x = pnts(:,1);
DATA.vertex.y = pnts(:,2);
DATA.vertex.z = pnts(:,3);
ply_write(DATA,fname);


end

