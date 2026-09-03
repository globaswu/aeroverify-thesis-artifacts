function outputFile = plot_6_1(outputFile)
scriptDir = fileparts(mfilename('fullpath'));
if nargin < 1 || isempty(outputFile)
    outputFile = fullfile(scriptDir, 'plot_6_1.png');
end
outputFile = char(outputFile);
outputDir = fileparts(outputFile);
if ~isempty(outputDir) && ~isfolder(outputDir), mkdir(outputDir); end
dataFile = fullfile(scriptDir, 'figure_6_1.csv');
T = readtable(dataFile, 'TextType', 'string', 'VariableNamingRule', 'preserve');
set(groot, 'defaultAxesFontName', 'Times New Roman');
set(groot, 'defaultTextFontName', 'Times New Roman');
E = sortrows(T(T.record_type == "evaluation", :), 'case_id');
S = T(T.record_type == "phase_summary", :);
fig = figure('Color','w','Visible','off','Position',[100 100 1000 450]);
tl = tiledlayout(fig,1,2,'TileSpacing','compact','Padding','compact');
ax = nexttile(tl); hold(ax,'on');
initial = E.case_id <= 30; adaptive = E.case_id >= 30;
plot(ax,E.case_id(initial),E.normalized_hypervolume(initial),'Color',[.16 .47 .71],'LineWidth',1.5);
plot(ax,E.case_id(adaptive),E.normalized_hypervolume(adaptive),'Color',[.90 .38 .01],'LineWidth',1.8);
scatter(ax,30,1,28,[.16 .47 .71],'filled');
scatter(ax,100,E.normalized_hypervolume(end),32,[.90 .38 .01],'d','filled');
xline(ax,30,'--','Color',[.13 .13 .13]); grid(ax,'on');
xlabel(ax,'Finalized evaluation'); ylabel(ax,'HV_{box} / value at case 30'); title(ax,'Box-restricted hypervolume');
ax = nexttile(tl);
phases = ["initial_design","adaptive_phase"];
values = zeros(2,2); counts = zeros(2,2); sizes = zeros(2,1);
for k=1:2
    row=S(S.phase==phases(k),:); sizes(k)=row.phase_size;
    values(k,:)=[row.phase_feasible_share_percent,row.phase_final_pareto_share_percent];
    counts(k,:)=[row.phase_feasible_count,row.phase_final_pareto_count];
end
bar(ax,values,'grouped'); ylim(ax,[0 100]); grid(ax,'on');
set(ax,'XTick',1:2,'XTickLabel',{'Initial design','Adaptive phase'});
ylabel(ax,'Share of phase evaluations [%]'); title(ax,'Feasibility and retained-front yield');
legend(ax,{'Feasible evaluations','Members of case-100 PF'},'Location','northwest','FontSize',7);
for i=1:2, for j=1:2, text(ax,i+(j-1.5)*.29,values(i,j)+2,sprintf('%d/%d',counts(i,j),sizes(i)),'HorizontalAlignment','center','FontSize',7); end, end
sgtitle(tl,'Optimization Progress Through Case 100','FontWeight','bold');
exportgraphics(fig,outputFile,'Resolution',200); close(fig); disp(outputFile);
end
