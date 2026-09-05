function plot_2_4(outputPath)
%PLOT_2_4 Reproduce the complete schematic from the adjacent coordinate CSV.
% The section outline is data; the planform and angles are illustrative.
plotDir = fileparts(mfilename('fullpath'));
if nargin < 1 || isempty(outputPath)
    outputPath = fullfile(plotDir,'figure_2_4.png');
end
data = readmatrix(fullfile(plotDir,'figure_2_4.csv'));
assert(size(data,2)==2 && size(data,1)>=6 && all(isfinite(data),'all'), ...
    'Expected finite ordered x_over_c,z_over_c coordinates.');
assert(abs(min(data(:,1)))<1e-12 && abs(max(data(:,1))-1)<1e-12, ...
    'Section coordinates must span x/c=0 to x/c=1.');
ink = [0.12 0.14 0.16]; grey = [0.42 0.45 0.48];
lightGrey = [0.73 0.76 0.78]; blue = [0 0.45 0.70];
gold = [0.90 0.62 0]; fillColor = [0.90 0.94 0.96];
paleGold = [0.99 0.96 0.86];
fig = figure('Visible','off','Color','w','Units','inches', ...
    'Position',[1 1 7.09 5.90]);
cleanup = onCleanup(@() close(fig));
axA = axes(fig,'Position',[0.035 0.5290 0.95 0.4360]);
hold(axA,'on'); xlim(axA,[-1.17 1.10]); ylim(axA,[-0.79 0.43]);
axis(axA,'off');
set(axA,'FontName','Times New Roman','FontSize',9.4);
span = linspace(-1,1,501);
chord = 0.28+0.34*(1-abs(span));
le = 0.25*chord; te = -0.75*chord;
patch(axA,[span fliplr(span)],[le fliplr(te)],fillColor, ...
    'EdgeColor',ink,'LineWidth',1.25);
plot(axA,[-1 1],[0 0],'--','Color',grey,'LineWidth',1);
plot(axA,[0 0],[-0.49 0.18],':','Color',grey,'LineWidth',0.9);
N = 10; phi = (1:N)*pi/(2*N+1); stations = cos(phi);
for side = [-1 1]
    stationY = side*stations;
    stationChord = 0.28+0.34*(1-abs(stationY));
    if side>0, stationColor=blue; else, stationColor=lightGrey; end
    for k = 1:N
        plot(axA,[stationY(k) stationY(k)], ...
            [-0.75 0.25]*stationChord(k),'Color', ...
            0.46*stationColor+0.54*[1 1 1],'LineWidth',0.55);
    end
    if side>0
        scatter(axA,stationY,zeros(1,N),18,blue,'filled', ...
            'MarkerEdgeColor','w','LineWidth',0.4);
    else
        scatter(axA,stationY,zeros(1,N),16,'w','filled', ...
            'MarkerEdgeColor',lightGrey,'LineWidth',0.8);
    end
end
highlightY = stations(6); highlightChord = 0.28+0.34*(1-highlightY);
drawArrow(fig,axA,[highlightY,-0.75*highlightChord], ...
    [highlightY,0.25*highlightChord],gold,1.7,true);
label(axA,highlightY+0.045,-0.18,'$c_i=c(y_i)$',ink,9.4,'left');
drawArrow(fig,axA,[-1.10,0.20],[-1.10,-0.31],ink,1,false);
label(axA,-1.10,0.24,'$V_\infty$',ink,9.4,'center');
label(axA,-0.98,0.06,'quarter-chord lifting line',grey,8.2,'left');
text(axA,0.025,0.17,'root plane','Color',grey,'FontName','Times New Roman', ...
    'FontSize',8,'Rotation',90,'VerticalAlignment','top');
dimY = -0.56;
plot(axA,[0 1],[dimY dimY],'Color',ink,'LineWidth',0.8);
plot(axA,[0 0],dimY+[-0.035 0.035],'Color',ink,'LineWidth',0.8);
plot(axA,[1 1],dimY+[-0.035 0.035],'Color',ink,'LineWidth',0.8);
label(axA,0.50,dimY-0.075,'$s=b/2$',ink,9.4,'center');
label(axA,0.50,-0.715, ...
    '$\phi_i=i\pi/(2N+1),\quad y_i=s\cos\phi_i,\quad i=1,\ldots,N,\quad N=10$', ...
    ink,8.5,'center');
label(axA,0.55,0.34, ...
    'filled: implemented half-span stations; open: symmetry mirror',blue,7.9,'center');
panelTitle(axA,'A. Cosine-spaced planform collocation');

axB = axes(fig,'Position',[0.035 0.2055 0.95 0.2883]);
hold(axB,'on'); xlim(axB,[-0.38 2.16]);
halfRange = 0.5*2.54*(0.2883*5.90)/(0.95*7.09);
ylim(axB,0.03+[-halfRange halfRange]);
set(axB,'DataAspectRatio',[1 1 1]); axis(axB,'off');
set(axB,'FontName','Times New Roman','FontSize',9.4);
alphaGlobal = 11; alphaEffective = 6;
angleEffective = deg2rad(alphaEffective);
R = [cos(angleEffective),-sin(angleEffective); ...
    sin(angleEffective),cos(angleEffective)];
section = data; section(:,1)=section(:,1)-0.25; section=section*R';
patch(axB,section(:,1),section(:,2),fillColor, ...
    'EdgeColor',ink,'LineWidth',1.2);
localLine = [-0.25 0;0.75 0]*R';
plot(axB,localLine(:,1),localLine(:,2),'Color',blue,'LineWidth',1.1);
globalEnd = 0.72*[cosd(alphaGlobal),sind(alphaGlobal)];
plot(axB,[0 globalEnd(1)],[0 globalEnd(2)],'--','Color',grey,'LineWidth',1);
drawArrow(fig,axB,[-0.32,-0.12],[0.84,-0.12],ink,1,false);
label(axB,-0.30,-0.18,'$V_\infty$',ink,9.4,'left');
t = linspace(0,deg2rad(alphaGlobal),60);
plot(axB,0.31*cos(t),0.31*sin(t),'Color',grey,'LineWidth',1);
t = linspace(0,angleEffective,60);
plot(axB,0.21*cos(t),0.21*sin(t),'Color',blue,'LineWidth',1.2);
plot(axB,[0.30 0.27],[0.045 0.17],'Color',grey,'LineWidth',0.7);
label(axB,0.23,0.19,'$\alpha_{\mathrm{global}}$',grey,8.5,'left');
plot(axB,[0.205 0.205],[0.011 -0.045],'Color',blue,'LineWidth',0.7);
label(axB,0.18,-0.075,'$\alpha_{\mathrm{eff},i}$',blue,8.5,'left');
drawArrow(fig,axB,[0.64 0.245],[0.53 0.10],gold,0.9,false);
label(axB,0.66,0.28,'$s_\theta\theta_i$',gold,9.4,'center');
text(axB,1.47,0.045, ...
    '$\alpha_{\mathrm{eff},i}=\alpha_{\mathrm{global}}+s_\theta\theta(y_i),\quad s_\theta=-1$', ...
    'Interpreter','latex','HorizontalAlignment','center', ...
    'VerticalAlignment','middle','FontSize',9.2,'Color',ink, ...
    'BackgroundColor',paleGold,'EdgeColor',gold,'Margin',4,'LineWidth',0.8);
label(axB,1.47,-0.105, ...
    {'The section input is torsion-corrected; induced effects are resolved', ...
    'by the Fourier lifting-line system.'},grey,8.2,'center');
label(axB,0.25,-0.30, ...
    'NACA 65-210 from coordinate file; angles illustrative',grey,7.1,'center');
panelTitle(axB,'B. One-way torsion correction at station i');

flowPosition = [0.035 0.025 0.95 0.1407];
flowBox(fig,flowPosition,0.015,0.28, ...
    {'Station inputs: $c_i$, $a_0$, $\alpha_{L=0}$', ...
    'and $\alpha_{\mathrm{eff},i}$'},ink,fillColor);
flowBox(fig,flowPosition,0.36,0.28, ...
    {'Solve the $N=10$ odd Fourier system', ...
    'for coefficients $A_n$'},ink,[0.96 0.97 0.98]);
flowBox(fig,flowPosition,0.705,0.28, ...
    {'Integrated outputs: $C_L$, $C_{D_i}$', ...
    'and span efficiency $e$'},ink,paleGold);
for pair = [0.295 0.64;0.36 0.705]
    annotation(fig,'arrow',flowPosition(1)+flowPosition(3)* ...
        [pair(1)+0.008 pair(2)-0.008], ...
        repmat(flowPosition(2)+0.5*flowPosition(4),1,2), ...
        'Color',blue,'LineWidth',1.2,'HeadLength',6,'HeadWidth',6);
end
drawnow;
[outputFolder,~,extension] = fileparts(outputPath);
if ~isempty(outputFolder) && ~isfolder(outputFolder), mkdir(outputFolder); end
if strcmpi(extension,'.pdf')
    exportgraphics(fig,outputPath,'ContentType','vector','BackgroundColor','white');
else
    set(fig,'PaperPositionMode','auto','InvertHardcopy','off');
    print(fig,outputPath,'-dpng','-r300');
end
disp(outputPath)
end

function label(ax,x,y,value,color,fontSize,alignment)
useLatex = ischar(value) && contains(value,'$');
if useLatex, interpreter='latex'; else, interpreter='none'; end
text(ax,x,y,value,'Color',color,'FontName','Times New Roman', ...
    'FontSize',fontSize,'HorizontalAlignment',alignment, ...
    'VerticalAlignment','middle','Interpreter',interpreter,'Clipping','off');
end

function panelTitle(ax,value)
text(ax,0,1.00,value,'Units','normalized','FontName','Times New Roman', ...
    'FontSize',9.6,'FontWeight','bold','VerticalAlignment','bottom', ...
    'HorizontalAlignment','left','Interpreter','none','Clipping','off');
end

function drawArrow(fig,ax,startPoint,endPoint,color,width,doubleHead)
position = ax.Position; limitsX=ax.XLim; limitsY=ax.YLim;
xx=position(1)+position(3)*([startPoint(1),endPoint(1)]-limitsX(1))/diff(limitsX);
yy=position(2)+position(4)*([startPoint(2),endPoint(2)]-limitsY(1))/diff(limitsY);
if doubleHead
    annotation(fig,'doublearrow',xx,yy,'Color',color,'LineWidth',width, ...
        'Head1Length',5,'Head1Width',5,'Head2Length',5,'Head2Width',5);
else
    annotation(fig,'arrow',xx,yy,'Color',color,'LineWidth',width, ...
        'HeadLength',5,'HeadWidth',5);
end
end

function flowBox(fig,position,x,width,value,ink,fillColor)
boxPosition = [position(1)+position(3)*x,position(2)+0.2*position(4), ...
    position(3)*width,position(4)*0.6];
annotation(fig,'textbox',boxPosition,'String',value,'Interpreter','latex', ...
    'FontSize',8.4,'Color',ink,'BackgroundColor',fillColor, ...
    'EdgeColor',ink,'LineWidth',0.9,'HorizontalAlignment','center', ...
    'VerticalAlignment','middle','FitBoxToText','off','Margin',2);
end
