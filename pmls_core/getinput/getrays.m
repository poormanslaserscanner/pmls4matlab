function [ vid, vpnt, edg, rays, zeroshots, calibshots ] = getrays( rayfile, vid, vpnt, edg, decl )
%GETRAYS Summary of this function goes here
%   Detailed explanation goes here
fid = fopen(rayfile,'rt'); 
n = numel( vid );
rays = cell( n, 1 );
zeroshots = cell( n, 1 );
calibshots = cell( n, 1 );
dummyz = zeros(0,3);
for i = 1 : n
    rays{i} = dummyz;
    zeroshots{i} = dummyz;
    calibshots{i} = dummyz;
end
linnum = 0;
while ~feof(fid)
    lin = textscan(fid,'%s', 1,'delimiter', '\n');
    linnum = linnum + 1; 
    lin = lin{1};
    if numel( lin ) < 1
        continue;
    end
    lin = lin{1};
    tmp = textscan( lin, '%s', 'delimiter', '|');
    tmp = tmp{1};
    fromid = tmp{3};
    if numel( fromid ) == 0
        ErrStruct('fromStation missing');
    end
    r = str2double( tmp{5} );
    th = str2double( tmp{6} );
    phi = ( str2double( tmp{7} ) ) * pi / 180;
    th = ( 90 - ( th + decl ) ) * pi / 180;
    [x, y, z] = sph2cart( th, phi, r );

    fromindex = find( strcmp( fromid, vid ) );
    if numel(fromindex) > 1
        ErrStruct(['fromStation: "', fromid, '" multiple definition']);
    end
    toid = tmp{4};

    if numel( fromindex ) < 1
        if numel( toid ) <= 0
            ErrStruct(['fromStation: "', fromid, '" not defined']);
        end
        toindex = find( strcmp( toid, vid ) );
        if numel(toindex) ~= 1
            if numel(toindex) < 1
                ErrStruct(['toStation: "', toid, '" not defined']);
            else
                ErrStruct(['toStation: "', toid, '" multiple definition']);
            end
        end
        actpnt = vpnt(toindex,:) - [x,y,z];
        vid = [vid;{fromid}];
        fromindex = numel( vid );
        edg = [edg;sort([fromindex,toindex])];
        vpnt = [vpnt; actpnt];
        rays = [rays;{vpnt(toindex,:)}];
        zeroshots = [zeroshots; {dummyz}];
        calibshots = [calibshots; {dummyz}];
        continue;
    end

    actpnt = vpnt(fromindex,:) + [x,y,z];
    if numel( toid ) > 0
        toindex = find( strcmp( toid, vid ) );
        if numel( toindex ) ~= 0
            assert( numel(toindex) == 1 );
            if fromindex == toindex
                zeroshots{ fromindex } = [zeroshots{fromindex};[toindex,th,phi]];
                continue;
            end
            calibshots{ fromindex } = [calibshots{fromindex};[toindex,th,phi]];
            actedg = sort( [fromindex,toindex] );
            if ~any( edg(:,1) == actedg(1) & edg(:,2) == actedg(2) )
                edg = [edg; actedg];
            end
        else
            vid = [vid;{toid}];
            toindex = numel( vid );
            edg = [edg;sort([fromindex,toindex])];
            vpnt = [vpnt; actpnt];
            rays = [rays;{dummyz}];
            zeroshots = [zeroshots; {dummyz}];
            calibshots = [calibshots; {dummyz}];
        end
    end
    rays{ fromindex } = [rays{fromindex};actpnt];
end

function S = ErrStruct( message )
    S.message = sprintf( '%s\nFile: %s\nline: %d',  message, rayfile, linnum);
    S.stack = struct('file', cell(0,1), 'name', cell(0,1), 'line', cell(0,1) );
    error(S);
end

end

