function segments2dxf( pnts1, pnts2, filename )
fid = dxf_open( filename );
n = size( pnts1, 1 );
for i = 1 : n
    sgm = [pnts1(i,:);pnts2(i,:)];
    dxf_polyline( fid, sgm(:,1), sgm(:,2), sgm(:,3) ); 
end
dxf_close(fid);
end

