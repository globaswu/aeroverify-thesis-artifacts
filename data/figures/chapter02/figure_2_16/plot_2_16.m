function plot_2_16(outputPath)
%PLOT_2_16 Reproduce the full box-detail diagram from one CSV.
folder = fileparts(mfilename('fullpath'));
if nargin<1 || isempty(outputPath)
    outputPath = fullfile(folder,'figure_2_16.png');
end
data = readtable(fullfile(folder,'figure_2_16.csv'));
controls = data(data.box_j_zero_based>=0,:);
selected = controls(controls.box_j_zero_based>=35 & controls.box_j_zero_based<=39,:);
assert(height(data)==4001 && height(controls)==50 && height(selected)==5);
assert(max(abs(controls.control_x_over_c-(controls.box_j_zero_based+.75)/50))<1e-12);
assert(max(abs(controls.control_W2GJ+controls.control_dzc_dx))<1e-12);
assert(max(abs(data.z_camber_over_c-.5*(data.z_upper_over_c+data.z_lower_over_c)))<1e-12);
assert(max(abs(selected.control_W2GJ+selected.control_dzc_dx))<1e-12);
N=50; M=110;
ink=[.145 .165 .188]; grey=[.408 .439 .475];
blue=[0 .435 .639]; gold=[.725 .510 0]; pale=[1 .953 .824];
fig=figure('Visible','off','Color','w','Units','inches','Position',[1 1 8.27 10.4]);
cleanup=onCleanup(@() close(fig));
canvas=axes(fig,'Position',[0 0 1 1],'Color','none');
xlim(canvas,[0 1]);ylim(canvas,[0 1]);axis(canvas,'off');hold(canvas,'on');
put(canvas,.075,.977,'W2GJ at individual aerodynamic-box control points',15,ink,'bold');
put(canvas,.075,.950,'NACA 65-210 mean-camber input to a planar lifting surface',10,grey);

grid=axes(fig,'Position',[.075 .655 .325 .325*8.27/10.4]);hold(grid,'on');
plot(grid,repmat((0:N)/N,2,1),[zeros(1,N+1);ones(1,N+1)], ...
    'Color',[.76 .8 .82],'LineWidth',.28);
plot(grid,[zeros(1,M+1);ones(1,M+1)],repmat((0:M)/M,2,1), ...
    'Color',[.76 .8 .82],'LineWidth',.28);
patch(grid,[.7 .8 .8 .7],[0 0 1 1],pale,'FaceAlpha',.7,'EdgeColor',gold,'LineWidth',.8);
for j=35:39
    rectangle(grid,'Position',[j/N 55/M 1/N 1/M], ...
        'FaceColor',gold,'EdgeColor','w','LineWidth',.4);
end
plot(grid,[.32 .75],[.75 .51],'Color',gold,'LineWidth',1.1);
text(grid,.10,.78,'five adjacent chord panels','FontName','Times New Roman', ...
    'FontSize',8.5,'Color',ink,'BackgroundColor','w');
xlim(grid,[0 1]);ylim(grid,[0 1]);axis(grid,'square');
xticks(grid,0:.2:1);yticks(grid,[0 .5 1]);
xlabel(grid,'Local chord coordinate \xi=x/c');
ylabel(grid,'Normalized span coordinate \eta=y/s');
panelTitle(grid,'A. Planar aerodynamic-box grid');
put(canvas,.445,.899,'$M=N_{\mathrm{span}}=110$',12,ink);
put(canvas,.445,.873,'$N=N_{\mathrm{chord}}=50$',12,ink);
put(canvas,.445,.836,'50 chordwise values repeat',9,ink);
put(canvas,.445,.818,'across 110 spanwise strips.',9,ink);
put(canvas,.445,.800,'Chordwise index varies fastest.',9,ink);
put(canvas,.445,.769,'Planar CAERO1 surface: z=0',9,grey);
put(canvas,.445,.751,'Grid shown in local coordinates.',9,grey);
put(canvas,.445,.718,'For every box $j=0,\ldots,N-1$:',9,ink);
put(canvas,.445,.676,'$\xi_j^*=\frac{j+0.75}{N}$',12,ink);
put(canvas,.445,.624, ...
    '$\mathrm{W2GJ}_j=-\left.\frac{\mathrm{d}\zeta_c}{\mathrm{d}\xi}\right|_{\xi_j^*}$',12,ink);

mask=data.x_over_c>=.7 & data.x_over_c<=.8;
x=data.x_over_c(mask);zu=data.z_upper_over_c(mask);
zl=data.z_lower_over_c(mask);zc=data.z_camber_over_c(mask);
xs=selected.control_x_over_c; zs=selected.control_z_camber_over_c;
slopes=selected.control_dzc_dx;
ax=axes(fig,'Position',[.075 .313 .405 .255]);hold(ax,'on');
patch(ax,[x;flipud(x)],[zu;flipud(zl)],[.929 .945 .953],'EdgeColor','none');
plot(ax,x,zu,'Color',ink,'LineWidth',1.1);plot(ax,x,zl,'Color',ink,'LineWidth',1.1);
plot(ax,x,zc,'--','Color',gold,'LineWidth',1.2);
plot(ax,[.7 .8],[0 0],'Color',blue,'LineWidth',1);
for j=35:40, xline(ax,j/N,':','Color',[.65 .68 .70],'LineWidth',.6); end
for k=1:5
    plot(ax,[xs(k) xs(k)],[0 zs(k)],':','Color',gold,'LineWidth',.8);
    d=[-.007 .007];plot(ax,xs(k)+d,zs(k)+slopes(k)*d,'Color',gold,'LineWidth',1.5);
end
scatter(ax,xs,zeros(5,1),20,blue,'filled');
scatter(ax,xs,zs,22,'w','filled','MarkerEdgeColor',gold);
xlim(ax,[.7 .8]);ylim(ax,[-.03 .05]);daspect(ax,[1 1 1]);
xticks(ax,.7:.02:.8);yticks(ax,[-.02 0 .02 .04]);
xlabel(ax,'\xi=x/c');ylabel(ax,'\zeta=z/c');
panelTitle(ax,{'B. Source section and control locations', ...
    'Equal chordwise/vertical geometric scales'});
text(ax,.703,.034,'upper surface','FontSize',8,'Color',grey,'FontName','Times New Roman');
text(ax,.703,-.028,'lower surface','FontSize',8,'Color',grey,'FontName','Times New Roman');
text(ax,.703,.003,'planar control points','FontSize',8,'Color',blue,'FontName','Times New Roman');
for j=35:39
    text(ax,(j+.5)/N,.047,sprintf('j=%d',j),'HorizontalAlignment','center', ...
        'FontSize',7.7,'Color',ink,'FontName','Times New Roman');
end

detailPos=[.575 .355 .375 .185];
detail=axes(fig,'Position',detailPos);hold(detail,'on');
for j=35:40,xline(detail,j/N,':','Color',[.65 .68 .70],'LineWidth',.6);end
plot(detail,x,zc,'--','Color',gold,'LineWidth',1.1);
for k=1:5
    d=[-.0075 .0075];plot(detail,xs(k)+d,zs(k)+slopes(k)*d,'Color',gold,'LineWidth',1.9);
    text(detail,xs(k),zs(k)+.00012,sprintf('%d',selected.box_j_zero_based(k)), ...
        'HorizontalAlignment','center','FontSize',8,'Color',ink,'FontName','Times New Roman');
end
scatter(detail,xs,zs,24,'w','filled','MarkerEdgeColor',gold);
xlim(detail,[.7 .8]);ylim(detail,[.00865 .01035]);
xticks(detail,.7:.02:.8);yticks(detail,[.009 .0095 .01]);
detail.YAxis.Exponent=0;ytickformat(detail,'%.4f');
xlabel(detail,'\xi=x/c');ylabel(detail,'Mean camber \zeta_c=z_c/c');
magnification=(detailPos(4)*10.4/(.01035-.00865))/(detailPos(3)*8.27/.1);
panelTitle(detail,{'C. Mean-camber tangents', ...
    sprintf('Vertical scale magnified x%.1f',magnification)});
put(canvas,.575,.297,'Open circles: mean-camber samples',8.3,grey);
put(canvas,.575,.282,'Solid gold segments: local tangents',8.3,grey);
put(canvas,.575,.267,'Blue circles in B: planar application points',8.3,grey);
put(canvas,.075,.260, ...
    '$\zeta_c=(\zeta_{\mathrm{upper}}+\zeta_{\mathrm{lower}})/2;\quad\mathrm{d}\zeta_c/\mathrm{d}\xi=\mathrm{d}z_c/\mathrm{d}x.$',10,ink);
put(canvas,.075,.238,'Calculated values for the five selected chordwise boxes',10,ink,'bold');

tableAx=axes(fig,'Position',[.075 .111 .875 .117]);
hold(tableAx,'on');axis(tableAx,'off');xlim(tableAx,[0 1]);ylim(tableAx,[0 1]);
patch(tableAx,[0 1 1 0],[.75 .75 1 1],[.945 .957 .961],'EdgeColor','none');
for y=0:.25:1,plot(tableAx,[0 1],[y y],'Color',[.82 .84 .86],'LineWidth',.6);end
edges=[0 .25 .40 .55 .70 .85 1];
for e=edges,plot(tableAx,[e e],[0 1],'Color',[.82 .84 .86],'LineWidth',.6);end
names={'Box index $j$','Control $\xi_j^*$','Slope $\mathrm{d}z_c/\mathrm{d}x$','$\mathrm{W2GJ}_j$'};
for r=1:4
    put(tableAx,.02,1-(r-.5)*.25,names{r},9,ink);
    for k=1:5
        if r==1,v=sprintf('%d',selected.box_j_zero_based(k));
        elseif r==2,v=sprintf('%.3f',xs(k));
        elseif r==3,v=sprintf('%+.7f',slopes(k));
        else,v=sprintf('%+.7f',selected.control_W2GJ(k));end
        if r==4,color=blue;else,color=ink;end
        text(tableAx,(edges(k+1)+edges(k+2))/2,1-(r-.5)*.25,v, ...
            'FontName','Times New Roman','FontSize',9,'Color',color, ...
            'HorizontalAlignment','center','VerticalAlignment','middle');
    end
end
put(canvas,.075,.070, ...
    'Mean camber supplies a normal-flow boundary-condition correction; it does not deform the planar surface.',8.7,ink);
put(canvas,.075,.044, ...
    'These box control points are separate from the quarter-chord lifting line and its ten spanwise stations.',8.7,grey);
set([grid ax detail],'FontName','Times New Roman','FontSize',9,'Box','off');
drawnow;
[outputFolder,~,extension]=fileparts(outputPath);
if ~isempty(outputFolder) && ~isfolder(outputFolder),mkdir(outputFolder);end
if strcmpi(extension,'.pdf')
    exportgraphics(fig,outputPath,'ContentType','vector','BackgroundColor','white');
else
    set(fig,'PaperPositionMode','auto','InvertHardcopy','off');
    print(fig,outputPath,'-dpng','-r400');
end
disp(outputPath)
end

function put(ax,x,y,value,fontSize,color,weight)
if nargin<7,weight='normal';end
if contains(value,'$'),interpreter='latex';else,interpreter='none';end
text(ax,x,y,value,'FontName','Times New Roman','FontSize',fontSize,'Color',color, ...
    'FontWeight',weight,'VerticalAlignment','middle','Interpreter',interpreter,'Clipping','off');
end

function panelTitle(ax,value)
text(ax,0,1.055,value,'Units','normalized','FontName','Times New Roman', ...
    'FontSize',9.5,'FontWeight','bold','VerticalAlignment','bottom', ...
    'Interpreter','none','Clipping','off');
end
