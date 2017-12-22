function [ vid, vpnt, edg, rays, zeroshots, calibshots ] = getinputmain( csvfile, poligonfile )
%GETINPUTMAIN Summary of this function goes here
%   Detailed explanation goes here
maindir = '';
fp = csvfile;
if any(fp=='\')
    i = find(fp == '\');
    i = i(end);
    maindir = fp(1:i);
end
vid = {'0'};
vpnt = [0,0,0];
edg = zeros(0,2);
if nargin > 1
    [vid, vpnt, edg] = getpoligon( poligonfile );
end
n = numel(vid);
rays = cell(n,1);
for i = 1 : n
    rays{i} = zeros(0,3);
end
zeroshots = rays;
rays = extendrays(vpnt,edg,rays);
erays = rays;

fid = fopen(csvfile,'rt'); 
textscan(fid,'%s', 1,'delimiter', '\n');
while ~feof(fid)
    lin = textscan(fid,'%s', 1,'delimiter', '\n');
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
    csvfile = [maindir, tmp{1}, '.csv'];
    if numel(tmp) < 6
        decl = 0.0;
    else
        decl = str2double(tmp{6});
    end
    [ ovid, ovpnt, edg, orays, ozeroshots] = getrays( csvfile, vid, vpnt, edg, decl );
    oerays = cell(numel(orays),1);
    n = numel(oerays);
    for i = 1 : n
        oerays{i} = zeros(0,3);
    end
    [vid, vpnt, rays, erays, zeroshots] =...
        mergehedgehog( ovid, ovpnt, orays, oerays, ozeroshots, vid, vpnt, rays, erays, zeroshots );
end
edg = int32(edg);
fclose(fid);

end

