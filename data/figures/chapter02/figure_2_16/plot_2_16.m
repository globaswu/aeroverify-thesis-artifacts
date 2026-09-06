function plot_2_16(outputPath)
%PLOT_2_16 Reproduce five lift curves and a local CL zoom.
% The only input is the adjacent figure_2_16.csv.
folder=fileparts(mfilename('fullpath'));
if nargin<1 || isempty(outputPath),outputPath=fullfile(folder,'figure_2_16.png');end
data=readtable(fullfile(folder,'figure_2_16.csv'));
alpha=data.alpha_deg;
assert(isequal(alpha,(-4:2:12)'), 'Expected nine verified incidence values.');
assert(all(data.aerodynamic_boxes==5500) && all(abs(data.Mach-.17)<1e-12));
values=[data.CL_dihedral0_on,data.CL_dihedral3_on,data.CL_dihedral0_off,data.CL_dihedral3_off];
assert(all(isfinite(values),'all'));
reference=data.CL_Sivells_TableI_linear_reference;
assert(max(abs(reference-.085*(alpha+1.3)))<1e-12);
deltaOn=data.CL_dihedral3_on-data.CL_dihedral0_on;
deltaOff=data.CL_dihedral3_off-data.CL_dihedral0_off;
assert(max(abs(deltaOn-data.delta_CL_3deg_minus_0deg_ON))<1e-12);
assert(max(abs(deltaOff-data.delta_CL_3deg_minus_0deg_OFF))<1e-12);
blue=[0 .4353 .6392];orange=[.7882 .4157 0];ink=[.1451 .1647 .1882];grey=[.4 .4275 .4588];
oldHeight=7.6;newHeight=9.0;
keepTop=@(y) 1-(1-y)*oldHeight/newHeight;
upperHeight=.485*oldHeight/newHeight;
lowerHeight=.185*oldHeight*1.75/newHeight;
lowerBottom=keepTop(.336)-lowerHeight;
footerY=@(y) lowerBottom-(.151-y)*oldHeight/newHeight;
fig=figure('Visible','off','Color','w','Units','inches','Position',[1 1 8.27 newHeight]);
cleanup=onCleanup(@() close(fig));
canvas=axes(fig,'Position',[0 0 1 1],'Color','none');
xlim(canvas,[0 1]);ylim(canvas,[0 1]);axis(canvas,'off');hold(canvas,'on');
put(canvas,.115,keepTop(.978),'Effect of dihedral and W2GJ on rigid-wing lift',15,ink,'bold');
put(canvas,.115,keepTop(.946),'Four matched rigid DLM cases; Mach 0.17; 5500 aerodynamic boxes',10,grey);
ax=axes(fig,'Position',[.115 keepTop(.405) .845 upperHeight]);hold(ax,'on');
h3on=plot(ax,alpha,data.CL_dihedral3_on,'--o','Color',blue,'LineWidth',1.25, ...
    'MarkerSize',6.7,'MarkerFaceColor','w','MarkerEdgeColor',blue);
h3off=plot(ax,alpha,data.CL_dihedral3_off,'--s','Color',orange,'LineWidth',1.25, ...
    'MarkerSize',6.7,'MarkerFaceColor','w','MarkerEdgeColor',orange);
h0on=plot(ax,alpha,data.CL_dihedral0_on,'-o','Color',blue,'LineWidth',1.25, ...
    'MarkerSize',3.8,'MarkerFaceColor',blue,'MarkerEdgeColor',blue);
h0off=plot(ax,alpha,data.CL_dihedral0_off,'-s','Color',orange,'LineWidth',1.25, ...
    'MarkerSize',3.8,'MarkerFaceColor',orange,'MarkerEdgeColor',orange);
hpaper=plot(ax,alpha,reference,'-.','Color',ink,'LineWidth',1.45);
xlim(ax,[-4.5 12.5]);ylim(ax,[-.42 1.27]);xticks(ax,-4:2:12);yticks(ax,-.4:.2:1.2);
set(ax,'XTickLabel',[]);ylabel(ax,'Lift coefficient C_L');
panelTitle(ax,'A. Lift curves');
legend(ax,[h0on h3on h0off h3off hpaper], ...
    {'dihedral 0° / W2GJ On (optimization convention)','dihedral 3° / W2GJ On', ...
    'dihedral 0° / W2GJ Off','dihedral 3° / W2GJ Off','Sivells Table I reconstruction'}, ...
    'Location','northwest','Box','off','FontName','Times New Roman','FontSize',9.5);
text(ax,.42,.09, ...
    {'Table I line: C_L=0.085(\alpha_{deg}+1.3)', ...
    'Reconstructed from slope and zero-lift angle;', ...
    'not individual measured points.'}, ...
    'Units','normalized','VerticalAlignment','bottom','FontName','Times New Roman', ...
    'FontSize',9,'Color',grey,'Interpreter','tex');

zoom=axes(fig,'Position',[.115 lowerBottom .845 lowerHeight]);hold(zoom,'on');
% Plot the nine original incidences and straight segments, then clip the axes.
hz0=plot(zoom,alpha,data.CL_dihedral0_on,'-o','Color',blue,'MarkerSize',4.2, ...
    'MarkerFaceColor',blue,'MarkerEdgeColor',blue,'LineWidth',1.4);
hz3=plot(zoom,alpha,data.CL_dihedral3_on,'--o','Color',blue,'MarkerSize',6.7, ...
    'MarkerFaceColor','w','MarkerEdgeColor',blue,'LineWidth',1.4);
xlim(zoom,[11.985 12.003]);ylim(zoom,[1.1494 1.1523]);
xticks(zoom,[11.985 11.990 11.995 12.000]);
yticks(zoom,[1.1495 1.1500 1.1505 1.1510 1.1515 1.1520]);
zoom.XAxis.Exponent=0;zoom.YAxis.Exponent=0;
xtickformat(zoom,'%.3f');ytickformat(zoom,'%.4f');
xlabel(zoom,'Incidence \alpha (deg)');ylabel(zoom,'Lift coefficient C_L');
panelTitle(zoom,'B. W2GJ on: local lift-curve zoom near 12°');
legend(zoom,[hz0 hz3],{'dihedral 0° / W2GJ On','dihedral 3° / W2GJ On'}, ...
    'Location','northwest','Box','off','FontName','Times New Roman','FontSize',9.5, ...
    'AutoUpdate','off');
endpoint0=data.CL_dihedral0_on(alpha==12);endpoint3=data.CL_dihedral3_on(alpha==12);
text(zoom,11.994,1.15212,sprintf('dihedral 0°: C_L=%.6f',endpoint0), ...
    'FontName','Times New Roman','FontSize',9.5,'Color',blue,'VerticalAlignment','middle');
plot(zoom,[11.9994 12],[1.15210 endpoint0],'Color',blue,'LineWidth',.8);
text(zoom,11.994,1.15030,sprintf('dihedral 3°: C_L=%.6f',endpoint3), ...
    'FontName','Times New Roman','FontSize',9.5,'Color',blue,'VerticalAlignment','middle');
plot(zoom,[11.9994 12],[1.15040 endpoint3],'Color',blue,'LineWidth',.8);
text(zoom,.42,.035,{'Connectors join calculated incidences;', ...
    'no additional points are computed in this zoom.'}, ...
    'Units','normalized','FontName','Times New Roman','FontSize',8.8, ...
    'Color',grey,'VerticalAlignment','bottom','Interpreter','none');
set([ax zoom],'FontName','Times New Roman','FontSize',10,'Box','off', ...
    'XGrid','on','YGrid','on','GridColor',[.86 .88 .895],'GridAlpha',1,'LineWidth',.65);
put(canvas,.115,footerY(.074),'Fit statistics use −2° ≤ α ≤ 8°; all nine computed incidences are displayed.',8.8,grey);
put(canvas,.115,footerY(.044), ...
    'All numerical curves are rigid benchmarks using the same historical 600-point airfoil. The 0° case follows',8.6,ink);
put(canvas,.115,footerY(.024), ...
    'the optimization geometry/camber convention; these are not full flexible-optimization results.',8.6,ink);
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
use=alpha>=-2 & alpha<=8;
assert(nnz(use)==6);
fields=["CL_dihedral0_on","CL_dihedral3_on","CL_dihedral0_off","CL_dihedral3_off"];
for k=1:numel(fields)
    y=data.(fields(k));
    fitted=polyfit(alpha(use),y(use),1);
    rmse=sqrt(mean((y(use)-reference(use)).^2));
    fprintf('%s: fit -2..8 deg; slope=%.12g/deg; fitted alpha0=%.12g deg; reference RMSE=%.12g\n', ...
        fields(k),fitted(1),-fitted(2)/fitted(1),rmse);
end
end

function put(ax,x,y,value,fontSize,color,weight)
if nargin<7,weight='normal';end
text(ax,x,y,value,'FontName','Times New Roman','FontSize',fontSize,'Color',color, ...
    'FontWeight',weight,'VerticalAlignment','middle','Interpreter','none','Clipping','off');
end

function panelTitle(ax,value)
text(ax,0,1.04,value,'Units','normalized','FontName','Times New Roman', ...
    'FontSize',11,'FontWeight','bold','VerticalAlignment','bottom', ...
    'Interpreter','tex','Clipping','off');
end
