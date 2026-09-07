function outputPath = plot_2_4(outputPath,savePanels)
%PLOT_2_4 Reproduce the eight-panel atlas using figure_2_4.csv only.
% Optional outputPath selects PNG/PDF/SVG. Optional savePanels=true also
% writes separate a-d/e-h PNGs beside that output. Default: one atlas PNG.
% Thick orange = lattice beam centre-lines; thin grey = skin-element edges;
% blue = receiving facets. Dashed proposals are not retained mesh members.
out=fileparts(mfilename('fullpath'));
if nargin<1 || isempty(outputPath),outputPath=fullfile(out,'figure_2_4.png');end
if nargin<2,savePanels=false;end
outputPath=char(outputPath);
[outputFolder,outputStem,extension]=fileparts(outputPath);
if ~any(strcmpi(extension,{'.png','.pdf','.svg'}))
    error('plot_2_4:OutputFormat','Output must use PNG, PDF or SVG.');
end
if ~isempty(outputFolder) && ~isfolder(outputFolder),mkdir(outputFolder);end
data=readtable(fullfile(out,'figure_2_4.csv'),'TextType','string');
panelA=upper_panels(data);
panelB=lower_panels(data);
% Render native figures directly to arrays: no panel image is an input and
% the atlas neither stretches coordinates nor changes any panel's scale.
imageA=print(panelA,'-RGBImage','-r220');
imageB=print(panelB,'-RGBImage','-r220');
close(panelA);close(panelB);
width=max(size(imageA,2),size(imageB,2));
height=size(imageA,1)+size(imageB,1);
atlas=uint8(255*ones(height,width,3));
atlas(1:size(imageA,1),1:size(imageA,2),:)=imageA;
atlas(size(imageA,1)+(1:size(imageB,1)),1:size(imageB,2),:)=imageB;
if strcmpi(extension,'.png')
    imwrite(atlas,outputPath);
else
    fig=figure('Visible','off','Color','w','Units','pixels', ...
        'Position',[80 80 width/2 height/2]);
    ax=axes(fig,'Position',[0 0 1 1]);image(ax,atlas);axis(ax,'image');axis(ax,'off');
    set(fig,'PaperUnits','inches','PaperPosition',[0 0 width/220 height/220], ...
        'PaperSize',[width/220 height/220]);
    if strcmpi(extension,'.pdf'),device='-dpdf';else,device='-dsvg';end
    print(fig,outputPath,device,'-r220');close(fig);
end
if savePanels
    imwrite(imageA,fullfile(outputFolder,[outputStem 'a.png']));
    imwrite(imageB,fullfile(outputFolder,[outputStem 'b.png']));
end
fprintf('Rendered eight panels to %s from one CSV.\n',outputPath);
end

function fig = upper_panels(data)
% Static scientific figure contract: two actual classification examples.
% Top: original/final single-B repair; bottom: rejected proposal/final mesh.
% Equal metric side-view scales, real neighboring skin facets; no magnification.
% Orange beam centre-lines, grey skin edges, blue actual receiving facets.
% A rejected proposal uses dashed orange lines and a cross, not a solid beam.
% Node and shell-vertex rows come from the single accompanying CSV file.
[nodes,shells]=upper_tables(data);
orange=[.78 .38 .12];blue=[.19 .39 .62];grey=[.53 .56 .59];ink=[.17 .19 .21];
fig=figure('Visible','off','Color','w','Position',[80 80 1400 680]);
set(fig,'DefaultAxesFontName','Arial','DefaultTextFontName','Arial');
names=["single_B_A_ordinary_C_beyond","B_rejected_length"];
titles={'(a) Single-node repair: original','(b) Single-node repair: final', ...
    '(c) Length guard: proposed correction','(d) Length guard: retained mesh'};
for row=1:2
    n=nodes(nodes.example==names(row),:);s=shells(shells.example==names(row),:);
    n=n([find(n.role=="A"),find(n.role=="B"),find(n.role=="C")],:);
    old=[n.original_x_m,n.original_y_m,n.original_z_m];
    final=[n.final_x_m,n.final_y_m,n.final_z_m];
    proposal=[n.all_proposals_x_m,n.all_proposals_y_m,n.all_proposals_z_m];
    p=[n.projection_x_m(2),n.projection_y_m(2),n.projection_z_m(2)];
    st=s(s.shell_element_id==n.selected_shell_element_id(2),:);
    v=[st.x_m,st.y_m,st.z_m];normal=cross(v(2,:)-v(1,:),v(3,:)-v(1,:));normal=normal/norm(normal);
    if dot(p-old(2,:),normal)<0,normal=-normal;end
    x=old(3,:)-old(1,:);x=x-dot(x,normal)*normal;x=x/norm(x);
    basis=[x(:),normal(:)];
    originalQ=(old-p)*basis*1000;finalQ=(final-p)*basis*1000;proposedQ=(proposal-p)*basis*1000;
    % Keep the one-ring facets, but bound the view around the shown beam chain.
    xmin=min(originalQ(:,1))-.75;xmax=max(originalQ(:,1))+.75;
    ymin=min(originalQ(:,2))-.7;ymax=.85;
    for col=1:2
        panel=(row-1)*2+col;
        ax=axes(fig,'Position',[.055+.475*(col-1),.56-.45*(row-1),.40,.30]);hold(ax,'on');
        accepted=n.category=="within_mpc_tolerance" | n.category=="snapped_to_shell_projection";
        receiving=unique(n.selected_shell_element_id(accepted));
        for eid=unique(s.shell_element_id).'
            tri=s(s.shell_element_id==eid,:);v=([tri.x_m,tri.y_m,tri.z_m]-p)*basis*1000;
            color=grey;width=.55;
            if ismember(eid,receiving),color=blue;width=1.4;end
            patch(ax,'Vertices',v,'Faces',[1 2 3],'FaceColor','none','EdgeColor',color,'LineWidth',width);
        end
        if row==1 && col==1,q=originalQ;style='-';labelB='B';
        elseif row==2 && col==1,q=proposedQ;style='--';labelB='B*';
        else,q=finalQ;style='-';labelB='B';if row==1,labelB='B''';end;end
        plot(ax,q(:,1),q(:,2),style,'Color',orange,'LineWidth',3);
        plot(ax,q([1 3],1),q([1 3],2),'o','MarkerFaceColor',ink,'MarkerEdgeColor','w','MarkerSize',7);
        marker='o';fill='w';if row==1 && col==2,fill=orange;end
        if row==2 && col==1,marker='x';end
        plot(ax,q(2,1),q(2,2),marker,'Color',orange,'MarkerEdgeColor',orange,'MarkerFaceColor',fill,'MarkerSize',9,'LineWidth',1.6);
        text(ax,q(1,1)-.3,q(1,2)-.22,'A','FontSize',12,'FontWeight','bold','Color',ink);
        text(ax,q(3,1)+.10,q(3,2)-.10,'C','FontSize',12,'FontWeight','bold','Color',ink);
        text(ax,q(2,1)-.1,q(2,2)-.35,labelB,'FontSize',12,'FontWeight','bold','Color',orange);
        axis(ax,'equal');xlim(ax,[xmin xmax]);ylim(ax,[ymin ymax]);set(ax,'Visible','off');
        title(ax,titles{panel},'Visible','on','FontSize',13,'FontWeight','normal');
        plot(ax,[xmin+.15,xmin+1.15],[ymin+.2,ymin+.2],'-','Color',ink,'LineWidth',1);
        text(ax,xmin+.65,ymin-.03,'1 mm','FontSize',9,'HorizontalAlignment','center');
    end
end
annotation(fig,'textbox',[.055 .462 .90 .042],'String', ...
    'B moves 1.701 mm; A is coupled without movement; C is outside repair reach (3.402 > 3.064 mm).', ...
    'LineStyle','none','FontSize',11,'Interpreter','none');
annotation(fig,'textbox',[.055 .02 .90 .042],'String', ...
    'B* is a rejected proposal: AB would lengthen by 81.9%, exceeding the 75% guard. B stays unchanged.', ...
    'LineStyle','none','FontSize',11,'Interpreter','none');
set(fig,'PaperPositionMode','auto');


end

function fig = lower_panels(data)
% Chart contract: show two distinct, observed near-skin coupling outcomes.
% Upper row: both adjacent lattice nodes relocate to their own skin facets.
% Lower row: an 8.189 micrometre gap remains when ordinary MPC coupling is
% permitted. The lower row is a uniformly magnified, cropped local side view.
% Reproduction requires only figure_2_4.csv, not a solver or archive.
% Explicit data-class encoding: thin grey skin edges, blue receiving facets,
% thick orange beam centre-lines. Open/filled markers denote original/final.
d=lower_table(data);
blue=[.19 .39 .62];orange=[.78 .38 .12];ink=[.17 .19 .21];grey=[.56 .60 .63];
fig=figure('Visible','off','Color','w','Position',[80 80 1400 730]);
set(fig,'DefaultAxesFontName','Arial','DefaultTextFontName','Arial');
u=d(d.example=="two_node",:);
target=u(u.entity=="receiving_vertex" & u.element_id==448671,:);
p=xyz(u(u.entity=="projection" & u.grid_id==491572,:));
a=xyz(u(u.entity=="beam_endpoint" & u.grid_id==491584 & u.state=="original",:));
c=xyz(u(u.entity=="beam_endpoint" & u.grid_id==491564 & u.state=="original",:));
v=xyz(target);n=cross(v(2,:)-v(1,:),v(3,:)-v(1,:));n=n/norm(n);
b=unique(xyz(u(u.entity=="beam_endpoint" & u.grid_id==491572 & u.state=="original",:)),'rows');
if dot(p-b,n)<0,n=-n;end
t=c-a;t=t-dot(t,n)*n;t=t/norm(t);s=cross(n,t);basis=[t(:),s(:),n(:)];
assert(norm(basis.'*basis-eye(3),'fro')<1e-12);
tr=@(rows) (xyz(rows)-p)*basis*1000;
all=tr(u);xlimTop=[min(all(:,1))-.3,max(all(:,1))+.3];
ylimTop=[min(all(:,2))-.2,max(all(:,2))+.2];zlimTop=[-3.15,.5];
% Upper row: oblique rendering of true mesh coordinates.
for panel=1:2
    ax=axes(fig,'Position',[.045+(panel-1)*.5 .555 .41 .37]);hold(ax,'on');
    state="original";if panel==2,state="final";end
    for eid=unique(u.element_id(u.entity=="context_vertex")).'
        q=tr(u(u.entity=="context_vertex" & u.element_id==eid,:));
        patch(ax,'Vertices',q,'Faces',[1 2 3],'FaceColor',[.86 .88 .90], ...
            'FaceAlpha',.10,'EdgeColor',grey,'LineWidth',.7);
    end
    for eid=[448671 449087]
        q=tr(u(u.entity=="receiving_vertex" & u.element_id==eid,:));
        patch(ax,'Vertices',q,'Faces',[1 2 3],'FaceColor',blue,'FaceAlpha',.22, ...
            'EdgeColor',blue,'LineWidth',1.2);
        centre=mean(q,1);name='T_B';dz=.30;if eid==449087,name='T_C';dz=-.60;end
        text(ax,centre(1),centre(2),centre(3)+dz,name, ...
            'Color',blue,'FontSize',12,'HorizontalAlignment','center','Tag','facet_label');
    end
    for eid=[829120 829109]
        q=tr(u(u.entity=="beam_endpoint" & u.element_id==eid & u.state==state,:));
        plot3(ax,q(:,1),q(:,2),q(:,3),'-','Color',orange,'LineWidth',3.2);
    end
    for gid=[491584 491572 491564]
        q=unique(tr(u(u.entity=="beam_endpoint" & u.grid_id==gid & u.state==state,:)),'rows');
        fill=ink;if gid~=491584,fill='w';if panel==2,fill=orange;end,end
        marker='o';if gid==491564,marker='d';end
        plot3(ax,q(1),q(2),q(3),marker,'MarkerFaceColor',fill,'MarkerEdgeColor',orange,'MarkerSize',8,'LineWidth',1.5);
        name='A';if gid==491572,name='B';elseif gid==491564,name='C';end
        if panel==2 && gid~=491584,name=[name ''''];end
        dz=.20;if gid==491572 && panel==2,dz=-.40;end
        if gid==491564 && panel==1,dz=-.2;end
        text(ax,q(1)+.08,q(2),q(3)+dz,name,'Color',ink,'FontSize',14,'FontWeight','bold');
    end
    if panel==1
        q=tr(u(u.entity=="projection",:));
        plot3(ax,q(:,1),q(:,2),q(:,3),'x','Color',blue,'MarkerSize',7,'LineWidth',1.2);
    end
    axis(ax,'equal');xlim(ax,xlimTop);ylim(ax,ylimTop);zlim(ax,zlimTop);
    view(ax,[10 25]);camproj(ax,'orthographic');camzoom(ax,1.25);set(ax,'Visible','off','Clipping','off');
    sx=-2.4;sy=0;sz=-2.7;
    plot3(ax,[sx sx+1],[sy sy],[sz sz],'-','Color',ink,'LineWidth',1.2);
    text(ax,sx+.5,sy,sz-.27,'1 mm','Color',ink,'FontSize',10,'HorizontalAlignment','center');
    if panel==1,heading='(e) Two adjacent nodes: before repair';else,heading='(f) Both nodes moved to their receiving facets';end
    note(fig,[.095+(panel-1)*.5 .948 .40 .04],heading,14,false,ink);
end
note(fig,[.055 .485 .89 .043], ...
    'B correction: 1.298 mm; C correction: 2.597 mm. Two receiving triangles are highlighted; their shared edge remains.',12,true,ink);
% Lower row: exact orthographic side coordinates in micrometres. Uniform
% zoom, equal length scales and beam clipping make the tiny offset visible.
u=d(d.example=="finite_offset",:);
p=xyz(u(u.entity=="projection",:));
b=unique(xyz(u(u.entity=="beam_endpoint" & u.grid_id==472299 & u.state=="original",:)),'rows');
v=xyz(u(u.entity=="receiving_vertex",:));
n=cross(v(2,:)-v(1,:),v(3,:)-v(1,:));n=n/norm(n);if dot(p-b,n)<0,n=-n;end
endrows=u(u.entity=="beam_endpoint" & u.grid_id~=472299 & u.state=="original",:);
w=xyz(endrows);t=w(2,:)-w(1,:);t=t-dot(t,n)*n;t=t/norm(t);
tr=@(rows) (xyz(rows)-p)*[t(:),n(:)]*1e6;
assert(abs(norm((b-p)*1e6)-8.1891470257)<1e-6);
for panel=1:2
    ax=axes(fig,'Position',[.070+(panel-1)*.5 .105 .365 .295]);hold(ax,'on');
    state="original";if panel==2,state="final";end
    % All receiving vertices project to n=0 in this true side view. Its
    % boundary appears as a line, not as a structural beam.
    q=tr(u(u.entity=="receiving_vertex",:));
    plot(ax,q([1:3 1],1),q([1:3 1],2),'-','Color',blue,'LineWidth',1.5);
    for eid=unique(u.element_id(u.entity=="beam_endpoint")).'
        q=tr(u(u.entity=="beam_endpoint" & u.element_id==eid & u.state==state,:));
        plot(ax,q(:,1),q(:,2),'-','Color',orange,'LineWidth',3.2);
    end
    q=unique(tr(u(u.entity=="beam_endpoint" & u.grid_id==472299 & u.state==state,:)),'rows');
    plot(ax,q(1),q(2),'o','MarkerFaceColor','w','MarkerEdgeColor',orange,'MarkerSize',8,'LineWidth',1.5);
    plot(ax,0,0,'x','Color',blue,'MarkerSize',8,'LineWidth',1.3);
    text(ax,-3.2,-9,'Q','Color',ink,'FontSize',14,'FontWeight','bold');
    text(ax,1.0,1.6,'Projection p','Color',blue,'FontSize',11);
    text(ax,-21,3.7,'Receiving skin element, edge-on','Color',blue,'FontSize',11);
    text(ax,4.0,-5.8,'Gap: 8.189 μm','Color',ink,'FontSize',11);
    % Dimension line intentionally omitted: the separated markers and label
    % show the gap without drawing anything that could be mistaken for a beam.
    axis(ax,'equal');xlim(ax,[-23 23]);ylim(ax,[-15 7]);
    plot(ax,[-21 -16],[-13 -13],'-','Color',ink,'LineWidth',1.3);
    text(ax,-18.5,-14.6,'5 μm','HorizontalAlignment','center','Color',ink,'FontSize',10);
    set(ax,'Visible','off','Clipping','on');
    if panel==1,heading='(g) Near-skin node before coupling';else,heading='(h) Ordinary MPC: coordinates unchanged';end
    title(ax,heading,'Visible','on','FontSize',14,'FontWeight','normal','Color',ink);
end
note(fig,[.055 .020 .89 .047], ...
    'Uniform side-view close-up: the 8.189 μm gap is below the 10 μm coupling tolerance. Beam segments are cropped.',11,false,ink);
set(findall(fig,'-property','Interpreter'),'Interpreter','none');
set(findall(fig,'Tag','facet_label'),'Interpreter','tex');
set(fig,'PaperPositionMode','auto');

end

function q=xyz(rows)
q=[rows.x_m rows.y_m rows.z_m];
end

function note(fig,pos,message,size,bold,color)
weight='normal';if bold,weight='bold';end
annotation(fig,'textbox',pos,'String',message,'FontName','Arial','FontSize',size, ...
    'FontWeight',weight,'Color',color,'EdgeColor','none','Interpreter','none');
end


function [nodes,shells]=upper_tables(data)
names=["single_B_A_ordinary_C_beyond","B_rejected_length"];
nodes=data(data.entity=="node" & data.state=="original" & ismember(data.example,names),:);
nodes.category=nodes.classification;
nodes.selected_shell_element_id=nodes.element_id;
for state=["original","final","projection","all_proposals"]
    coords=zeros(height(nodes),3);
    for i=1:height(nodes)
        q=data(data.entity=="node" & data.example==nodes.example(i) & ...
            data.grid_id==nodes.grid_id(i) & data.state==state,:);
        assert(height(q)==1);
        coords(i,:)=[q.x_m q.y_m q.z_m];
    end
    for k=1:3
        letters="xyz";letter=extractBetween(letters,k,k);
        nodes.(char(state+"_"+letter+"_m"))=coords(:,k);
    end
end
shells=data(data.entity=="skin_vertex" & ismember(data.example,names),:);
shells.shell_element_id=shells.element_id;
end

function d=lower_table(data)
keep=ismember(data.example,["two_node","finite_offset"]);
keep=keep & (data.entity=="beam_endpoint" | data.entity=="skin_vertex" | ...
    (data.entity=="node" & data.state=="projection"));
d=data(keep,:);
receiving=d.entity=="skin_vertex" & ~ismissing(d.receiving_for) & strlength(d.receiving_for)>0;
context=d.entity=="skin_vertex" & ~receiving;
d.entity(receiving)="receiving_vertex";
d.entity(context)="context_vertex";
d.entity(d.entity=="node")="projection";
end
