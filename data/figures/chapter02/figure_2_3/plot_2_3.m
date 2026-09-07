function outputPath = plot_2_3(outputPath)
%PLOT_2_3 Original 1.002 mm coordinate repair, all receiving skin facets.
% Requires only figure_2_3.csv. No solver, archive, or external data dependency.
% Contract: preserve true oblique/side coordinates and equal scales, reveal
% the turning skin closure at C, distinguish thin skin edges from thick beams.
out=fileparts(mfilename('fullpath'));
if nargin<1 || isempty(outputPath),outputPath=fullfile(out,'figure_2_3.png');end
outputPath=char(outputPath);
[outputFolder,~,extension]=fileparts(outputPath);
if ~any(strcmpi(extension,{'.png','.pdf','.svg'}))
    error('plot_2_3:OutputFormat','Output must use PNG, PDF or SVG.');
end
if ~isempty(outputFolder) && ~isfolder(outputFolder),mkdir(outputFolder);end
d=readtable(fullfile(out,'figure_2_3.csv'),'TextType','string');
v=xyz(d(d.entity=="receiving_vertex" & d.receiver=="B",:));
a=xyz(d(d.entity=="beam_node" & d.receiver=="A" & d.state=="original",:));
b=xyz(d(d.entity=="beam_node" & d.receiver=="B" & d.state=="original",:));
c=xyz(d(d.entity=="beam_node" & d.receiver=="C" & d.state=="original",:));
p=xyz(d(d.entity=="projection" & d.receiver=="B",:));
n=cross(v(2,:)-v(1,:),v(3,:)-v(1,:));n=n/norm(n);if dot(p-b,n)<0,n=-n;end
t=c-a;t=t-dot(t,n)*n;t=t/norm(t);s=cross(n,t);basis=[t(:),s(:),n(:)];
assert(norm(basis.'*basis-eye(3),'fro')<1e-12);
tr=@(rows) (xyz(rows)-p)*basis*1000;
q=tr(d);xl=[min(q(:,1))-.7,max(q(:,1))+.9];
yl=[min(q(:,2))-.3,max(q(:,2))+.3];zl=[min(q(:,3))-.7,max(q(:,3))+.7];
blue=[.19 .39 .62];orange=[.78 .38 .12];ink=[.17 .19 .21];grey=[.50 .55 .59];
fig=figure('Visible','off','Color','w','Position',[80 80 1400 1030]);
set(fig,'DefaultAxesFontName','Arial','DefaultTextFontName','Arial');
note(fig,[.045 .950 .91 .042],'Single-node repair at the skin mesh',22,true,ink);
note(fig,[.045 .902 .91 .038], ...
    'A and C are already close to their respective skin facets. Only B is relocated; all three receiving facets are shown.',12,false,ink);
headings={'(a) Oblique view - before repair','(b) Oblique view - after repair', ...
    '(c) Side view - before repair','(d) Side view - after repair'};
positions=[.035 .520 .445 .33;.525 .520 .445 .33;.035 .238 .445 .22;.525 .238 .445 .22];
for panel=1:4
    before=mod(panel,2)==1;side=panel>2;
    state="original";if ~before,state="final";end
    ax=axes(fig,'Position',positions(panel,:));hold(ax,'on');
    for entity=["context_vertex","receiving_vertex"]
        for eid=unique(d.element_id(d.entity==entity)).'
            tri=d(d.entity==entity & d.element_id==eid,:);verts=tr(tri);
            if side,verts=verts(:,[1 3]);end
            edge=grey;face=[.86 .88 .90];alpha=.10;width=.75;
            if entity=="receiving_vertex",edge=blue;face=blue;alpha=.23;width=1.35;end
            patch(ax,'Vertices',verts,'Faces',[1 2 3],'FaceColor',face,'FaceAlpha',alpha,'EdgeColor',edge,'LineWidth',width);
        end
    end
    for eid=[936457 936828]
        verts=tr(d(d.entity=="beam_endpoint" & d.element_id==eid & d.state==state,:));
        if side
            plot(ax,verts(:,1),verts(:,3),'-','Color',orange,'LineWidth',3.4);
        else
            plot3(ax,verts(:,1),verts(:,2),verts(:,3),'-','Color',orange,'LineWidth',3.4);
        end
    end
    for name=["A","B","C"]
        node=tr(d(d.entity=="beam_node" & d.receiver==name & d.state==state,:));
        fill=ink;edge=ink;sz=8;
        if name=="B",fill='w';edge=orange;sz=10;if ~before,fill=orange;end,end
        label=char(name);if name=="B" && ~before,label=['B' char(8242)];end
        offset=[-.25 0 .28];
        if name=="B",offset=[-.12 0 -.40];elseif name=="C",offset=[.32 0 -.05];end
        if name=="C" && side,offset(1)=.62;end
        if name=="B" && ~before && ~side,offset(3)=-.70;end
        if side
            plot(ax,node(1),node(3),'o','MarkerFaceColor',fill,'MarkerEdgeColor',edge,'MarkerSize',sz,'LineWidth',1.6);
            text(ax,node(1)+offset(1),node(3)+offset(3),label,'Color',ink,'FontSize',14,'FontWeight','bold');
        else
            plot3(ax,node(1),node(2),node(3),'o','MarkerFaceColor',fill,'MarkerEdgeColor',edge,'MarkerSize',sz,'LineWidth',1.6);
            text(ax,node(1)+offset(1),node(2),node(3)+offset(3),label,'Color',ink,'FontSize',14,'FontWeight','bold');
        end
    end
    if side
        if before
            plot(ax,0,0,'x','Color',blue,'MarkerSize',8,'LineWidth',1.3);
            text(ax,-.35,.25,'Projection of B','Color',blue,'FontSize',10);
        end
        % Actual closure facet projects downward from the upper skin at C.
        closure=tr(d(d.entity=="receiving_vertex" & d.receiver=="C",:));
        k=mean(closure,1);
        text(ax,k(1)+.9,k(3)+.45,'Skin closure','Color',blue,'FontSize',11);
        upper=tr(d(d.entity=="receiving_vertex" & d.receiver=="A",:));
        k=mean(upper,1);
        text(ax,k(1)-2.0,k(3)+.42,'Upper skin','Color',blue,'FontSize',11);
        axis(ax,'equal');xlim(ax,xl);ylim(ax,zl);
        sx=xl(1)+.25;sz=zl(1)+.25;
        plot(ax,[sx sx+1],[sz sz],'-','Color',ink,'LineWidth',1.3);
        text(ax,sx+.5,sz-.25,'1 mm','Color',ink,'FontSize',10,'HorizontalAlignment','center');
    else
        axis(ax,'equal');xlim(ax,xl);ylim(ax,yl);zlim(ax,zl);
        view(ax,[10 28]);camproj(ax,'orthographic');
    end
    set(ax,'Visible','off','Clipping','off');
    title(ax,headings{panel},'Visible','on','FontSize',14,'FontWeight','normal','Color',ink);
end
annotation(fig,'line',[.065 .105],[.180 .180],'Color',grey,'LineWidth',.9);
note(fig,[.111 .163 .27 .034],'Skin-element edges',11,false,ink);
annotation(fig,'line',[.380 .420],[.180 .180],'Color',orange,'LineWidth',3.4);
note(fig,[.426 .163 .27 .034],'Beam centre-lines',11,false,ink);
annotation(fig,'rectangle',[.725 .170 .025 .021],'FaceColor',blue*.25+.75,'EdgeColor',blue,'LineWidth',1.1);
note(fig,[.757 .163 .23 .034],'Receiving skin elements',11,false,ink);
note(fig,[.045 .109 .91 .036], ...
    'B coordinate correction: 1.002 mm. A and C retain their coordinates and are MPC-coupled to the skin.',12,true,ink);
note(fig,[.045 .061 .91 .034], ...
    'C is close to the turning closure facet, not far from the skin. Equal length scales; no added beam or load-induced deformation.',10,false,ink);
note(fig,[.045 .023 .91 .030], ...
    'Source data: accompanying CSV. All shown skin triangles form one edge-connected patch; blue facets receive A, B and C.',9,false,grey);
set(findall(fig,'-property','Interpreter'),'Interpreter','none');
set(fig,'PaperPositionMode','auto');
switch lower(extension)
    case '.png',print(fig,outputPath,'-dpng','-r220');
    case '.pdf'
        set(fig,'PaperUnits','inches');paper=get(fig,'PaperPosition');
        set(fig,'PaperSize',paper(3:4),'PaperPosition',[0 0 paper(3:4)]);
        print(fig,outputPath,'-dpdf','-r220');
    case '.svg',print(fig,outputPath,'-dsvg','-r220');
end
close(fig);
fprintf('Rendered 3 receiving facets and an edge-connected surrounding skin patch from CSV only.\n');
end

function q=xyz(rows)
q=[rows.x_m rows.y_m rows.z_m];
end
function note(fig,pos,message,size,bold,color)
weight='normal';if bold,weight='bold';end
annotation(fig,'textbox',pos,'String',message,'FontName','Arial','FontSize',size, ...
    'FontWeight',weight,'Color',color,'EdgeColor','none','Interpreter','none');
end
