function plot_5_7(outputFile)
if nargin < 1, outputFile=fullfile(fileparts(mfilename('fullpath')),'plot_5_7.png'); end
T=loadSiblingData('figure_5_7.csv');

xyz=[numericCol(T,'x_m') numericCol(T,'y_m') numericCol(T,'z_m')]; u=[numericCol(T,'ux_mode3') numericCol(T,'uy_mode3') numericCol(T,'uz_mode3')]; mag=numericCol(T,'displacement_magnitude'); def=xyz+u; stride=max(1,ceil(height(T)/160000)); take=1:stride:height(T); ref=take(1:5:end); fig=figure('Visible','off','Color','w','Position',[100 100 1050 760]); tl=tiledlayout(fig,2,2,'Padding','compact','TileSpacing','compact');
ax=nexttile(tl); scatter(ax,xyz(ref,1),xyz(ref,2),1,[.85 .85 .85],'.'); hold(ax,'on'); scatter(ax,def(take,1),def(take,2),2,mag(take),'filled'); axis(ax,'equal'); title(ax,'Top'); xlabel(ax,'x (m)'); ylabel(ax,'y (m)');
ax=nexttile(tl); scatter3(ax,xyz(ref,1),xyz(ref,2),xyz(ref,3),1,[.85 .85 .85],'.'); hold(ax,'on'); scatter3(ax,def(take,1),def(take,2),def(take,3),2,mag(take),'filled'); axis(ax,'equal'); view(ax,-55,22); title(ax,'Oblique'); xlabel(ax,'x (m)'); ylabel(ax,'y (m)'); zlabel(ax,'z (m)');
ax=nexttile(tl); scatter(ax,xyz(ref,1),xyz(ref,3),1,[.85 .85 .85],'.'); hold(ax,'on'); scatter(ax,def(take,1),def(take,3),2,mag(take),'filled'); axis(ax,'equal'); title(ax,'Front'); xlabel(ax,'x (m)'); ylabel(ax,'z (m)');
ax=nexttile(tl); scatter(ax,xyz(ref,2),xyz(ref,3),1,[.85 .85 .85],'.'); hold(ax,'on'); scatter(ax,def(take,2),def(take,3),2,mag(take),'filled'); axis(ax,'equal'); title(ax,'Right'); xlabel(ax,'y (m)'); ylabel(ax,'z (m)'); colormap(fig,'turbo'); colorbar(ax); title(tl,sprintf('FCC case 67 SOL 103 mode 3 (%.6f Hz)',numericSubset(T,'frequency_hz',1))); finishPlot(fig,outputFile);
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
