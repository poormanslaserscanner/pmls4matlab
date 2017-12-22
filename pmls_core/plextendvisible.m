function H = plextendvisible( H )
%PLEXTENDVISIBLE Summary of this function goes here
%   Detailed explanation goes here
[erays, H.eedges] = extendvisible( H.base, H.rays, H.zeroshots );
H.erays = minvisible( H.base, H.rays, erays, H.zeroshots );
H.pmls_type = 'ehedgehog';
H.pmls_name = [H.pmls_name, '_e'];
end

