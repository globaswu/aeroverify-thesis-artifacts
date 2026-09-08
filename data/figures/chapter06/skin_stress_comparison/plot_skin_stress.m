function plot_skin_stress(outputFile)
% Reconstruct the original skin triangles using only adjacent source CSVs.
% Add this folder to the path; plot_skin_stress('/output/skin_stress.png').
% The displayed element value is max of both original centroid surfaces.
% No nodal averaging, interpolation or geometry smoothing is performed.
if nargin < 1
    outputFile = fullfile(pwd, 'skin_stress_surface.png');
end
bundle = fileparts(mfilename('fullpath'));
cases = readtable(fullfile(bundle, 'cases.csv'), 'TextType', 'string', ...
    'VariableNamingRule', 'preserve');
assert(isequal(cases.case(:).', [37 99]));
vertexFiles = {'case_37_vertices.csv', 'case_99_vertices.csv'};
triangleFiles = {'case_37_triangles.csv', 'case_99_triangles.csv'};
colors = [.055 .13 .28; .10 .32 .51; .24 .52 .62; .61 .70 .60; .94 .82 .34];
cmap = interp1(linspace(0,1,5), colors, linspace(0,1,256), 'linear');
az = deg2rad(-60); el = deg2rad(40);
viewDirection = [cos(el)*cos(az), cos(el)*sin(az), sin(el)];
rightDirection = [-sin(az), cos(az), 0];
upDirection = cross(viewDirection, rightDirection);
basis = [rightDirection(:), upDirection(:), viewDirection(:)];
wholeMin = [-.035 -.04 -.055]; wholeMax = [1.025 2.56 .075];
rootOffsetMin = [-.028 -.002 -.008]; rootOffsetMax = [.028 .018 .008];
figureHandle = figure('Visible', 'off', 'Color', 'w', 'Units', 'inches', ...
    'Position', [1 1 7.48 6.40], 'Renderer', 'opengl');
positions = [.035 .515 .43 .355; .52 .515 .43 .355; ...
    .035 .17 .43 .25; .52 .17 .43 .25];
axesHandles = gobjects(4,1);
for panel = 1:4
    axesHandles(panel) = axes(figureHandle, 'Position', positions(panel,:), ...
        'FontName', 'Times New Roman', 'FontSize', 10, 'Projection', 'orthographic');
    hold(axesHandles(panel), 'on');
    colormap(axesHandles(panel), cmap); clim(axesHandles(panel), [0 220]);
end
for caseIndex = 1:2
    caseNumber = cases.case(caseIndex);
    fprintf('Reading and rendering case %d\n', caseNumber);
    rawVertices = readmatrix(fullfile(bundle, vertexFiles{caseIndex}));
    rawFaces = readmatrix(fullfile(bundle, triangleFiles{caseIndex}));
    nodeIds = rawVertices(:,1); vertices = rawVertices(:,2:4);
    elementIds = rawFaces(:,1);
    assert(all(diff(nodeIds)>0) && all(diff(elementIds)>0));
    [found, faces] = ismember(rawFaces(:,2:4), nodeIds);
    assert(all(found, 'all'));
    surfaces = single(rawFaces(:,5:6));
    values = max(surfaces, [], 2);
    assert(all(isfinite(vertices), 'all') && all(isfinite(values)));
    assert(min(values)>=0 && max(values)<=220e6);
    assert(size(vertices,1)==cases.vertices(caseIndex));
    assert(size(faces,1)==cases.triangles(caseIndex));
    [peakValue, peakIndex] = max(values);
    peak = mean(vertices(faces(peakIndex,:),:), 1);
    expectedPeaks = [99785296 210424352]; expectedElements = [35161 675562];
    assert(double(peakValue)==expectedPeaks(caseIndex));
    assert(elementIds(peakIndex)==expectedElements(caseIndex));
    projected = vertices * basis;
    peakProjected = peak * basis;
    rootMin = peak + rootOffsetMin;
    rootMax = peak + rootOffsetMax;
    renderSurface(axesHandles(caseIndex), projected, faces, values, ...
        peakProjected, wholeMin, wholeMax, basis, false);
    points = reshape(vertices(faces(:),:), size(faces,1), 3, 3);
    triangleMin = squeeze(min(points, [], 2));
    triangleMax = squeeze(max(points, [], 2));
    keep = all(triangleMax>=rootMin,2) & all(triangleMin<=rootMax,2);
    renderSurface(axesHandles(caseIndex+2), projected, faces(keep,:), values(keep), ...
        peakProjected, rootMin, rootMax, basis, true);
    panelLetters = 'abcd';
    title(axesHandles(caseIndex), sprintf('(%s) Case %d: overview', ...
        panelLetters(caseIndex), caseNumber), 'FontName', 'Times New Roman', ...
        'FontWeight', 'normal', 'FontSize', 11);
    title(axesHandles(caseIndex+2), sprintf('(%s) Case %d: peak-root vicinity', ...
        panelLetters(caseIndex+2), caseNumber), 'FontName', 'Times New Roman', ...
        'FontWeight', 'normal', 'FontSize', 11);
    annotation(figureHandle, 'textbox', [positions(caseIndex+2,1) .132 .43 .028], ...
        'String', sprintf('Raw maximum %.3f MPa; element %d', ...
        double(peakValue)/1e6, elementIds(peakIndex)), 'EdgeColor', 'none', ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
        'FontName', 'Times New Roman', 'FontSize', 9);
    fprintf('Case %d: maximum %.9g Pa, element %d, centroid [%.12g %.12g %.12g] m\n', ...
        caseNumber, double(peakValue), elementIds(peakIndex), peak);
    clear rawVertices rawFaces points triangleMin triangleMax
end
colorHandle = colorbar(axesHandles(4), 'southoutside');
colorHandle.Position = [.215 .092 .58 .023];
colorHandle.Ticks = [0 55 110 165 220];
colorHandle.FontName = 'Times New Roman'; colorHandle.FontSize = 9;
colorHandle.Label.String = 'Shell von Mises surface envelope [MPa]';
colorHandle.Label.FontName = 'Times New Roman'; colorHandle.Label.FontSize = 10;
for panel = 1:4
    axesHandles(panel).Position = positions(panel,:);
end
annotation(figureHandle, 'textbox', [.05 .947 .9 .042], ...
    'String', 'Skin stress at nominal \alpha = 12\circ', 'Interpreter', 'tex', ...
    'EdgeColor', 'none', 'HorizontalAlignment', 'center', ...
    'FontName', 'Times New Roman', 'FontSize', 13);
annotation(figureHandle, 'textbox', [.05 .913 .9 .033], ...
    'String', 'SOL 144 subcase 9; stored ANGLEA = 0.20944 rad', ...
    'EdgeColor', 'none', 'HorizontalAlignment', 'center', ...
    'FontName', 'Times New Roman', 'FontSize', 9);
annotation(figureHandle, 'textbox', [.025 .012 .95 .028], ...
    'String', 'Actual undeformed triangles; maximum of two centroid surfaces; no nodal averaging.', ...
    'EdgeColor', 'none', 'HorizontalAlignment', 'center', ...
    'FontName', 'Times New Roman', 'FontSize', 8.7);
drawnow;
set(figureHandle, 'PaperPositionMode', 'auto');
print(figureHandle, outputFile, '-dpng', '-r500');
close(figureHandle);
fprintf('Saved %s\n', outputFile);
end

function renderSurface(ax, projected, faces, values, peak, low, high, basis, zoom)
patch(ax, 'Faces', faces, 'Vertices', projected, ...
    'FaceVertexCData', double(values)/1e6, 'FaceColor', 'flat', ...
    'EdgeColor', 'none', 'FaceLighting', 'none', 'CDataMapping', 'scaled');
[x,y,z] = ndgrid([low(1) high(1)], [low(2) high(2)], [low(3) high(3)]);
corners = [x(:),y(:),z(:)] * basis;
padding = .03; scaleLength = .5; scaleLabel = '0.5 m';
if zoom
    padding = .002; scaleLength = .01; scaleLabel = '10 mm';
end
limitsLow = min(corners(:,1:2), [], 1)-padding;
limitsHigh = max(corners(:,1:2), [], 1)+padding;
view(ax, 2); axis(ax, 'equal'); axis(ax, 'off');
xlim(ax, [limitsLow(1) limitsHigh(1)]);
ylim(ax, [limitsLow(2) limitsHigh(2)]);
zlim(ax, [min(projected(:,3))-.01, max(projected(:,3))+.1]);
overlayDepth = max(projected(:,3))+.05;
line(ax, peak(1), peak(2), overlayDepth, 'LineStyle', 'none', ...
    'Marker', 'o', 'MarkerSize', 6, 'MarkerFaceColor', 'none', ...
    'Color', 'w', 'LineWidth', 2);
line(ax, peak(1), peak(2), overlayDepth+.001, 'LineStyle', 'none', ...
    'Marker', 'o', 'MarkerSize', 6, 'MarkerFaceColor', 'none', ...
    'Color', [.15 .15 .15], 'LineWidth', .65);
start = limitsLow+[.05 .065].*(limitsHigh-limitsLow);
line(ax, [start(1) start(1)+scaleLength], [start(2) start(2)], ...
    [overlayDepth overlayDepth], 'Color', [.15 .15 .15], 'LineWidth', 1.3);
text(ax, start(1)+scaleLength/2, start(2)-.035*(limitsHigh(2)-limitsLow(2)), ...
    overlayDepth, scaleLabel, 'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'top', 'FontName', 'Times New Roman', 'FontSize', 8.5);
end
