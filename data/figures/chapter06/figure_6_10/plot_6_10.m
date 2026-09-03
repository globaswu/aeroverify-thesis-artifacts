function outputFile = plot_6_10(outputFile)
scriptDir = fileparts(mfilename('fullpath'));
if nargin < 1 || isempty(outputFile)
    outputFile = fullfile(scriptDir, 'plot_6_10.png');
end
outputFile = char(outputFile);
outputDir = fileparts(outputFile);
if ~isempty(outputDir) && ~isfolder(outputDir), mkdir(outputDir); end
dataFile = fullfile(scriptDir, 'figure_6_10.csv');
T = readtable(dataFile, 'TextType', 'string', 'VariableNamingRule', 'preserve');
set(groot, 'defaultAxesFontName', 'Times New Roman'); set(groot, 'defaultTextFontName', 'Times New Roman');
F=T(truth(T.c_feasible_label),:); mass=F.two_wing_mass_kg; compliance=F.y2_ctrim_nm; R=corrcoef(mass,compliance); Rp=corrcoef(averageRank(mass),averageRank(compliance));
fig=figure('Color','w','Visible','off','Position',[100 100 1000 480]); tl=tiledlayout(fig,1,2,'TileSpacing','compact','Padding','compact'); ax=nexttile(tl); hold(ax,'on'); ini=F.phase=="initial_design"; ada=F.phase=="adaptive_phase"; pf=truth(F.final_pareto);
scatter(ax,mass(ini),compliance(ini),31,'o','MarkerFaceColor','w','MarkerEdgeColor',[.16 .47 .71],'DisplayName','Initial feasible'); scatter(ax,mass(ada),compliance(ada),32,[.90 .38 .01],'d','filled','DisplayName','Adaptive feasible'); scatter(ax,mass(pf),compliance(pf),58,'o','MarkerFaceColor','none','MarkerEdgeColor',[.13 .13 .13],'DisplayName','Case-100 Pareto'); grid(ax,'on'); axis(ax,'square'); xlabel(ax,'Full two-wing structural mass [kg]'); ylabel(ax,'Two-wing trim compliance [N m]'); title(ax,sprintf('Feasible sample (n=70)\nPearson r=%.2f; Spearman rho=%.2f',R(1,2),Rp(1,2))); legend(ax,'FontSize',6.5);
ax=nexttile(tl); hold(ax,'on'); C=T(T.case_id<=16,:); plans=unique([C.x1_ar C.x2_taper_ratio],'rows','sorted'); colors=[.16 .47 .71;.90 .38 .01;.18 .55 .34;.64 .23 .45];
for k=1:size(plans,1)
 mask=abs(C.x1_ar-plans(k,1))<1e-12 & abs(C.x2_taper_ratio-plans(k,2))<1e-12; G=sortrows(C(mask,:),'two_wing_mass_kg'); plot(ax,G.two_wing_mass_kg,G.y2_ctrim_nm,'Color',colors(k,:),'LineWidth',1.1,'DisplayName',sprintf('AR=%.0f, lambda=%.1f',plans(k,1),plans(k,2))); ok=truth(G.c_feasible_label); scatter(ax,G.two_wing_mass_kg(ok),G.y2_ctrim_nm(ok),27,colors(k,:),'o','filled','HandleVisibility','off'); scatter(ax,G.two_wing_mass_kg(~ok),G.y2_ctrim_nm(~ok),30,colors(k,:),'x','HandleVisibility','off');
end
grid(ax,'on'); axis(ax,'square'); xlabel(ax,'Full two-wing structural mass [kg]'); ylabel(ax,'Two-wing trim compliance [N m]'); title(ax,'Matched planform corners'); legend(ax,'FontSize',6.5);
title(tl,'Compliance-Mass Relationship Through Case 100','FontWeight','bold'); exportgraphics(fig,outputFile,'Resolution',200); close(fig); disp(outputFile);
end
function v=truth(x), if islogical(x),v=x; elseif isnumeric(x),v=x~=0; else,v=strcmpi(string(x),'true'); end, end
function r=averageRank(x), [s,order]=sort(x); r=zeros(size(x)); i=1; while i<=numel(x), j=i; while j<numel(x)&&s(j+1)==s(i),j=j+1;end; r(order(i:j))=(i+j)/2; i=j+1; end, end
