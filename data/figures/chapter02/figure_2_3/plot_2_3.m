function outputPath = plot_2_3(outputPath)
%PLOT_2_3 Reconstruct two microscopic coupling examples from the adjacent CSV.
% The CSV supplies all geometry. No solver or external data is required.
mpcFigureDirectory = fileparts(mfilename('fullpath'));
if nargin < 1
    outputPath = fullfile(mpcFigureDirectory,'figure_2_3.png');
end
T = readtable(fullfile(mpcFigureDirectory,'figure_2_3.csv'),'TextType','string');
mpcCaseNames = ["snap_repair","ordinary_mpc"];
mpcExamples = cell(1,2);
mpcBases = {eye(3),eye(3)};
for idx = 1:2
    Q = T(T.example==mpcCaseNames(idx),:);
    O = Q(Q.entity=="beam_node" & Q.state=="original",:);
    F = Q(Q.entity=="beam_node" & Q.state=="final",:);
    P = Q(Q.entity=="projection",:);
    S = Q(Q.entity=="shell_vertex",:);
    ex.original_xyz_m = xyz(O); ex.final_xyz_m = xyz(F);
    ex.projection_recalculated_from_source_geometry_m = xyz(P);
    ex.shell_xyz_m = xyz(S); ex.shell_grid_ids = S.grid_id;
    ex.beam_grid_id = O.grid_id; ex.shell_element_id = P.element_id;
    ex.incident_beams = struct('original_xyz_m',{},'final_xyz_m',{});
    ids = unique(Q.element_id(Q.entity=="beam_endpoint"),'stable');
    for j = 1:numel(ids)
        B = Q(Q.entity=="beam_endpoint" & Q.element_id==ids(j),:);
        ex.incident_beams(j).original_xyz_m = xyz(B(B.state=="original",:));
        ex.incident_beams(j).final_xyz_m = xyz(B(B.state=="final",:));
    end
    ex.local_shell_patch = struct('grid_ids',{},'xyz_m',{});
    ids = unique(Q.element_id(Q.entity=="context_shell_vertex"),'stable');
    for j = 1:numel(ids)
        S2 = Q(Q.entity=="context_shell_vertex" & Q.element_id==ids(j),:);
        ex.local_shell_patch(j).grid_ids = S2.grid_id;
        ex.local_shell_patch(j).xyz_m = xyz(S2);
    end
    ex.coordinate_change_m = norm(xyz(F)-xyz(O));
    ex.final_gap_recalculated_m = norm(xyz(F)-xyz(P));
    ex.weights = [ex.shell_xyz_m(:,1:2).';ones(1,3)]\[0;0;1];
    assert(abs(sum(ex.weights)-1)<1e-12);
    mpcExamples{idx} = ex;
end
assert(abs(mpcExamples{1}.coordinate_change_m-0.001298153657195304)<1e-12);
assert(mpcExamples{2}.coordinate_change_m==0);
assert(abs(mpcExamples{2}.final_gap_recalculated_m-8.189147025740352e-6)<1e-12);
mpcBlue = [0.10 0.32 0.51];
mpcGold = [0.71 0.36 0.07];
mpcInk = [0.17 0.19 0.21];
mpcFigure = figure('Visible','off','Color','w','Units','centimeters', ...
    'Position',[2 2 18 14], 'Renderer','opengl');
set(mpcFigure, 'DefaultAxesFontName','Arial', 'DefaultTextFontName','Arial');
annotation(mpcFigure, 'textbox',[0.04 0.933 0.92 0.049], ...
    'String','Microscopic shell-lattice coupling: FCC case 55', ...
    'LineStyle','none','FontSize',11,'FontWeight','bold','Color',mpcInk);
annotation(mpcFigure, 'textbox',[0.04 0.895 0.92 0.039], ...
    'String','Actual skin triangles and incident beam centrelines; geometry shown at equal scale', ...
    'LineStyle','none','FontSize',8.5,'Color',mpcInk);

mpcAxisPositions = [0.04 0.425 0.43 0.425; 0.54 0.425 0.43 0.425];
for mpcIndex = 1:2
    ex = mpcExamples{mpcIndex};
    origin = ex.projection_recalculated_from_source_geometry_m(:).';
    basis = mpcBases{mpcIndex};
    ax = axes(mpcFigure,'Position',mpcAxisPositions(mpcIndex,:));
    hold(ax,'on');
    for j = 1:numel(ex.local_shell_patch)
        tri = ex.local_shell_patch(j);
        if ~any(ismember(tri.grid_ids, ex.shell_grid_ids))
            continue;
        end
        q = (tri.xyz_m - origin) * basis * 1000;
        patch(ax,'Faces',[1 2 3],'Vertices',q, ...
            'FaceColor',[0.79 0.85 0.90],'FaceAlpha',0.30, ...
            'EdgeColor',[0.63 0.69 0.74],'LineWidth',0.55);
    end
    q = (ex.shell_xyz_m - origin) * basis * 1000;
    patch(ax,'Faces',[1 2 3],'Vertices',q,'FaceColor',[0.40 0.62 0.77], ...
        'FaceAlpha',0.33,'EdgeColor',mpcBlue,'LineWidth',1.1);
    for j = 1:3
        plot3(ax,q(j,1),q(j,2),q(j,3),'o','MarkerSize',3.4, ...
            'MarkerFaceColor',mpcBlue,'MarkerEdgeColor',mpcBlue);
        text(ax,q(j,1)+0.08,q(j,2)+0.04,q(j,3)+0.13, ...
            sprintf('i=%d',j),'FontSize',8.5,'Color',mpcBlue);
    end
    for j = 1:numel(ex.incident_beams)
        beam = ex.incident_beams(j);
        qb = (beam.original_xyz_m - origin) * basis * 1000;
        qf = (beam.final_xyz_m - origin) * basis * 1000;
        if mpcIndex == 1
            plot3(ax,qb(:,1),qb(:,2),qb(:,3),'--','Color',mpcGold,'LineWidth',1.5);
        end
        plot3(ax,qf(:,1),qf(:,2),qf(:,3),'-','Color',mpcInk,'LineWidth',1.8);
    end
    b0 = (ex.original_xyz_m(:).' - origin) * basis * 1000;
    bf = (ex.final_xyz_m(:).' - origin) * basis * 1000;
    plot3(ax,0,0,0,'x','MarkerSize',8,'LineWidth',1.4,'Color',mpcBlue);
    if mpcIndex == 1
        plot3(ax,b0(1),b0(2),b0(3),'o','MarkerSize',6,'LineWidth',1.2, ...
            'MarkerFaceColor','w','MarkerEdgeColor',mpcGold);
        plot3(ax,bf(1),bf(2),bf(3),'s','MarkerSize',5,'LineWidth',1.1, ...
            'MarkerFaceColor',mpcInk,'MarkerEdgeColor',mpcInk);
        quiver3(ax,b0(1),b0(2),b0(3),-b0(1),-b0(2),-b0(3),0, ...
            'Color',mpcGold,'LineWidth',1.2,'MaxHeadSize',0.30);
        text(ax,b0(1)+0.18,b0(2)-0.30,b0(3)-0.12,'b_0', ...
            'FontSize',10,'Color',mpcGold);
        text(ax,0.22,-0.20,0.22,'b_1 = p','FontSize',9,'Color',mpcInk);
        text(ax,0.27,0.10,-0.72,'1.298 mm','FontSize',8.5,'Color',mpcGold);
        panelTitle = '(a) Guarded mesh repair: node relocation';
    else
        plot3(ax,bf(1),bf(2),bf(3),'o','MarkerSize',7,'LineWidth',1.3, ...
            'MarkerFaceColor','none','MarkerEdgeColor',mpcGold);
        text(ax,0.23,-0.16,0.20,'b, p','FontSize',9,'Color',mpcInk);
        panelTitle = '(b) Ordinary MPC: node position retained';
    end
    axis(ax,'equal');
    xlim(ax,[-3 3]); ylim(ax,[-2.8 3.2]); zlim(ax,[-3 0.55]);
    view(ax,[-32 25]);
    set(ax,'XTick',[-2 0 2],'YTick',[-2 0 2],'ZTick',[-2 0], ...
        'FontSize',7,'Box','off','LineWidth',0.6,'XColor',[0.45 0.47 0.49], ...
        'YColor',[0.45 0.47 0.49],'ZColor',[0.45 0.47 0.49], ...
        'TickLength',[0.012 0.012]);
    xlabel(ax,'s (mm)','FontSize',8); ylabel(ax,'t (mm)','FontSize',8);
    zlabel(ax,'n (mm)','FontSize',8);
    title(ax,panelTitle,'FontSize',9,'FontWeight','bold', ...
        'Units','normalized','Position',[0.5 1.065 0],'Color',mpcInk);
end

% The small offset is resolved with a uniformly magnified orthographic inset.
% This is an s-n projection of the retained geometry, not a distorted 3-D gap.
ex = mpcExamples{2};
origin = ex.projection_recalculated_from_source_geometry_m(:).';
basis = mpcBases{2};
mpcInset = axes(mpcFigure,'Position',[0.535 0.105 0.20 0.200]);
hold(mpcInset,'on');
plot(mpcInset,[-7 7],[0 0],'-','Color',mpcBlue,'LineWidth',1.4);
for j = 1:numel(ex.incident_beams)
    qb = (ex.incident_beams(j).final_xyz_m - origin) * basis * 1e6;
    plot(mpcInset,qb(:,1),qb(:,3),'-','Color',mpcInk,'LineWidth',1.6);
end
b = (ex.final_xyz_m(:).' - origin) * basis * 1e6;
plot(mpcInset,0,0,'x','MarkerSize',6,'LineWidth',1.3,'Color',mpcBlue);
plot(mpcInset,b(1),b(3),'o','MarkerSize',5,'MarkerFaceColor','w', ...
    'MarkerEdgeColor',mpcGold,'LineWidth',1.2);
quiver(mpcInset,0,0,b(1),b(3),0,'Color',mpcGold,'LineWidth',1.2,'MaxHeadSize',0.20);
text(mpcInset,0.7,1.0,'p','FontSize',9,'Color',mpcBlue);
text(mpcInset,b(1)+0.9,b(3)+0.1,'b','FontSize',9,'Color',mpcGold);
text(mpcInset,-2.1,-4.2,'r','FontSize',10,'FontAngle','italic','Color',mpcGold);
axis(mpcInset,'equal'); xlim(mpcInset,[-6 6]); ylim(mpcInset,[-11 3]);
set(mpcInset,'XTick',[-5 0 5],'YTick',[-10 -5 0], ...
    'FontSize',7,'Box','off','LineWidth',0.6,'TickLength',[0.02 0.02]);
xlabel(mpcInset,'s (\mum)','FontSize',7.5);
ylabel(mpcInset,'n (\mum)','FontSize',7.5);
title(mpcInset,'Offset detail (s-n)', ...
    'FontSize',8,'FontWeight','normal','Units','normalized','Position',[0.5 1.08 0]);

annotation(mpcFigure,'textbox',[0.055 0.327 0.42 0.053], ...
    'String','GRID 491572  |  shell CTRIA3 448671', ...
    'LineStyle','none','FontSize',8,'Color',mpcInk);
annotation(mpcFigure,'textbox',[0.055 0.211 0.42 0.11], ...
    'String',{'Dashed: original incident beams', ...
    'Solid: final incident beams', ...
    'Original b_0 moves onto p before MPC generation.'}, ...
    'LineStyle','none','FontSize',8.1,'Color',mpcInk);
annotation(mpcFigure,'textbox',[0.055 0.090 0.42 0.115], ...
    'String',{'N_i = [0.12197, 0.19814, 0.67989]', ...
    'Final ||r|| < 0.1 nm (deck rounding).', ...
    'Node IDs and graph connections are retained.'}, ...
    'LineStyle','none','FontSize',7.8,'Color',mpcInk);
annotation(mpcFigure,'textbox',[0.54 0.352 0.42 0.030], ...
    'String','GRID 472299  |  shell CTRIA3 453875', ...
    'LineStyle','none','FontSize',8,'Color',mpcInk);
annotation(mpcFigure,'textbox',[0.755 0.185 0.22 0.164], ...
    'String',{'r = x_b - x_p', '||r|| = 8.189 \mum', ...
    'Coordinate change: 0', 'p = \Sigma_i N_i x_i'}, ...
    'LineStyle','none','FontSize',8.1,'Color',mpcInk);
annotation(mpcFigure,'textbox',[0.755 0.091 0.22 0.088], ...
    'String',{'N_i = [0.68198,', '0.16393, 0.15409]'}, ...
    'LineStyle','none','FontSize',7.8,'Color',mpcInk);
drawnow;
[outputFolder,~,~] = fileparts(outputPath);
if ~isempty(outputFolder) && ~isfolder(outputFolder), mkdir(outputFolder); end
exportgraphics(mpcFigure,outputPath,'Resolution',300,'BackgroundColor','white');
close(mpcFigure);
fprintf('MPC figure: %s\n',outputPath);
end

function q = xyz(T)
q = T{:,{'local_s_m','local_t_m','local_n_m'}};
end

