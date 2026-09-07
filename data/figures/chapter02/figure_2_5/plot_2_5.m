function plot_2_5(outputPath)
%PLOT_2_5 Reproduce Figure 2.5 from three CSV inputs beside this function.
%   plot_2_5(outputPath) exports PNG, PDF or SVG according to the extension.
% Chart contract: static retained FCC55 lattice geometry comparison.
% Question: how do the retained beam paths change when 31 nodes snap to skin?
% Six orthographic panels show original/final coordinates in oblique and side
% views, followed by equal-scale interface enlargements. Grain: 348 nodes,
% 399 actual CBEAM edges, 713 shell
% triangles. CSV-only inputs; no projection connectors or amplified motion.
% Hard two-root palette: orange beams/moved nodes, blue receiving facets;
% neutral shell edges. Palette matches the microscopic chapter figures.
% Open/filled markers distinguish original/final. Exported PNG inspected.
plotDirectory = fileparts(mfilename('fullpath'));
if nargin < 1 || isempty(outputPath)
    outputPath = fullfile(plotDirectory,'figure_2_5.png');
end
nodes = readtable(fullfile(plotDirectory,'figure_2_5.csv'),'TextType','string');
beams = readtable(fullfile(plotDirectory,'chunk_beams.csv'));
shell = readtable(fullfile(plotDirectory,'chunk_shell_vertices.csv'));
original = nodes{:,{'original_x_m','original_y_m','original_z_m'}};
final = nodes{:,{'final_x_m','final_y_m','final_z_m'}};
skin = shell{:,{'x_m','y_m','z_m'}};
snapped = nodes.category == "snapped_to_shell_projection";
ordinary = nodes.category == "within_mpc_tolerance";
rejected = nodes.category == "rejected_snap_beam_length";
beyond = nodes.category == "beyond_snap_tolerance";
assert(height(nodes)==348 && height(beams)==399 && height(shell)==2139);
assert(nnz(snapped)==31 && nnz(ordinary)==50 && nnz(rejected)==21 && nnz(beyond)==246);
move = vecnorm(final-original,2,2);
assert(all(move(~snapped)==0) && all(move(snapped)>0));
assert(nnz(nodes.full_lattice_degree(snapped)==2)==29 && nnz(nodes.full_lattice_degree(snapped)==4)==2);
[foundA,indexA] = ismember(beams.grid_a,nodes.grid_id);
[foundB,indexB] = ismember(beams.grid_b,nodes.grid_id);
assert(all(foundA & foundB));
affected = snapped(indexA) | snapped(indexB);
assert(nnz(affected)==60);
assert(all(shell.local_vertex==repmat((1:3)',height(shell)/3,1)));
faces = reshape(1:height(shell),3,[])';
receivingFaces = faces(shell.receiving_for_visible_node(1:3:end)~=0,:);
assert(size(receivingFaces,1)==75);
% Rigid local frame: mean skin normal (+global z), global x projected onto
% that plane, and their right-handed transverse direction. No deformation.
normals = cross(skin(2:3:end,:)-skin(1:3:end,:),skin(3:3:end,:)-skin(1:3:end,:),2);
normals(normals(:,3)<0,:) = -normals(normals(:,3)<0,:);
normal = sum(normals,1); normal = normal/norm(normal);
horizontal = [1 0 0]-normal(1)*normal; horizontal = horizontal/norm(horizontal);
transverse = cross(normal,horizontal);
basis = [horizontal(:),transverse(:),normal(:)];
origin = mean(skin,1);
assert(norm(basis'*basis-eye(3),'fro')<1e-12);
original = (original-origin)*basis*1000;
final = (final-origin)*basis*1000;
skin = (skin-origin)*basis*1000;
extent = [min([original;final;skin],[],1);max([original;final;skin],[],1)];
padding = [2.5 2.5 2];
limits = extent+[-padding;padding];
% Slight in-plane rotation separates rows stacked in the old side view.
sideBasis = [cosd(5) 0;sind(5) 0;0 1];
originalSide = original*sideBasis; finalSide = final*sideBasis;
skinSide = skin*sideBasis;
sideExtent = [min([originalSide;finalSide;skinSide],[],1);max([originalSide;finalSide;skinSide],[],1)];
sideLimits = sideExtent+[-2.5 -2;2.5 2];
zoomLimits = [-24 -4;-8 .6];
visibleZoom = snapped & originalSide(:,1)>=zoomLimits(1,1) & originalSide(:,1)<=zoomLimits(2,1);
blue = [0.10 0.36 0.67]; orange = [0.85 0.32 0.04]; paleOrange = [.95 .74 .57]; ink = [0.19 0.20 0.22];
markerEdge = [0.38 0.17 0.04];
fig = figure('Visible','off','Color','w','Units','pixels','Position',[50 50 1600 1500]);
set(fig,'DefaultAxesFontName','Arial','DefaultTextFontName','Arial',...
    'DefaultTextInterpreter','none','DefaultLegendInterpreter','none','PaperPositionMode','auto');
annotation(fig,'textbox',[.045 .943 .91 .04],'String','Local lattice patch before and after mesh repair',...
    'EdgeColor','none','FontSize',20,'FontWeight','bold','Color',ink,'Margin',0);
annotation(fig,'textbox',[.045 .904 .91 .03],...
    'String',sprintf('399 beams: 60 affected, 339 unchanged | 31 nodes move %.3f–%.3f mm | no added beams',min(move(snapped))*1000,max(move(snapped))*1000),...
    'EdgeColor','none','FontSize',12.5,'Color',ink,'Margin',0);
positions = [.06 .61 .40 .28;.55 .61 .40 .28;.06 .345 .40 .21;.55 .345 .40 .21;.06 .163 .40 .125;.55 .163 .40 .125];
panelNames = {'(a) Before nodal repair — oblique','(b) After nodal repair — oblique',...
    '(c) Before nodal repair — side','(d) After nodal repair — side',...
    '(e) Before — enlarged skin interface','(f) After — enlarged skin interface'};
for k=1:6
    ax = axes(fig,'Position',positions(k,:)); hold(ax,'on');
    state = original; stateSide=originalSide; fill = 'w';
    if mod(k,2)==0, state=final; stateSide=finalSide; fill=orange; end
    if k<=2
      patch(ax,'Vertices',skin,'Faces',faces,'FaceColor',[.74 .76 .78],...
        'FaceAlpha',.12,'EdgeColor',[.69 .71 .73],'EdgeAlpha',.42,'LineWidth',.30);
      patch(ax,'Vertices',skin,'Faces',receivingFaces,'FaceColor',blue,...
        'FaceAlpha',.36,'EdgeColor',[.55 .57 .59],'EdgeAlpha',.65,'LineWidth',.35);
      for group=1:2
        selected=~affected;lineColor=paleOrange;lineWidth=.75;
        if group==2, selected=affected;lineColor=orange;lineWidth=1.4;end
        for dimension=1:3
          edgeCoordinates{dimension}=reshape([state(indexA(selected),dimension),state(indexB(selected),dimension),nan(nnz(selected),1)]',[],1); %#ok<SAGROW>
        end
        plot3(ax,edgeCoordinates{1},edgeCoordinates{2},edgeCoordinates{3},'-','Color',lineColor,'LineWidth',lineWidth);
      end
      plot3(ax,state(snapped,1),state(snapped,2),state(snapped,3),'o',...
        'LineStyle','none','MarkerSize',5.8,'MarkerEdgeColor',markerEdge,'MarkerFaceColor',fill,'LineWidth',1.25);
      xlim(ax,limits(:,1)'); ylim(ax,limits(:,2)'); zlim(ax,limits(:,3)');
      daspect(ax,[1 1 1]); camproj(ax,'orthographic');
      view(ax,[32 20]); xlabel(ax,'Local x (mm)'); ylabel(ax,'Local y (mm)'); zlabel(ax,'Local normal (mm)');
    else
      patch(ax,'Vertices',skinSide,'Faces',faces,'FaceColor',[.74 .76 .78],...
        'FaceAlpha',.12,'EdgeColor',[.69 .71 .73],'EdgeAlpha',.55,'LineWidth',.4);
      patch(ax,'Vertices',skinSide,'Faces',receivingFaces,'FaceColor',blue,...
        'FaceAlpha',.36,'EdgeColor',blue,'EdgeAlpha',.65,'LineWidth',.55);
      for group=1:2
        selected=~affected;lineColor=paleOrange;lineWidth=.8;
        if group==2, selected=affected;lineColor=orange;lineWidth=1.5;end
        for dimension=1:2
          edgeCoordinates{dimension}=reshape([stateSide(indexA(selected),dimension),stateSide(indexB(selected),dimension),nan(nnz(selected),1)]',[],1); %#ok<SAGROW>
        end
        plot(ax,edgeCoordinates{1},edgeCoordinates{2},'-','Color',lineColor,'LineWidth',lineWidth);
      end
      markerSize=5.8;if k>4,markerSize=7;end
      plot(ax,stateSide(snapped,1),stateSide(snapped,2),'o','LineStyle','none',...
        'MarkerSize',markerSize,'MarkerEdgeColor',markerEdge,'MarkerFaceColor',fill,'LineWidth',1.25);
      bounds=sideLimits;if k>4,bounds=zoomLimits;end
      xlim(ax,bounds(:,1)');ylim(ax,bounds(:,2)');daspect(ax,[1 1 1]);
      xlabel(ax,'In-plane position h (mm)');ylabel(ax,'Local normal (mm)');
      if k<=4
        rectangle(ax,'Position',[zoomLimits(1,:) diff(zoomLimits,1,1)],'EdgeColor',ink,'LineStyle','--','LineWidth',.8);
      end
    end
    set(ax,'FontSize',10,'Color','none','Box','off','TickDir','out',...
        'XColor',ink,'YColor',ink,'ZColor',ink,'GridColor',[.88 .88 .88]);
    grid(ax,'off');
    title(ax,panelNames{k},'FontSize',14,'FontWeight','bold','Units','normalized','Position',[.5 1.065 0]);
end
legendAx=axes(fig,'Position',[.05 .083 .90 .04],'Visible','off'); hold(legendAx,'on');
h1=plot(legendAx,nan,nan,'-','Color',orange,'LineWidth',1.8);
h2=plot(legendAx,nan,nan,'-','Color',[.64 .66 .68],'LineWidth',.7);
h3=plot(legendAx,nan,nan,'o','Color',markerEdge,'MarkerFaceColor','w','LineWidth',1.3);
h4=plot(legendAx,nan,nan,'o','Color',markerEdge,'MarkerFaceColor',orange,'LineWidth',1.3);
h5=plot(legendAx,nan,nan,'s','Color',[.55 .57 .59],'MarkerFaceColor',blue,'MarkerSize',8);
h6=plot(legendAx,nan,nan,'-','Color',paleOrange,'LineWidth',1.3);
legend(legendAx,[h1 h6 h2 h5 h3 h4],{'60 affected beams','339 unchanged beams','Skin-element edges',...
    'Receiving skin elements','Node before repair','Same node after repair'},...
    'Orientation','horizontal','NumColumns',3,'Location','north','Box','off','FontSize',11);
annotation(fig,'textbox',[.045 .014 .91 .052],'String',...
    {'Identical exported connectivity before and after repair; repositioning retained nodes is not load-induced deformation.',...
     'Overview panels retain all 399 beams. Dashed boxes locate the interface enlargements; lengths are unexaggerated.',...
     'Side direction: h = x cos(5°) + y sin(5°). Other nodes already contact the skin; there is no uniform clearance.',...
     'Data: accompanying node, beam and skin-element CSV files.'},...
    'EdgeColor','none','FontSize',10.5,'Color',ink,'Margin',0,'Interpreter','none');
drawnow;
% Preserve full canvas margins; exportgraphics tight-crops figure annotations.
[~,~,outputExtension] = fileparts(outputPath);
switch lower(outputExtension)
    case '.png'
        print(fig,outputPath,'-dpng','-r180');
    case '.pdf'
        print(fig,outputPath,'-dpdf','-bestfit');
    case '.svg'
        print(fig,outputPath,'-dsvg');
    otherwise
        close(fig);
        error('Output must have a .png, .pdf, or .svg extension.');
end
fprintf('Exported: %s\n',outputPath);
fprintf('Origin_m: %.15g %.15g %.15g\n',origin);
fprintf('Basis columns [horizontal transverse normal]:\n'); disp(basis);
fprintf('Displacement_mm range: %.12g %.12g\n',min(move(snapped))*1000,max(move(snapped))*1000);
fprintf('Affected beams: %d; unchanged beams: %d; moved nodes in enlargement: %d\n',nnz(affected),nnz(~affected),nnz(visibleZoom));
close(fig);
end
