function outputFile = plot_6_5(outputFile)
scriptDir = fileparts(mfilename('fullpath'));
if nargin < 1 || isempty(outputFile)
    outputFile = fullfile(scriptDir, 'plot_6_5.png');
end
outputFile = char(outputFile);
outputDir = fileparts(outputFile);
if ~isempty(outputDir) && ~isfolder(outputDir), mkdir(outputDir); end
dataFile = fullfile(scriptDir, 'figure_6_5.csv');
T = readtable(dataFile, 'TextType', 'string', 'VariableNamingRule', 'preserve');
set(groot, 'defaultAxesFontName', 'Times New Roman'); set(groot, 'defaultTextFontName', 'Times New Roman');
S=T(T.record_type=="trim_stress",:); E=T(T.record_type=="strain_energy",:); F=T(T.record_type=="flutter_envelope",:); cases=unique(S.case_id,'sorted'); colors=lines(numel(cases)); fig=figure('Color','w','Visible','off','Position',[100 100 850 950]); tl=tiledlayout(fig,2,2,'TileSpacing','compact','Padding','compact'); ax=gobjects(4,1); for k=1:4,ax(k)=nexttile(tl);hold(ax(k),'on');end
for k=1:numel(cases)
 sh=sortrows(S(S.case_id==cases(k)&S.stress_component=="shell_von_mises",:),'normalized_semispan'); be=sortrows(S(S.case_id==cases(k)&S.stress_component=="cbeam_maxabs_normal",:),'normalized_semispan'); en=sortrows(E(E.case_id==cases(k),:),'angle_of_attack_deg'); fl=sortrows(F(F.case_id==cases(k),:),'velocity_m_per_s'); plot(ax(1),sh.normalized_semispan,sh.trim_stress_mpa,'Color',colors(k,:),'LineWidth',1.35,'DisplayName',sprintf('MI%d',cases(k))); plot(ax(2),be.normalized_semispan,be.trim_stress_mpa,'Color',colors(k,:),'LineWidth',1.35); plot(ax(3),en.angle_of_attack_deg,en.half_wing_strain_energy_nm,'o-','Color',colors(k,:),'LineWidth',1.15,'MarkerSize',3.5); plot(ax(4),fl.velocity_m_per_s,1e5*fl.maximum_filtered_damping,'Color',colors(k,:),'LineWidth',1.25);
end
xlim(ax(1),[0 1]);ylim(ax(1),[0 100]);xlabel(ax(1),'Normalized semispan, y/s [-]');ylabel(ax(1),'Shell von Mises stress [MPa]');title(ax(1),'A. Trim shell stress'); xlim(ax(2),[0 1]);ylim(ax(2),[0 100]);xlabel(ax(2),'Normalized semispan, y/s [-]');ylabel(ax(2),'CBEAM max-absolute normal stress [MPa]');title(ax(2),'B. Trim CBEAM stress'); xlabel(ax(3),'Angle of attack [deg]');ylabel(ax(3),'Half-wing strain energy [N m]');title(ax(3),'C. Parsed SOL 144 total strain energy'); xlabel(ax(4),'Velocity [m/s]');ylabel(ax(4),'Maximum filtered damping, 1e5 g [-]');title(ax(4),'D. Conservative V-g envelope over roots');yline(ax(4),0,'--');for k=1:4,grid(ax(k),'on');end;legend(ax(1),'FontSize',7);title(tl,'Representative Stress, Energy, and Aeroelastic Response','FontWeight','bold');exportgraphics(fig,outputFile,'Resolution',200);close(fig);disp(outputFile);
end
