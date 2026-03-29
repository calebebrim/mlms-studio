function disp_wp_feature(feature)
disp('==========================================================');

trstr = [feature.tr.strg];
tsstr = [feature.ts.strg];
disp(['tr.streng: ' num2str(trstr) ' - ts.streng: ' num2str(tsstr)]);

disp(['Cicles: ' num2str(feature.cicles)]);
disp('Centers:');
[c,d] = fn_wp_params(feature.params);
hsz = length(c);
for v = 1:hsz
    disp([num2str(v) ': ' num2str(c(v)) ' - neibor size: ' num2str(d(v))]);
end
disp('==========================================================');
end
