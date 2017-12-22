function [ntris,nvt] = remeshunionc( trisc, vtc, bpar, bdist, cuda, marcube, Hc )

[v, bb0, grs] = binunion( trisc, vtc, bpar, bdist, cuda, Hc );
if marcube
    [nvt, elem]=v2m( v, 0.5, 0.9, 10, 'cgalmesh');
    elem = elem(:,1:4);
    nvt = nvt(:,1:3);
    [elem, nvt] = filterrefvertices( elem, nvt );
    [ntris,nvt] = getsurface( elem, nvt );
    nvt = ( nvt + 0.5 ) * grs + repmat( bb0, size(nvt,1),1 );
    [nvt,ntris]=meshcheckrepair(nvt,ntris,'meshfix');
    [ntris, nvt] = filterrefvertices( ntris, nvt );
else
    [nvt,ntris]=binsurface(v);
    nvt = ( nvt + 0.5) * grs + repmat( bb0, size(nvt,1),1 );
end


end