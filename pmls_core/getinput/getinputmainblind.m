function [ vid, vpnt, edg, rays, zeroshots ] = getinputmainblind( csvfile, poligonfile )
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
%vpnt = [0,0,0];
edg = zeros(0,2);
thphir = zeros(0,3);
if nargin > 1
    [vid, edg, thphir] = getpoligonblind( poligonfile );
end
n = numel(vid);
rays = cell(n,1);
for i = 1 : n
    rays{i} = zeros(0,3);
end
zeroshots = rays;
%rays = extendrays(vpnt,edg,rays);
erays = rays;
extendindices = (1:n)';
fid = fopen(csvfile,'rt'); 
linnum = 0;
if fid == -1
    ErrStruct('Cannot open file');
end
textscan(fid,'%s', 1,'delimiter', '\n');
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
    if numel( tmp ) < 1
        continue;
    end
    csvfile = [maindir, tmp{1}, '.csv'];
    if numel(tmp) < 6
        decl = 0.0;
    else
        decl = str2double(tmp{6});
    end
    [ ovid, edg, thphir, orays, ozeroshots] = getraysblind( csvfile, vid, edg, thphir, decl );
    oerays = cell(numel(orays),1);
    n = numel(oerays);
    for i = 1 : n
        oerays{i} = zeros(0,3);
    end
    [vid, ~, rays, erays, zeroshots] =...
        mergehedgehog( ovid, zeros(numel(ovid),3), orays, oerays, ozeroshots, vid, zeros(numel(vid),3), rays, erays, zeroshots );
end
edg = int32(edg);
fclose(fid);
[vpnt,Err] = calcpolygon(edg, thphir);
[Err,indi] = sort(Err,'descend');
fromStation = vid(edg(indi,1));
toStation = vid(edg(indi,2));
shotId = indi;
T = table(shotId, Err, fromStation, toStation);
disp(T);
n = numel(rays);
logind = false(n,1);
logind(extendindices) = true;
for i = 1 : n
    m = size(rays{i},1);
    rays{i} = rays{i} + repmat(vpnt(i,:),m,1);
    if ~isempty(zeroshots{i})
        logind(i) = true;
    end
end
rays = extendrays(vpnt,edg,rays,logind);
function S = ErrStruct( message )
    S.message = sprintf( '%s\nFile: %s\nline: %d',  message, csvfile, linnum);
    S.stack = struct('file', cell(0,1), 'name', cell(0,1), 'line', cell(0,1) );
    error(S);
end
end

function [base, Err] = calcpolygon(edg, thphir)
indices = find(edg(:,1) > edg(:,2));
thphir(indices,2) = -thphir(indices,2);
logind = thphir(indices,1) > pi; 
thphir(indices(logind),1) = thphir(indices(logind),1) - pi;
thphir(indices(~logind),1) = thphir(indices(~logind),1) + pi;
edg(indices,:) = edg(indices,[2,1]);
assert( all(-pi/2 <= thphir(:,2)) && all(thphir(:,2) <= pi / 2) );
logind = thphir(indices,1) < 0; 
thphir(indices(logind),1) = thphir(indices(logind),1) + 2 * pi;
logind = thphir(indices,1) > 2 * pi; 
thphir(indices(logind),1) = thphir(indices(logind),1) - 2 * pi;
assert( all(0 <= thphir(:,1)) && all(thphir(:,1) <= 2 * pi) );

uedg = unique(edg, 'rows') - 1;
Err = zeros(size(edg,1),1);
n = size(uedg,1);
b = zeros(n,3);
m = max(uedg(:));
specindex = find( uedg(:,1) == 0 );
%indices = [(1 : specindex - 1)'; ((specindex + 1) : n)']; 
% i = [indices;(1:n)'];
% j = double([uedg(indices,1); uedg(:,2)]);
% v = [-ones(n-1,1);ones(n,1)];
% A = sparse(i,j,v);
A = zeros(n,m);
for i = 1 : n
    actedg = uedg(i,:) + 1;
    logind = ((edg(:,1) == actedg(1)) & (edg(:,2) == actedg(2)));
    uthphir = sum(thphir(logind,:),1) / nnz(logind);
    [x,y,z] = sph2cart(uthphir(1), uthphir(2), uthphir(3));
    b(i,:) = [x,y,z];
    A(i,uedg(i,2)) = 1;
    if ( uedg(i,1) > 0 )
        A(i,uedg(i,1)) = -1;
    end
end
rc = rcond(full(A'*A)); 
if rc < 4 * eps
    warning('Polygon is disconnested');
    base = zeros(size(A,2),3);
else
%A=full(A);
base = A \ b;
end
% Errm = A * base - b;
% Errm = sqrt(dot(Errm,Errm,2));
uedg = uedg + 1;
%T = table((1:size(uedg,1))', Errm, vid(uedg(:,1)), vid(uedg(:,2)));
%disp(T);
base = [zeros(1,3);base];
b = [zeros(1,3);b];
A = [1,zeros(1,size(A,2));zeros(size(A,1),1),A];
A(specindex + 1,1) = -1;
Errm = A * base - b;
Errm = sqrt(dot(Errm,Errm,2));
for i = 1 : n
    actedg = uedg(i,:);
    logind = ((edg(:,1) == actedg(1)) & (edg(:,2) == actedg(2)));
    Err(logind) = Errm(i+1);  
end
end

