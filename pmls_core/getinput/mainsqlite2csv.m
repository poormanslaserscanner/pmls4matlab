function mainsqlite2csv( sqfile, csvfile )
%SELDAT Summary of this function goes here
%   Detailed explanation goes here
fp = which( 'sqlite3.exe' );
i = find(fp == '\');
if ~isempty(i)
    i = i(end) - 1;
    fp = fp(1:i);
    s = sqlite(sqfile, fp);
else
    s = sqlite(sqfile);
end
[~,out] = fprintf( s, sprintf('SELECT * FROM surveys') );
fid = fopen(csvfile,'wt');
fprintf(fid, 'id|name|day|team|comment|declination|init_station\n');
fprintf( fid, '%s', out'  );
fclose(fid);

end



