function outputPath = plot_2_1(csvPath, outputPath)
%PLOT_SPANWISE_PROFILE Reproduce the analytical profile using the CSV only.
% This function does not reconstruct the nTop geometry or require its image.
if nargin < 1
    csvPath = fullfile(fileparts(mfilename('fullpath')), 'figure_2_1.csv');
end
if nargin < 2
    outputPath = fullfile(fileparts(csvPath), 'figure_2_1.png');
end
T = readtable(csvPath);
assert(height(T) == 51, 'The profile must contain 51 positions.');
assert(all(isfinite(T{:,:}), 'all'), 'All CSV values must be finite.');
assert(max(abs(T.y_m - T.eta .* T.s_m)) < 1e-12);
assert(max(abs(T.t_m - (T.t1_m + (T.t2_m-T.t1_m).*T.eta))) < 1e-12);
assert(max(abs(T.t_mm - 1e3*T.t_m)) < 1e-10);
assert(max(abs(T.t_over_t1 - T.t_m ./ T.t1_m)) < 1e-12);
assert(T.eta(1) == 0 && T.eta(end) == 1);
assert(abs(T.t_m(1)-T.t1_m(1)) < 1e-12);
assert(abs(T.t_m(end)-T.t2_m(end)) < 1e-12);
ink = [0.11 0.15 0.19];
navy = [0.10 0.26 0.40];
f = figure('Visible','off','Color','w','Units','inches', ...
    'Position',[1 1 8.5 4.4],'Renderer','painters');
cleanup = onCleanup(@() close(f));
ax = axes(f,'Position',[0.11 0.20 0.84 0.57], ...
    'FontName','Times New Roman','FontSize',12,'XColor',ink,'YColor',ink);
plot(ax,T.eta,T.t_mm,'Color',navy,'LineWidth',1.8);
hold(ax,'on');
plot(ax,T.eta([1 end]),T.t_mm([1 end]),'o','Color',navy, ...
    'MarkerFaceColor','w','LineWidth',1.5,'MarkerSize',6);
xlim(ax,[0 1]); ylim(ax,[0 5]);
xticks(ax,0:0.2:1); yticks(ax,0:1:5);
ax.YGrid = 'on'; ax.GridColor = [0.75 0.78 0.80]; ax.GridAlpha = 0.45;
ax.Box = 'off';
xlabel(ax,'Normalized spanwise position, y/s');
ylabel(ax,'Geometric strut diameter, t (mm)');
text(ax,0.02,T.t_mm(1)+0.18,sprintf('t_1 = %.4f mm (root)',T.t_mm(1)), ...
    'FontName','Times New Roman','FontSize',12,'Color',navy);
text(ax,0.98,T.t_mm(end)-0.43,sprintf('t_2 = %.4f mm (tip)',T.t_mm(end)), ...
    'HorizontalAlignment','right','FontName','Times New Roman','FontSize',12,'Color',navy);
annotation(f,'textbox',[0.11 0.88 0.84 0.08], ...
    'String','Linear spanwise lattice-strut diameter: case 55', ...
    'EdgeColor','none','FontName','Times New Roman','FontSize',15,'Color',ink);
annotation(f,'textbox',[0.11 0.79 0.84 0.07], ...
    'String',sprintf('t(y) = t_1 + (t_2 - t_1)y/s;   s = %.5f m;   0 \\leq y \\leq s',T.s_m(1)), ...
    'Interpreter','tex','EdgeColor','none','FontName','Times New Roman','FontSize',12,'Color',ink);
set(findall(f,'-property','FontName'),'FontName','Times New Roman');
f.PaperPositionMode = 'auto';
[outputFolder,~,~] = fileparts(outputPath);
if ~isempty(outputFolder) && ~isfolder(outputFolder), mkdir(outputFolder); end
print(f,outputPath,'-dpng','-r300');
fprintf('PROFILE_MATLAB: %s\n', outputPath);
end
