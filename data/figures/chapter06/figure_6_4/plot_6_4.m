function outputFile = plot_6_4(outputFile)
scriptDir = fileparts(mfilename('fullpath'));
if nargin < 1 || isempty(outputFile)
    outputFile = fullfile(scriptDir, 'plot_6_4.png');
end
outputFile = char(outputFile);
outputDir = fileparts(outputFile);
if ~isempty(outputDir) && ~isfolder(outputDir), mkdir(outputDir); end
dataFile = fullfile(scriptDir, 'figure_6_4.csv');
T = readtable(dataFile, 'TextType', 'string', 'VariableNamingRule', 'preserve');
set(groot, 'defaultAxesFontName', 'Times New Roman'); set(groot, 'defaultTextFontName', 'Times New Roman');
L=T(T.record_type=="llt",:); D=T(T.record_type=="trim_displacement",:); cases=unique(L.case_id,'sorted'); colors=lines(numel(cases)); fig=figure('Color','w','Visible','off','Position',[100 100 850 950]); tl=tiledlayout(fig,2,2,'TileSpacing','compact','Padding','compact'); ax=gobjects(4,1); for k=1:4,ax(k)=nexttile(tl);hold(ax(k),'on');end
for k=1:numel(cases)
 A=sortrows(L(L.case_id==cases(k),:),'normalized_semispan'); B=sortrows(D(D.case_id==cases(k),:),'normalized_semispan'); plot(ax(1),A.normalized_semispan,A.lift_per_unit_span_n_per_m,'Color',colors(k,:),'LineWidth',1.35,'DisplayName',sprintf('MI%d',cases(k))); plot(ax(2),A.normalized_semispan,A.outboard_bending_moment_nm/1000,'Color',colors(k,:),'LineWidth',1.35); plot(ax(3),B.normalized_semispan,B.trim_twist_deg,'Color',colors(k,:),'LineWidth',1.35); plot(ax(4),B.normalized_semispan,1000*B.trim_vertical_displacement_m,'Color',colors(k,:),'LineWidth',1.35);
end
titles={'A. Torsion-corrected LLT load','B. Derived outboard-load moment','C. SOL 144 trim twist','D. SOL 144 trim vertical displacement'}; ylabels={'LLT lift per unit span [N/m]','Aerodynamic bending moment [kN m]','Torsional displacement [deg]','Vertical displacement [mm]'}; for k=1:4,xlim(ax(k),[0 1]);grid(ax(k),'on');xlabel(ax(k),'Normalized semispan, y/s [-]');ylabel(ax(k),ylabels{k});title(ax(k),titles{k});end; legend(ax(1),'FontSize',7); title(tl,'Representative Static Aerostructural Decomposition','FontWeight','bold'); exportgraphics(fig,outputFile,'Resolution',200); close(fig); disp(outputFile);
end
