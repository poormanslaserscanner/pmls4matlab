function T = mergeinputpy( Hc )
%MERGEINPUTPY Summary of this function goes here
%   Detailed explanation goes here
T = mergehdggeneral(Hc);
T = matlab2py(T);
% [ T.vt, T.bindices, T.vzindices, T.edges, T.extindices, T.ezindices ] = ...
%     hedges2py(  base, rays, erays, zeroshots );

end
% function T = mergeinputpy( Hc )
% %MERGEINPUTPY Summary of this function goes here
% %   Detailed explanation goes here
% n = numel( Hc );
% vid = cell(0,1);
% base = zeros(0, 3);
% rays = cell(0, 1);
% erays = cell(0, 1);
% zeroshots = cell(0, 1);
% extended = true;
% for i = 1 : n
%     H = Hc{i};
%     if isfield( H, 'erays_i' )
%         [obase, orays, ozeroshots, oerays] = py2hedges(  H.verts, H.base_i, H.rays_i, H.zeroshots_i, H.erays_i );
%     else
%         extended = false;
%         [obase, orays, ozeroshots, oerays] = py2hedges(  H.verts, H.base_i, H.rays_i, H.zeroshots_i );
%     end
%     [vid, base, rays, erays, zeroshots] = mergehedgehog( vid, base, rays, erays, zeroshots, H.vid, obase, orays, oerays, ozeroshots );
% end
% if ~extended
%     erays = cell(numel(rays),1);
%     T.pmls_type = 'hedgehog';    
% else
%     T.pmls_type = 'ehedgehog';
% end
% [ T.vt, T.bindices, T.vzindices, T.edges, T.extindices, T.ezindices ] = ...
%     hedges2py(  base, rays, erays, zeroshots );
% T.vid = vid;
% if n > 0
%     T.pmls_name = [Hc{1}.pmls_name, '_merge'];
% end
% 
% end

% function [vid, base, rays, erays, zeroshots] = mergehedgehog( vid, base, rays, erays, zeroshots, ovid, obase, orays, oerays, ozeroshots )
% n = numel( ovid );
% for i = 1 : n
%     index = find( strcmp(ovid{i}, vid) );
%     if isempty( index )
%         next = numel(vid) + 1;
%         vid{next,1} = ovid{i};
%         base(next, :) = obase(i,:);
%         rays{next,1} = orays{i};
%         erays{next,1} = oerays{i};
%         zeroshots{next,1} = ozeroshots{i};
%     else
%         siz = size( orays{i}, 1 );
%         rays{ index } = [ rays{index}; ( orays{i} - repmat( obase(i,:), siz, 1) + repmat( base(index,:), siz, 1 ) ) ];
%         siz = size( oerays{i}, 1 );
%         erays{ index } = [ erays{index}; ( oerays{i} - repmat( obase(i,:), siz, 1) + repmat( base(index,:), siz, 1 ) ) ];
%         if isempty(zeroshots{index})
%             zeroshots{index} = ozeroshots{i};
%         end
%     end
% end
% end
