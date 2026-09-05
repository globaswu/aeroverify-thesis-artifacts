function plot_5_1(outputFile)
if nargin < 1, outputFile = fullfile(fileparts(mfilename('fullpath')), 'plot_5_1.png'); end
% Reproduce the completed topology comparison using figure_5_1.csv only.
% No simulation software or external data is required.
% Lines join observed nondominated points as visual guides, not predictions.
folder = fileparts(mfilename('fullpath'));
T = readtable(fullfile(folder, 'figure_5_1.csv'), TextType='string');
Y = [T.Y1_two_wing_mass_kg, T.Y2_two_wing_trim_compliance_Nm];
feasible = T.C_binary_feasible == 1;
familyPF = T.within_topology_observed_pareto == 1;
pooledPF = T.pooled_observed_pareto == 1;
assert(height(T) == 213 && all(isfinite(Y), 'all'));
assert(isequal(observedFront(Y, feasible), pooledPF));
families = ["FCC", "BCC", "SC"];
colors = [23,107,145; 185,120,36; 164,80,120] / 255;
markers = {'o', 's', '^'};
f = figure(Visible='off', Color='w', Units='inches', Position=[1,1,7.2,5.3]);
ax = axes(f, Position=[0.105,0.125,0.87,0.635], FontName='Times New Roman', ...
    FontSize=10, LineWidth=0.7, Box='off', XGrid='on', YGrid='on', GridAlpha=0.15);
hold(ax,'on');
handles = gobjects(6,1);
for k = 1:numel(families)
    group = T.topology == families(k);
    assert(sum(group) == 71);
    assert(isequal(observedFront(Y(group,:),feasible(group)),familyPF(group)));
    mask = group & ~feasible;
    scatter(ax,Y(mask,1),Y(mask,2),26,colors(k,:),markers{k}, ...
        MarkerFaceColor='none',MarkerEdgeAlpha=0.52,LineWidth=0.7,HandleVisibility='off');
    mask = group & feasible;
    scatter(ax,Y(mask,1),Y(mask,2),30,colors(k,:),markers{k}, ...
        'filled',MarkerEdgeColor='w',LineWidth=0.35,HandleVisibility='off');
    P = sortrows(Y(group & familyPF,:),1);
    plot(ax,P(:,1),P(:,2),Color=colors(k,:),LineWidth=1.1,HandleVisibility='off');
    handles(k) = plot(ax,nan,nan,Color=colors(k,:),Marker=markers{k}, ...
        MarkerFaceColor=colors(k,:),MarkerSize=6,LineWidth=1.1);
end
scatter(ax,Y(pooledPF,1),Y(pooledPF,2),82,'o',MarkerFaceColor='none', ...
    MarkerEdgeColor=[0.125,0.125,0.125],LineWidth=0.75,HandleVisibility='off');
handles(4) = plot(ax,nan,nan,'o',Color=[0.33,0.33,0.33],MarkerFaceColor=[0.33,0.33,0.33],LineStyle='none');
handles(5) = plot(ax,nan,nan,'o',Color=[0.47,0.47,0.47],MarkerFaceColor='none',LineStyle='none');
handles(6) = plot(ax,nan,nan,'o',Color=[0.125,0.125,0.125],MarkerFaceColor='none',MarkerSize=9,LineStyle='none');
xlabel(ax,'Two-wing structural mass (kg)',FontSize=11);
ylabel(ax,'Two-wing trim compliance (N \cdot m)',FontSize=11);
xlim(ax,[31,86]); ylim(ax,[42.8,56.4]);
annotation(f,'textbox',[0.1,0.927,0.8,0.065],String='Completed lattice-sizing campaigns', ...
    EdgeColor='none',HorizontalAlignment='center',FontName='Times New Roman',FontSize=13);
annotation(f,'textbox',[0.1,0.883,0.8,0.055],String='71 evaluations per topology; 92 feasible observations', ...
    EdgeColor='none',HorizontalAlignment='center',FontName='Times New Roman',FontSize=10);
leg = legend(ax,handles([1,4,2,5,3,6]),{'FCC','Feasible','BCC','Infeasible','SC','Pooled front'}, ...
    NumColumns=3,Box='off',FontName='Times New Roman',FontSize=9.5);
leg.Units = 'normalized'; leg.Position = [0.2,0.765,0.65,0.115];
for id = ["FCC70", "FCC26", "SC70"]
    i = find(T.design_id == id);
    dx = 0; dy = 0.45; align = 'left';
    if id == "FCC26", dx = -0.5; align = 'right'; end
    if id == "SC70", dx = 0.7; dy = 0.25; end
    text(ax,Y(i,1)+dx,Y(i,2)+dy,id,FontName='Times New Roman',FontSize=9, ...
        HorizontalAlignment=align,BackgroundColor='w',Margin=0.6);
end
exportgraphics(f,outputFile,Resolution=300);
close(f);
fprintf('Saved plot_5_1: %d evaluations, %d feasible, %d pooled-front points.\n',height(T),sum(feasible),sum(pooledPF));

end

function mask = observedFront(Y, eligible)
mask = false(size(eligible));
for i = find(eligible).'
    dominates = eligible & all(Y <= Y(i,:),2) & any(Y < Y(i,:),2);
    mask(i) = ~any(dominates);
end
end
