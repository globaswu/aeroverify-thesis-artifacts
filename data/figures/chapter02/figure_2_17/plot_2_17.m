function metrics = plot_2_17(outputPath)
%PLOT_2_17 Matched rigid W2GJ on/off comparison from adjacent CSV, without CFD.
% The CSV retains all nine verified model points. Figure and fits use -2:2:8.
% The Sivells reference is reconstructed from Table I experimental parameters.

outDir = fileparts(mfilename('fullpath'));
if nargin < 1 || strlength(string(outputPath)) == 0
    outputPath = fullfile(outDir,'figure_2_17_matlab.png');
end
T = readtable(fullfile(outDir,'figure_2_17.csv'));
assert(isequal(T.alpha_deg,(-4:2:12).'), 'Expected nine verified incidences.');
reconstructed = T.reference_slope_per_deg.*(T.alpha_deg-T.reference_zero_lift_deg);
assert(all(abs(reconstructed-T.CL_Sivells_tabulated_linear_reference)<1e-12));
assert(all(abs(T.CL_W2GJ_on-T.CL_on_independent_force_sum)<1e-6));
assert(all(abs(T.CL_W2GJ_off-T.CL_off_independent_force_sum)<1e-6));
T = T(T.alpha_deg>=-2 & T.alpha_deg<=8,:);
alpha = T.alpha_deg;
referenceSlope = T.reference_slope_per_deg(1);
referenceZero = T.reference_zero_lift_deg(1);
denseAlpha = linspace(-2,8,501).';
reference = referenceSlope.*(denseAlpha-referenceZero);
fig = figure('Visible','off','Color','w','Units','inches', ...
    'Position',[1 1 7.087 4.75],'PaperPositionMode','auto');
cleanup = onCleanup(@()close(fig));
ax = axes(fig,'Units','normalized','Position',[0.12 0.145 0.855 0.685]);
hold(ax,'on');
hReference = plot(ax,denseAlpha,reference,'--','Color',[0.2 0.2 0.2],'LineWidth',1.55);
hOn = plot(ax,alpha,T.CL_W2GJ_on,'-s','Color',[33 102 172]/255, ...
    'LineWidth',1.6,'MarkerSize',5.6,'MarkerFaceColor','w');
hOff = plot(ax,alpha,T.CL_W2GJ_off,'-.o','Color',[198 107 24]/255, ...
    'LineWidth',1.55,'MarkerSize',5.6,'MarkerFaceColor','w');
set(ax,'FontName','Times New Roman','FontSize',10,'LineWidth',0.8, ...
    'TickDir','out','Box','on','XLim',[-2.25 8.25],'YLim',[-0.24 0.94], ...
    'XTick',alpha,'YTick',-0.2:0.2:0.8,'GridColor',[0.75 0.75 0.75],'GridAlpha',0.45);
grid(ax,'on');
yline(ax,0,'-','Color',[0.66 0.66 0.66],'LineWidth',0.7,'HandleVisibility','off');
xlabel(ax,'Root-chord incidence, \alpha (deg)','FontName','Times New Roman','FontSize',11);
ylabel(ax,'Wing lift coefficient, C_L','FontName','Times New Roman','FontSize',11);
lgd = legend(ax,[hReference hOn hOff], ...
    {'Sivells (1947), Table I: linear reconstruction','Rigid W2GJ on','Rigid W2GJ off'}, ...
    'Location','northwest','FontName','Times New Roman','FontSize',9.5,'Box','off');
lgd.Color = 'w';
annotation(fig,'textbox',[0.12 0.902 0.855 0.07], ...
    'String','Rigid-wing W2GJ camber control','LineStyle','none','Margin',0, ...
    'FontName','Times New Roman','FontSize',12.5,'VerticalAlignment','middle');
annotation(fig,'textbox',[0.12 0.848 0.855 0.05], ...
    'String','Matched on/off pair; M=0.17; 3^{\circ} dihedral; 110\times50 aerodynamic boxes', ...
    'LineStyle','none','Margin',0,'FontName','Times New Roman','FontSize',9.8, ...
    'Color',[0.31 0.31 0.31],'VerticalAlignment','middle');
[outputFolder,~,outputExtension] = fileparts(outputPath);
if ~isempty(outputFolder) && ~isfolder(outputFolder), mkdir(outputFolder); end
switch lower(outputExtension)
    case '.png', print(fig,outputPath,'-dpng','-r600');
    case '.svg', print(fig,outputPath,'-dsvg');
    otherwise, error('Use a PNG or SVG output path.');
end
values = [T.CL_W2GJ_on T.CL_W2GJ_off];
slopes = zeros(2,1); intercepts = zeros(2,1); rmse = zeros(2,1);
for k = 1:2
    fitted = polyfit(alpha,values(:,k),1);
    slopes(k) = fitted(1); intercepts(k) = fitted(2);
    rmse(k) = sqrt(mean((values(:,k)-T.CL_Sivells_tabulated_linear_reference).^2));
end
metrics = table(["on";"off"],slopes,-intercepts./slopes,values(alpha==0,:).',rmse, ...
    'VariableNames',{'W2GJ','slope_per_degree','fitted_zero_lift_angle_deg', ...
    'CL_at_zero_incidence','RMSE_against_reconstructed_reference'});
disp(metrics);
end
