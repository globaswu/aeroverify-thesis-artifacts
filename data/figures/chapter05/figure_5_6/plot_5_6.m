function plot_5_6(outputFile)
if nargin < 1, outputFile=fullfile(fileparts(mfilename('fullpath')),'plot_5_6.png'); end
T=loadSiblingData('figure_5_6.csv');

x=numericCol(T,'velocity_mps'); [x,ord]=sort(x); old=numericCol(T,'four_point_damping_g'); new=numericCol(T,'eighteen_point_damping_g'); fig=figure('Visible','off','Color','w'); ax=axes(fig); plot(ax,x,old(ord),'--','Color',[.6 .6 .6],'LineWidth',1.4,'DisplayName','Four-value MKAERO1'); hold(ax,'on'); plot(ax,x,new(ord),'-','Color',[.75 .08 .12],'LineWidth',1.5,'DisplayName','Revised 18-value MKAERO1'); yline(ax,0,':'); xlabel(ax,'Velocity (m/s)'); ylabel(ax,'Damping, g'); title(ax,'FCC case 67 point-3 MKAERO1 sensitivity'); legend(ax); finishPlot(fig,outputFile);
end

function T = loadSiblingData(csvName)
here = fileparts(mfilename('fullpath'));
T = readtable(fullfile(here, csvName), 'VariableNamingRule', 'preserve');
end
function v = numericCol(T, name)
x = T.(name);
if isnumeric(x) || islogical(x)
    v = double(x);
else
    v = str2double(string(x));
end
v = v(:);
end
function v = numericSubset(T, name, index)
v = numericCol(T,name); v = v(index);
end
function s = textCol(T, name)
s = string(T.(name)); s = s(:);
end
function tf = logicalCol(T, name)
x = T.(name);
if islogical(x)
    tf = x;
elseif isnumeric(x)
    tf = x ~= 0;
else
    tf = ismember(lower(strtrim(string(x))), ["1","true","yes"]);
end
tf = tf(:);
end
function [xv, yv, Z] = gridData(T, xName, yName, zName)
x = numericCol(T,xName); y = numericCol(T,yName); z = numericCol(T,zName);
valid = isfinite(x) & isfinite(y) & isfinite(z); x=x(valid); y=y(valid); z=z(valid);
xv = unique(x,'sorted'); yv = unique(y,'sorted');
[~,ix] = ismember(x,xv); [~,iy] = ismember(y,yv);
Z = nan(numel(yv),numel(xv)); Z(sub2ind(size(Z),iy,ix)) = z;
end
function plotObservations(ax,x,y,feasible)
scatter(ax,x(~feasible),y(~feasible),28,[0.70 0.09 0.17],'x','LineWidth',1.0,'DisplayName','Infeasible'); hold(ax,'on');
scatter(ax,x(feasible),y(feasible),30,'o','MarkerFaceColor','w','MarkerEdgeColor',[0.09 0.41 0.67],'LineWidth',0.9,'DisplayName','Feasible');
end
function plotPareto(ax,T,xName,yName,feasName,pfName,caseName)
x=numericCol(T,xName); y=numericCol(T,yName); feasible=logicalCol(T,feasName); pf=logicalCol(T,pfName);
plotObservations(ax,x,y,feasible); [sx,ord]=sort(x(pf)); sy=y(pf); sy=sy(ord); plot(ax,sx,sy,'-','Color',[0.13 0.13 0.13],'LineWidth',0.9,'HandleVisibility','off');
scatter(ax,x(pf),y(pf),36,[0.13 0.13 0.13],'filled','DisplayName','Observed Pareto');
cases=numericCol(T,caseName); ids=find(pf); for k=1:numel(ids), text(ax,x(ids(k)),y(ids(k)),sprintf(' %d',round(cases(ids(k)))),'FontSize',7); end
end
function h = plotScore(ax,G,P,xName,yName,scoreName,pxName,pyName,feasName,pfName)
[xv,yv,Z]=gridData(G,xName,yName,scoreName); h=imagesc(ax,xv,yv,Z); set(ax,'YDir','normal'); hold(ax,'on');
if min(Z,[],'all','omitnan') <= 0.5 && max(Z,[],'all','omitnan') >= 0.5, contour(ax,xv,yv,Z,[0.5 0.5],'w','LineWidth',1.0); end
xp=numericCol(P,pxName); yp=numericCol(P,pyName); feasible=logicalCol(P,feasName); pf=logicalCol(P,pfName); plotObservations(ax,xp,yp,feasible); scatter(ax,xp(pf),yp(pf),55,'o','MarkerFaceColor','none','MarkerEdgeColor',[0.13 0.13 0.13],'LineWidth',1.1,'DisplayName','Observed Pareto'); axis(ax,'square');
end
function finishPlot(fig, outputFile)
folder=fileparts(outputFile); if ~isempty(folder) && ~isfolder(folder), mkdir(folder); end
exportgraphics(fig,outputFile,'Resolution',180,'BackgroundColor','white'); close(fig);
end
