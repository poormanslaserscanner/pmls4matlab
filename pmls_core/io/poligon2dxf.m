function poligon2dxf( base, edges, filename )
fid = dxf_open( filename );
n = size( edges, 1 );
for i = 1 : n
    sgm = [base(edges(i,1),:);base(edges(i,2),:)];
    dxf_polyline( fid, sgm(:,1), sgm(:,2), sgm(:,3) ); 
end
dxf_close(fid);
end

