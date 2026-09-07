function plot_2_15(outputPath)
%PLOT_2_15 Reproduce archived CFD diagnostics from adjacent CSV, without CFD.
% Whiskers show observed iteration ranges, not uncertainty intervals.
% Input CSV retains all samples; the history panel displays iterations 40-240.

outDir = fileparts(mfilename('fullpath'));
if nargin < 1, outputPath = fullfile(outDir,'figure_2_15.png'); end
[outputFolder,~,~] = fileparts(outputPath);
if ~isempty(outputFolder) && ~isfolder(outputFolder), mkdir(outputFolder); end
T = readtable(fullfile(outDir, 'figure_2_15.csv'), 'TextType', 'string');
assert(height(T) == 75, 'Expected 75 retained samples.');
assert(all(T.monitor_reported_pass == 1), 'Original monitor pass must be retained.');
assert(all(T.boundary_layer_extrusion_enabled == 0), 'Layer setting changed.');
meshes = ["geom_coarse", "geom_medium", "geom_fine"];
labels = ["Coarse", "Medium", "Fine"];
colors = [102 102 102; 33 102 172; 198 107 24]/255;
markers = {'o','s','^'};
fig = figure('Visible','off','Color','w','Units','inches', ...
    'Position',[1 1 7.087 5.6],'PaperPositionMode','auto');
cleanup = onCleanup(@() close(fig));
history = axes(fig,'Units','normalized','Position',[0.105 0.29 0.465 0.465]);
terminal = axes(fig,'Units','normalized','Position',[0.76 0.29 0.212 0.465]);
hold(history,'on'); hold(terminal,'on');
patch(history,[160 240 240 160],[0.0675 0.0675 0.079 0.079], ...
    [0.93 0.93 0.93],'EdgeColor','none','HandleVisibility','off');
handles = gobjects(3,1);
for index = 1:3
    G = sortrows(T(T.mesh_id == meshes(index),:),'iteration');
    assert(height(G)==25, 'Expected 25 samples per mesh.');
    H = G(G.iteration>=40,:);
    last = G(end,:);
    tail = G(G.iteration>=last.iteration-last.monitor_window_iterations,:);
    lo = min(tail.CD_total); hi = max(tail.CD_total); cd = last.CD_total;
    handles(index) = plot(history,H.iteration,H.CD_total,'-', ...
        'Color',colors(index,:),'LineWidth',1.45,'Marker',markers{index}, ...
        'MarkerIndices',1:4:height(H),'MarkerSize',4.1,'MarkerFaceColor','w');
    y = 3-index;
    plot(terminal,[lo hi],[y y],'-','Color',colors(index,:),'LineWidth',1.3);
    plot(terminal,[lo lo],[y-0.065 y+0.065],'-','Color',colors(index,:),'LineWidth',1.3);
    plot(terminal,[hi hi],[y-0.065 y+0.065],'-','Color',colors(index,:),'LineWidth',1.3);
    plot(terminal,cd,y,markers{index},'Color',colors(index,:), ...
        'MarkerSize',5.5,'MarkerFaceColor','w','LineWidth',1.1);
    text(terminal,cd,y+0.23,sprintf('%.5f',cd),'Color',colors(index,:), ...
        'FontName','Times New Roman','FontSize',9.5, ...
        'HorizontalAlignment','center','VerticalAlignment','bottom');
    text(terminal,0.0670,y+0.09,labels(index),'FontName','Times New Roman', ...
        'FontSize',9.2,'HorizontalAlignment','right','VerticalAlignment','middle');
    text(terminal,0.0670,y-0.10,sprintf('%.3f M cells',last.cell_count/1e6), ...
        'FontName','Times New Roman','FontSize',9.2, ...
        'HorizontalAlignment','right','VerticalAlignment','middle');
    fprintf('%s: %.0f cells; final CD=%.10f; last80 range=[%.10f,%.10f]; original monitor passed\n', ...
        labels(index),last.cell_count,cd,lo,hi);
end
set(history,'XLim',[40 248],'YLim',[0.0675 0.079], ...
    'XTick',[40 80 120 160 200 240],'YTick',0.068:0.002:0.078);
xlabel(history,'Steady-solver iteration','FontName','Times New Roman','FontSize',10.5);
ylabel(history,'CFD total drag coefficient, C_D','FontName','Times New Roman','FontSize',10.5);
legend(history,handles,labels,'Location','northeast','FontName','Times New Roman', ...
    'FontSize',9,'Box','off','Color','w');
set(terminal,'XLim',[0.0675 0.0785],'YLim',[-0.6 2.65], ...
    'XTick',[0.070 0.075],'YTick',[0 1 2],'YTickLabel',{'','',''});
xlabel(terminal,'C_D at iteration 240','FontName','Times New Roman','FontSize',10.5);
for ax = [history terminal]
    set(ax,'FontName','Times New Roman','FontSize',9.2, ...
        'LineWidth',0.8,'Box','on','TickDir','out', ...
        'GridColor',[0.75 0.75 0.75],'GridAlpha',0.5);
end
grid(history,'on'); terminal.XGrid = 'on'; terminal.YGrid = 'off';
addText(fig,[0.105 0.915 0.87 0.06],'Archived full-wing CFD drag diagnostics',12.5);
addText(fig,[0.105 0.865 0.87 0.05], ...
    'NACA 65-210 coordinate input; \alpha=7^{\circ}; U_{\infty}=98.68 m s^{-1}',10);
addText(fig,[0.105 0.783 0.465 0.055],'A  Total-drag history',11);
addText(fig,[0.66 0.783 0.33 0.055],'B  Terminal mesh values',11);
addText(fig,[0.105 0.144 0.87 0.05], ...
    'Shading / whiskers: iterations 160-240 (nine samples); whiskers show ranges, not uncertainty.',8.4);
addText(fig,[0.105 0.094 0.87 0.05], ...
    'All runs passed the original force-range monitor at iteration 240 (drag tolerance: 60 N).',8.8);
addText(fig,[0.105 0.044 0.87 0.05], ...
    'Boundary-layer extrusion was disabled. Monitor acceptance is not experimental validation.',8.8);
print(fig,outputPath,'-dpng','-r600');

end

function addText(fig,position,value,fontSize)
annotation(fig,'textbox',position,'String',value,'Interpreter','tex', ...
    'LineStyle','none','Margin',0,'FontName','Times New Roman', ...
    'FontSize',fontSize,'Color',[0.2 0.2 0.2],'VerticalAlignment','middle');
end
