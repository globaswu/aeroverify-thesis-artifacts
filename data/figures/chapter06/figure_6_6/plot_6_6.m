function outputFile = plot_6_6(outputFile)
scriptDir = fileparts(mfilename('fullpath'));
if nargin < 1 || isempty(outputFile)
    outputFile = fullfile(scriptDir, 'plot_6_6.png');
end
outputFile = char(outputFile);
outputDir = fileparts(outputFile);
if ~isempty(outputDir) && ~isfolder(outputDir), mkdir(outputDir); end
dataFile = fullfile(scriptDir, 'figure_6_6.csv');
T = readtable(dataFile, 'TextType', 'string', 'VariableNamingRule', 'preserve');
set(groot, 'defaultAxesFontName', 'Times New Roman'); set(groot, 'defaultTextFontName', 'Times New Roman');
T=T(truth(T.c_feasible_label),:); keys={'x1_ar','x2_taper_ratio','x3_primary_member_ratio','x4_secondary_member_ratio','two_wing_mass_kg','y1_cditrim','y2_ctrim_nm'}; labels={'AR','lambda','r1','r2','m2W','CDi,trim','Ctrim'}; X=zeros(height(T),numel(keys));
for j=1:numel(keys), X(:,j)=T.(keys{j}); end
bounds=[6 12;.2 .8;.05 .4;.15 .5];
for j=1:4, X(:,j)=(X(:,j)-bounds(j,1))/(bounds(j,2)-bounds(j,1)); end
for j=5:7, X(:,j)=(X(:,j)-min(X(:,j)))/(max(X(:,j))-min(X(:,j))); end
fig=figure('Color','w','Visible','off','Position',[100 100 950 620]); ax=axes(fig); hold(ax,'on');
for i=1:height(T)
 if truth(T.final_pareto(i)) && T.phase(i)=="adaptive_phase", c=[.90 .38 .01]; w=1.8; a=.92; elseif truth(T.final_pareto(i)), c=[.13 .13 .13]; w=1.35; a=.78; else, c=[.16 .47 .71]; w=.8; a=.28; end
 plot(ax,1:7,X(i,:),'Color',[c a],'LineWidth',w);
end
for j=1:7, plot(ax,[j j],[0 1],'Color',[.13 .13 .13],'LineWidth',.65); end
xlim(ax,[.8 6.2]); ylim(ax,[-.03 1.03]); set(ax,'XTick',1:7,'XTickLabel',labels,'YTick',[]); box(ax,'off'); title(ax,sprintf('Parallel Coordinates of the 70 Feasible Evaluations\nMass is diagnostic; the two rightmost axes are minimized objectives'));
h1=plot(ax,nan,nan,'Color',[.16 .47 .71],'LineWidth',1.2); h2=plot(ax,nan,nan,'Color',[.13 .13 .13],'LineWidth',1.5); h3=plot(ax,nan,nan,'Color',[.90 .38 .01],'LineWidth',2); legend(ax,[h1 h2 h3],{'Feasible, dominated','Initial-design Pareto','Adaptive Pareto'},'Location','southoutside','NumColumns',3);
exportgraphics(fig,outputFile,'Resolution',200); close(fig); disp(outputFile);
end
function v=truth(x), if islogical(x),v=x; elseif isnumeric(x),v=x~=0; else,v=strcmpi(string(x),'true'); end, end
