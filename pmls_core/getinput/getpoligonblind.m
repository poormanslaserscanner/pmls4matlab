function [vid, edg, thphir] = getpoligonblind( polfile )
%GETPOLIGON Summary of this function goes here
%   Detailed explanation goes here
fid = fopen(polfile,'rt'); 
vid = {'0'};
edg = zeros(0,2);
decl = 4.45;
thphir = zeros(0,3);
linnum = 0;
if fid == -1
    ErrStruct('Cannot open file.');
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
    if numel( lin ) > 12 && strcmp( lin(1:12), 'Declination:' )
        tmp = textscan( lin, 'Declination: %f' );
        if numel(tmp) < 1
            ErrStruct('Declination missing');
        end
        decl = tmp{1};
    end
    if numel( lin ) > 5 && strcmp( lin(1:4), 'From' )
        while ~feof( fid )
            lin = textscan(fid,'%s', 1,'delimiter', '\n');
            if numel( lin ) == 0
                break;
            end
            lin = lin{1};
            if numel( lin ) == 0
                break;
            end
            lin = lin{1};
            if numel( lin ) == 0
                break;
            end
            tmp = textscan( lin, '%s', 'delimiter', '\t');
            if numel( tmp ) == 0
                break;
            end
            tmp = tmp{1};
            if numel( tmp ) < 5
                ErrStruct('Not enough fields');
            end
            fromid = tmp{1};
            fromindex = find( strcmp( fromid, vid ) );
            assert( numel(fromindex) <= 1 );
            if numel(fromindex) < 1
                vid = [vid;{fromid}];
                fromindex = numel(vid);
            end
            toid = tmp{2};
            toindex = find( strcmp( toid, vid ) );
            assert( numel(toindex) <= 1 );
            if numel(toindex) < 1
                vid = [vid;{toid}];
                toindex = numel(vid);
            end
            actedg = [fromindex,toindex];
            r = str2double( tmp{3} );
            th = str2double( tmp{4} );
            phi = ( str2double( tmp{5} ) ) * pi / 180;
            th = ( 90 - ( th + decl ) ) * pi / 180;
%             if fromindex > toindex
%                 phi = -phi;
%                 if th > pi
%                     th = th - pi;
%                 else
%                     th = th + pi;
%                 end
%                 actedg = actedg(1,[2,1]);
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
        end
    end
end

function S = ErrStruct( message )
    S.message = sprintf( '%s\nFile: %s\nline: %d',  message, polfile, linnum);
    S.stack = struct('file', cell(0,1), 'name', cell(0,1), 'line', cell(0,1) );
    error(S);
end


end

