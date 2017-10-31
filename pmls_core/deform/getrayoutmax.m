function pnts = getrayoutmax( tris, vt, base, rays, voxsiz )
%GETRAYOUTMAX Summary of this function goes here
%   Detailed explanation goes here
if nargin < 5
    voxsiz = 5;
end
[v, bb0, grs] = binunion( {tris}, {[vt;cell2mat(rays)]}, voxsiz, 0.75 );
v = bwdist(v);
vsiz = size( v );


%  indices = find( v == 1 );
%              [i1,i2,i3] = ind2sub(vsiz,indices);
%              bbb = repmat(bb0,numel(indices),1);
%              q = [i1+0.5,i2+0.5,i3+0.5] * grs;
%              pnts = q + bbb;
%  
%  return;
n = numel(rays);
pnts = zeros(0,3);
for i = 1 : n
    p0 = floor( ( base( i, : ) - bb0 ) / grs );
    m = size( rays{i}, 1 );
        for k = 1 : m
            pfiz = rays{i}(k,:);
            p = floor( (pfiz - bb0) / grs );
            d = p-p0;
            N = max(abs(d));
            lin1 = round( linspace( p0(1), p(1), N ) );
            log1 = (lin1 <= vsiz( 1 ) & lin1 > 0 );

            lin2 = round( linspace( p0(2), p(2), N ) ); 
            log2 = (lin2 <= vsiz( 2 ) & lin2 > 0 );

            lin3 = round( linspace( p0(3), p(3), N ) );
            log3 = (lin3 <= vsiz( 3 ) & lin3 > 0 );
            logind = log1 & log2 & log3;
            indices = sub2ind( vsiz, lin1(logind), lin2(logind), lin3(logind) );
%            [maxv,maxi] = max(v(indices));
%            if maxv > 2
%                [i1,i2,i3] = ind2sub(vsiz,indices(maxi));
%                e = normr(pfiz - base(i,:));
%                q = base(i,:) + e * ( ([i1,i2,i3] * grs + bb0 - base(i,:))' * e );
%                pnts = [pnts; q];
%            end

            logind = (v(indices) > 0);
            if any(logind)
            indices = indices(logind);
            [i1,i2,i3] = ind2sub(vsiz,indices);
            e = normr(pfiz - base(i,:));
            bas = repmat(base(i,:),numel(indices),1);
            bbb = repmat(bb0,numel(indices),1);
            q = [i1 + 0.5;i2 + 0.5;i3 + 0.5]' * grs;
            q = q + bbb - bas;
            q = bas + q;%(q * e')*e;
            pnts = [pnts; q];
            end
        end
   
end

end

