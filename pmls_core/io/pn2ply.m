function pn2ply( fname, pnts, normals )
%POINTS2PLY Summary of this function goes here
%   Detailed explanation goes here
DATA.vertex.x = pnts(:,1);
DATA.vertex.y = pnts(:,2);
DATA.vertex.z = pnts(:,3);
DATA.vertex.nx = normals(:,1);
DATA.vertex.ny = normals(:,2);
DATA.vertex.nz = normals(:,3);
ply_write(DATA,fname);


end

