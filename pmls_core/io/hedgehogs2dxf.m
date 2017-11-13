function hedgehogs2dxf( base, rays, filename )
fid = dxf_open( filename );
n = numel( rays );
for i = 1 : n
    m = size( rays{i}, 1 );
    for j = 1 : m
        sgm = [base(i,:);rays{i}(j,:)];
        dxf_polyline( fid, sgm(:,1), sgm(:,2), sgm(:,3) ); 
    end
end
dxf_close(fid);
end

