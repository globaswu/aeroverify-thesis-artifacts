function outputFile = plot_6_2(outputFile)
scriptDir = fileparts(mfilename('fullpath'));
if nargin < 1 || isempty(outputFile)
    outputFile = fullfile(scriptDir, 'plot_6_2.png');
end
outputFile = char(outputFile);
outputDir = fileparts(outputFile);
if ~isempty(outputDir) && ~isfolder(outputDir), mkdir(outputDir); end
dataFile = fullfile(scriptDir, 'figure_6_2.csv');
T = readtable(dataFile, 'TextType', 'string', 'VariableNamingRule', 'preserve');
set(groot, 'defaultAxesFontName', 'Times New Roman');
set(groot, 'defaultTextFontName', 'Times New Roman');
fig=figure('Color','w','Visible','off','Position',[100 100 900 650]);
ax=axes(fig,'Position',[.11 .15 .82 .76]); drawObjective(ax,T,true); title(ax,'Four-Input Objective Space (100 Evaluations)');
xlabel(ax,'Trim induced-drag coefficient, C_{D_i,trim} [-]'); ylabel(ax,'Two-wing trim compliance, C_{trim} [N m]');
inset=axes(fig,'Position',[.52 .50 .36 .32]); drawObjective(inset,T,false); title(inset,'Feasible-front detail','FontSize',8);
P=T(truth(T.final_pareto),:); dx=range(P.y1_cditrim); dy=range(P.y2_ctrim_nm); xlim(inset,[min(P.y1_cditrim)-.06*dx,max(P.y1_cditrim)+.06*dx]); ylim(inset,[min(P.y2_ctrim_nm)-.06*dy,max(P.y2_ctrim_nm)+.06*dy]);
exportgraphics(fig,outputFile,'Resolution',200); close(fig); disp(outputFile);
end
function drawObjective(ax,T,showLegend)
hold(ax,'on'); inf=~truth(T.c_feasible_label); dom=truth(T.c_feasible_label)&~truth(T.final_pareto); ini=truth(T.final_pareto)&T.case_id<=30; ada=truth(T.final_pareto)&T.case_id>30; ref=truth(T.refined_mesh);
scatter(ax,T.y1_cditrim(inf),T.y2_ctrim_nm(inf),36,[.55 .55 .55],'x','DisplayName','Infeasible');
scatter(ax,T.y1_cditrim(dom),T.y2_ctrim_nm(dom),40,'o','MarkerFaceColor','w','MarkerEdgeColor',[.16 .47 .71],'DisplayName','Feasible, dominated');
scatter(ax,T.y1_cditrim(ini),T.y2_ctrim_nm(ini),48,[.13 .13 .13],'o','filled','DisplayName','Initial-design Pareto');
scatter(ax,T.y1_cditrim(ada),T.y2_ctrim_nm(ada),50,[.90 .38 .01],'d','filled','DisplayName','Adaptive Pareto');
scatter(ax,T.y1_cditrim(ref),T.y2_ctrim_nm(ref),66,'s','MarkerFaceColor','none','MarkerEdgeColor',[.42 .24 .60],'DisplayName','Refined mesh');
P=sortrows(T(truth(T.final_pareto),:),'y1_cditrim'); plot(ax,P.y1_cditrim,P.y2_ctrim_nm,'Color',[.13 .13 .13],'LineWidth',1,'HandleVisibility','off'); grid(ax,'on');
if showLegend, legend(ax,'Location','southoutside','NumColumns',2,'FontSize',7); end
end
function v=truth(x), if islogical(x),v=x; elseif isnumeric(x),v=x~=0; else,v=strcmpi(string(x),'true'); end, end
