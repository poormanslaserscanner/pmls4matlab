function [vid, vpnt, edg] = getpoligon( polfile )
%GETPOLIGON Summary of this function goes here
%   Detailed explanation goes here
fid = fopen(polfile,'rt'); 
vid = {'0'};
vpnt = [0,0,0];
edg = [];
decl = 4.45;
while ~feof(fid)
    lin = textscan(fid,'%s', 1,'delimiter', '\n');
    lin = lin{1};
    if numel( lin ) < 1
        continue;
    end
    lin = lin{1};
    if numel( lin ) > 12 && strcmp( lin(1:12), 'Declination:' )
        tmp = textscan( lin, 'Declination: %f' );
        decl = tmp{1};
        if( decl <= 2 || decl >= 5 )
            assert( 0 );
        end
    end
    if numel( lin ) > 5 && strcmp( lin(1:4), 'From' )
        while ~feof( fid )
            lin = textscan(fid,'%s', 1,'delimiter', '\n');
            lin = lin{1};
            lin = lin{1};
            if numel( lin ) == 0
                break;
            end
            tmp = textscan( lin, '%s', 'delimiter', '\t');
            tmp = tmp{1};
            fromid = tmp{1};
            fromindex = find( strcmp( fromid, vid ) );
            assert( numel(fromindex) == 1 );
            toid = tmp{2};
            toindex = find( strcmp( toid, vid ) );
            if numel( toindex ) ~= 0
                assert( numel(toindex) ==1 );
                actedg = sort( [fromindex,toindex] );
                if any( edg(:,1) == actedg(1) & edg(:,2) == actedg(2) )
                    assert(0);
                end
                edg = [edg; actedg];
            else
                vid = [vid;{toid}];
                toindex = numel( vid );
                edg = [edg;sort([fromindex,toindex])];
                r = str2double( tmp{3} );
                th = str2double( tmp{4} );
                phi = ( str2double( tmp{5} ) ) * pi / 180;
                th = ( 90 - ( th + decl ) ) * pi / 180;
                [x, y, z] = sph2cart( th, phi, r );
                vpnt = [vpnt; vpnt(fromindex,:) + [x, y, z]];
            end
        end
    end
end
end

