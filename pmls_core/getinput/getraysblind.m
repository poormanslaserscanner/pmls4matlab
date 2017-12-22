function [ vid, edg, thphir, rays, zeroshots ] = getraysblind( rayfile, vid, edg, thphir, decl )
%GETRAYS Summary of this function goes here
%   Detailed explanation goes here
fid = fopen(rayfile,'rt'); 
n = numel( vid );
rays = cell( n, 1 );
zeroshots = cell( n, 1 );
dummyz = zeros(0,3);
for i = 1 : n
    rays{i} = dummyz;
    zeroshots{i} = dummyz;
end
linnum = 0;
if fid == -1
    ErrStruct('Cannot open file.')
end
while ~feof(fid)
    lin = textscan(fid,'%s', 1,'delimiter', '\n');
    linnum = linnum + 1; 
    if numel( lin ) < 1
        continue;
    end
    lin = lin{1};
    if numel( lin ) < 1
        continue;
    end
    lin = lin{1};
    tmp = textscan( lin, '%s', 'delimiter', '|');
    if numel( tmp ) < 1
        continue;
    end
    tmp = tmp{1};
    if numel(tmp) < 7
        ErrStruct('Not enough fields');
    end
    fromid = tmp{3};
    if numel( fromid ) == 0
        ErrStruct('fromStation missing');
    end
    r = str2double( tmp{5} );
    th = str2double( tmp{6} );
    phi = ( str2double( tmp{7} ) ) * pi / 180;
    th = ( 90 - ( th + decl ) ) * pi / 180;
    fromindex = find( strcmp( fromid, vid ) );
    if numel(fromindex) > 1
        ErrStruct(['fromStation: "', fromid, '" multiple definition']);
    end
    if numel(fromindex) < 1
        vid = [vid;{fromid}];
        rays = [rays;{dummyz}];
        zeroshots = [zeroshots; {dummyz}];
        fromindex = numel(vid);
    end
    toid = tmp{4};
    if numel( toid ) > 0
        toindex = find( strcmp( toid, vid ) );
        assert( numel(toindex) <= 1 );
        if numel(toindex) < 1
            vid = [vid;{toid}];
            rays = [rays;{dummyz}];
            zeroshots = [zeroshots; {dummyz}];
            toindex = numel(vid);
        end
        if fromindex == toindex
            zeroshots{ fromindex } = [zeroshots{fromindex};[toindex,th,phi]];
            continue;
        end
            actedg = [fromindex,toindex];
%             if fromindex > toindex
%                 phi = -phi;
%                 if th > pi
%                     th = th - pi;
%                 else
%                     th = th + pi;
%                 end
%                 actedg = [toindex,fromindex];
%             end
            edg = [edg;actedg];
            assert( -pi/2 <= phi && phi <= pi / 2 );
            if th < 0
                th = th + 2 * pi;
            elseif th > 2 * pi
                th = th - 2 * pi;
            end
            assert( 0 <= th && th <= 2*pi);
            thphir = [thphir;[th, phi, r]];
    else
        [x, y, z] = sph2cart( th, phi, r );
        actpnt = [x,y,z];
        rays{ fromindex } = [rays{fromindex};actpnt];
    end
end

function S = ErrStruct( message )
    S.message = sprintf( '%s\nFile: %s\nline: %d',  message, rayfile, linnum);
    S.stack = struct('file', cell(0,1), 'name', cell(0,1), 'line', cell(0,1) );
    error(S);
end

end

