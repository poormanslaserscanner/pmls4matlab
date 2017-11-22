function [ntris,nvt] = remeshunionc( trisc, vtc, bpar, bdist, cuda, marcube )

[v, bb0, grs] = binunion( trisc, vtc, bpar, bdist, cuda );
if marcube
    [nvt, elem]=v2m( v, 0.5, 1, 10, 'cgalmesh');
    elem = elem(:,1:4);
    nvt = nvt(:,1:3);
    [elem, nvt] = filterrefvertices( elem, nvt );
    [ntris,nvt] = getsurface( elem, nvt );
    nvt = ( nvt + 0.5 ) * grs + repmat( bb0, size(nvt,1),1 );
    [ntris, nvt] = filterrefvertices( ntris, nvt );
    [nvt,ntris]=meshcheckrepair(nvt,ntris,'meshfix');
    [nvt,ntris]=meshcheckrepair(nvt,ntris,'dup');
    [ntris, nvt] = filterrefvertices( ntris, nvt );
else
    [nvt,ntris]=binsurface(v);
    nvt = ( nvt + 0.5 ) * grs + repmat( bb0, size(nvt,1),1 );
end


end