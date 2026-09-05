function outputFile = plot_6_3(outputFile)
scriptDir = fileparts(mfilename('fullpath'));
if nargin < 1 || isempty(outputFile)
    outputFile = fullfile(scriptDir, 'plot_6_3.png');
end
outputFile = char(outputFile);
outputDir = fileparts(outputFile);
if ~isempty(outputDir) && ~isfolder(outputDir), mkdir(outputDir); end
dataFile = fullfile(scriptDir, 'figure_6_3.csv');
T = readtable(dataFile, 'TextType', 'string', 'VariableNamingRule', 'preserve');
set(groot, 'defaultAxesFontName', 'Times New Roman');
set(groot, 'defaultTextFontName', 'Times New Roman');
keys={"normalized_x1_ar","normalized_x2_taper_ratio","normalized_x3_primary_member_ratio","normalized_x4_secondary_member_ratio"}; labels={'Normalized AR','Normalized taper ratio','Normalized primary-member ratio','Normalized secondary-member ratio'}; pairs=[1 2;1 3;1 4;2 3;2 4;3 4];
fig=figure('Color','w','Visible','off','Position',[100 100 800 980]); tl=tiledlayout(fig,3,2,'TileSpacing','compact','Padding','compact');
for p=1:6
 ax=nexttile(tl); hold(ax,'on'); x=T.(keys{pairs(p,1)}); y=T.(keys{pairs(p,2)}); inf=~truth(T.c_feasible_label); ini=truth(T.c_feasible_label)&T.phase=="initial_design"; ada=truth(T.c_feasible_label)&T.phase=="adaptive_phase"; pf=truth(T.final_pareto);
 scatter(ax,x(inf),y(inf),25,[.55 .55 .55],'x','DisplayName','Infeasible'); scatter(ax,x(ini),y(ini),25,'o','MarkerFaceColor','w','MarkerEdgeColor',[.16 .47 .71],'DisplayName','Initial feasible'); scatter(ax,x(ada),y(ada),27,[.90 .38 .01],'d','filled','DisplayName','Adaptive feasible'); scatter(ax,x(pf),y(pf),53,'o','MarkerFaceColor','none','MarkerEdgeColor',[.13 .13 .13],'DisplayName','Case-100 Pareto');
 xlim(ax,[-.025 1.025]); ylim(ax,[-.025 1.025]); xticks(ax,[0 .5 1]); yticks(ax,[0 .5 1]); axis(ax,'square'); grid(ax,'on'); xlabel(ax,labels{pairs(p,1)}); ylabel(ax,labels{pairs(p,2)});
end
legend(tl.Children(end), 'Location','southoutside','NumColumns',4,'FontSize',6.5); title(tl,'Pairwise Projections of the Four-Dimensional Design Domain','FontWeight','bold'); exportgraphics(fig,outputFile,'Resolution',200); close(fig); disp(outputFile);
end
function v=truth(x), if islogical(x),v=x; elseif isnumeric(x),v=x~=0; else,v=strcmpi(string(x),'true'); end, end
