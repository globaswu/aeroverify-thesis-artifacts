function plot_5_21(outputFile)
if nargin < 1, outputFile=fullfile(fileparts(mfilename('fullpath')),'plot_5_21.png'); end
T=loadSiblingData('figure_5_21.csv');

O=T(textCol(T,'record_type')=="observed",:); R=T(textCol(T,'record_type')=="reference",:); feasible=logicalCol(O,'Feasible'); pf=logicalCol(O,'Pareto'); fig=figure('Visible','off','Color','w','Position',[100 100 720 1000]); tl=tiledlayout(fig,3,1,'Padding','compact','TileSpacing','compact'); ax=nexttile(tl); scatter(ax,numericSubset(O,'TaperRatio',feasible),1000*numericSubset(O,'CDitrim',feasible),34,numericSubset(O,'AR',feasible),'filled'); hold(ax,'on'); scatter(ax,numericSubset(O,'TaperRatio',~feasible),1000*numericSubset(O,'CDitrim',~feasible),30,'x','MarkerEdgeColor',[.6 .6 .6]); scatter(ax,numericSubset(O,'TaperRatio',pf),1000*numericSubset(O,'CDitrim',pf),65,'o','MarkerFaceColor','none','MarkerEdgeColor','k'); xlabel(ax,'Taper ratio'); ylabel(ax,'1000 C_{D_i,trim}');
ax=nexttile(tl); ar=numericCol(R,'AR'); taper=numericCol(R,'TaperRatio'); for value=[6 9 12], m=abs(ar-value)<1e-12; [x,ord]=sort(taper(m)); y=numericCol(R,'RigidSpanEfficiency'); y=y(m); plot(ax,x,y(ord),'LineWidth',1.1,'DisplayName',sprintf('Rigid LLT, AR=%g',value)); hold(ax,'on'); end; scatter(ax,numericSubset(O,'TaperRatio',feasible),numericSubset(O,'TorsionCorrectedE',feasible),28,numericSubset(O,'AR',feasible),'filled'); scatter(ax,numericSubset(O,'TaperRatio',~feasible),numericSubset(O,'TorsionCorrectedE',~feasible),28,'x','MarkerEdgeColor',[.6 .6 .6]); xlabel(ax,'Taper ratio'); ylabel(ax,'Span efficiency'); legend(ax,'Location','best');
ax=nexttile(tl); ut=unique(taper); lo=nan(size(ut)); hi=lo; pen=numericCol(R,'TaperOnlyCDiPenaltyPct'); for i=1:numel(ut), vals=pen(abs(taper-ut(i))<1e-12); lo(i)=min(vals); hi(i)=max(vals); end; fill(ax,[ut;flipud(ut)],[lo;flipud(hi)],[.85 .92 .97],'EdgeColor','none','DisplayName','Rigid LLT envelope'); hold(ax,'on'); m=abs(ar-9)<1e-12; [x,ord]=sort(taper(m)); y=pen(m); plot(ax,x,y(ord),'LineWidth',1.2,'DisplayName','Rigid LLT, AR=9'); scatter(ax,numericSubset(O,'TaperRatio',feasible),numericSubset(O,'TaperOnlyCDiPenaltyPct',feasible),28,numericSubset(O,'AR',feasible),'filled'); scatter(ax,numericSubset(O,'TaperRatio',~feasible),numericSubset(O,'TaperOnlyCDiPenaltyPct',~feasible),28,'x','MarkerEdgeColor',[.6 .6 .6]); xlabel(ax,'Taper ratio'); ylabel(ax,'Taper-only C_{D_i} penalty (%)'); legend(ax,'Location','best'); colormap(fig,'parula'); title(tl,'Taper-ratio theory and observed-result consistency checks'); finishPlot(fig,outputFile);
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
