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
fig=figure('Color','w','Visible','off','Position',[100 100 1000 480]); tl=tiledlayout(fig,1,2,'TileSpacing','compact','Padding','compact');
ax=nexttile(tl); cats=["feasible","shell_von_mises_only","cbeam_normal_only","shell_and_cbeam"]; phases=["initial_design","adaptive_phase"]; C=zeros(4,2);
for i=1:4, for j=1:2, C(i,j)=sum(T.failure_mechanism==cats(i)&T.phase==phases(j)); end, end
bar(ax,C,'grouped'); set(ax,'XTick',1:4,'XTickLabel',{'Feasible','Shell VM','CBEAM normal','Shell + CBEAM'}); xtickangle(ax,18); ylabel(ax,'Number of evaluations'); title(ax,'Feasibility outcomes'); grid(ax,'on'); legend(ax,{'Initial design','Adaptive phase'},'FontSize',7);
ax=nexttile(tl); hold(ax,'on'); inf=~truth(T.c_feasible_label); ini=truth(T.c_feasible_label)&T.phase=="initial_design"; ada=truth(T.c_feasible_label)&T.phase=="adaptive_phase"; pf=truth(T.final_pareto);
scatter(ax,T.shell_utilization(inf),T.cbeam_utilization(inf),30,[.55 .55 .55],'x','DisplayName','Infeasible'); scatter(ax,T.shell_utilization(ini),T.cbeam_utilization(ini),29,'o','MarkerFaceColor','w','MarkerEdgeColor',[.16 .47 .71],'DisplayName','Initial feasible'); scatter(ax,T.shell_utilization(ada),T.cbeam_utilization(ada),31,[.90 .38 .01],'d','filled','DisplayName','Adaptive feasible'); scatter(ax,T.shell_utilization(pf),T.cbeam_utilization(pf),57,'o','MarkerFaceColor','none','MarkerEdgeColor',[.13 .13 .13],'DisplayName','Case-100 Pareto');
xline(ax,1,'--'); yline(ax,1,'--'); set(ax,'XScale','log','YScale','log'); axis(ax,'square'); grid(ax,'on'); xlabel(ax,'Shell von Mises utilization'); ylabel(ax,'CBEAM normal-stress utilization'); title(ax,'Stress-screening map'); legend(ax,'FontSize',6.5,'Location','best');
sgtitle(tl,'Feasibility Mechanisms at 100 Finalized Evaluations','FontWeight','bold'); exportgraphics(fig,outputFile,'Resolution',200); close(fig); disp(outputFile);
end
function v=truth(x), if islogical(x),v=x; elseif isnumeric(x),v=x~=0; else,v=strcmpi(string(x),'true'); end, end
