function outputPath = compose_figure(outputPath, savePanels)
%COMPOSE_FIGURE Build an atlas from adjacent layout.csv and adjacent PNG assets.
%   compose_figure() writes composed.png beside this function.
%   compose_figure('chosen.png', true) also writes each canvas to chosen_panels/.
%   Chosen output extensions: .png, .pdf, .svg. PDF/SVG embed the raster atlas.
%   Requires base MATLAB with its bundled JVM; no nTop, MAT, or helper files.
%
% Figure contract: compare the supplied nTop case/view screenshots using the
% labels, calibrated bars and colors in layout.csv. No geometry is generated.
% Coordinates are zero-based top-left image EDGES in pixels. Each image uses
% the declared isotropic scale, with no extra cropping. Canvas groups retain
% their declared dimensions and are stacked in first-appearance order, left
% aligned on white, without gaps or stretching. Inspect the exported atlas.

packageDir = fileparts(mfilename('fullpath'));
if nargin < 1 || isempty(outputPath)
    outputPath = fullfile(packageDir, 'composed.png');
end
if nargin < 2
    savePanels = false;
end
if ~isscalar(savePanels) || ~(islogical(savePanels) || isnumeric(savePanels))
    error('compose:BadOption', 'savePanels must be a logical scalar.');
end
if ~usejava('jvm')
    error('compose:NoJVM', 'The bundled MATLAB JVM is required for SHA-256 verification.');
end
packageDir = canonicalPath(packageDir);
outputPath = canonicalPath(char(outputPath));
[outputDir, outputStem, extension] = fileparts(outputPath);
if ~ismember(lower(extension), {'.png', '.pdf', '.svg'})
    error('compose:BadExtension', 'Output extension must be .png, .pdf or .svg.');
end

layoutPath = fullfile(packageDir, 'layout.csv');
required = {'figure','record_type','case_id','view','source_png','x_px','y_px', ...
    'width_px','height_px','x2_px','y2_px','text','font','font_px','font_weight', ...
    'color','line_width_px','horizontal_alignment','vertical_alignment', ...
    'isotropic_scale_factor','source_crop_sha256'};
opts = detectImportOptions(layoutPath, 'VariableNamingRule', 'preserve');
if ~all(ismember(required, opts.VariableNames))
    error('compose:BadLayout', 'layout.csv is missing required columns.');
end
% Import every field as a string so empty/all-numeric columns have one type.
opts = setvartype(opts, opts.VariableNames, 'string');
T = readtable(layoutPath, opts);
T = fillmissing(T, 'constant', "");
if height(T) == 0 || any(strlength(T.figure) == 0)
    error('compose:BadLayout', 'Every row must identify its figure group.');
end
if any(~ismember(T.record_type, ["canvas", "image", "text", "line"]))
    error('compose:BadLayout', 'Unknown record_type in layout.csv.');
end
groups = unique(T.figure, 'stable');
assets = containers.Map('KeyType', 'char', 'ValueType', 'any');
protected = {canonicalPath(layoutPath), canonicalPath(mfilename('fullpath') + ".m"), ...
    canonicalPath(fullfile(packageDir, 'compose.py'))};
for k = 1:height(T)
    r = T(k,:);
    if r.record_type ~= "image"
        continue
    end
    path = adjacentPNG(packageDir, r.source_png);
    protected{end+1} = path; %#ok<AGROW>
    if ~isKey(assets, path)
        asset.rgb = readPNG(path);
        asset.sha256 = sha256File(path);
        assets(path) = asset;
    end
    asset = assets(path);
    expected = lower(r.source_crop_sha256);
    if strlength(expected) > 0 && expected ~= string(asset.sha256)
        error('compose:HashMismatch', 'SHA-256 mismatch for %s.', r.source_png);
    end
    w = number(r, 'width_px');
    h = number(r, 'height_px');
    scale = number(r, 'isotropic_scale_factor', w / size(asset.rgb,2));
    if min([w h scale]) <= 0 || abs(w-size(asset.rgb,2)*scale) > 1e-5 || ...
            abs(h-size(asset.rgb,1)*scale) > 1e-5
        error('compose:AnisotropicImage', 'Image dimensions do not match its isotropic scale: %s.', r.source_png);
    end
end
if any(strcmpi(outputPath, protected))
    error('compose:InputOverwrite', 'Output would overwrite a package input.');
end

panels = cell(numel(groups), 1);
for k = 1:numel(groups)
    panels{k} = renderGroup(T(T.figure == groups(k),:), packageDir, assets);
end
widths = cellfun(@(p) size(p,2), panels);
heights = cellfun(@(p) size(p,1), panels);
atlas = repmat(uint8(255), sum(heights), max(widths), 3);
y = 0;
for k = 1:numel(panels)
    atlas(y+(1:heights(k)), 1:widths(k), :) = panels{k};
    y = y + heights(k);
end
if ~isfolder(outputDir)
    mkdir(outputDir);
end
writeAtlas(atlas, outputPath, extension);
if savePanels
    panelDir = fullfile(outputDir, [outputStem '_panels']);
    if ~isfolder(panelDir)
        mkdir(panelDir);
    end
    for k = 1:numel(groups)
        [~, stem] = fileparts(char(groups(k)));
        stem = regexprep(stem, '[^a-zA-Z0-9_-]', '_');
        panelPath = canonicalPath(fullfile(panelDir, sprintf('%02d_%s.png', k, stem)));
        if any(strcmpi(panelPath, protected))
            error('compose:InputOverwrite', 'Panel output would overwrite a package input.');
        end
        imwrite(panels{k}, panelPath);
    end
end
fprintf('Wrote %s (%d x %d px; %d groups; %d PNG assets verified)\n', ...
    outputPath, size(atlas,2), size(atlas,1), numel(groups), assets.Count);
end


function rgb = renderGroup(T, packageDir, assets)
canvas = T(T.record_type == "canvas",:);
if height(canvas) ~= 1
    error('compose:BadCanvas', 'Each figure group requires exactly one canvas row.');
end
w = number(canvas, 'width_px');
h = number(canvas, 'height_px');
if min([w h]) <= 0 || any([w h] ~= round([w h])) || ...
        number(canvas,'x_px',0) ~= 0 || number(canvas,'y_px',0) ~= 0
    error('compose:BadCanvas', 'Canvas dimensions must be positive integer pixels at origin (0,0).');
end
dpi = 100; % Recipe pixel font/stroke sizes are explicitly converted to points.
[fig, ax] = pixelFigure(w, h, parseColor(canvas.color, [1 1 1]), dpi);
cleanup = onCleanup(@() close(fig)); %#ok<NASGU>
for k = 1:height(T)
    r = T(k,:);
    if r.record_type == "canvas"
        continue
    end
    x = number(r, 'x_px');
    y = number(r, 'y_px');
    switch r.record_type
        case "image"
            asset = assets(adjacentPNG(packageDir, r.source_png));
            iw = number(r, 'width_px');
            ih = number(r, 'height_px');
            if x < -1e-5 || y < -1e-5 || x+iw > w+1e-5 || y+ih > h+1e-5
                error('compose:ClippedImage', 'Image extends beyond its canvas: %s.', r.source_png);
            end
            nr = size(asset.rgb,1);
            nc = size(asset.rgb,2);
            % MATLAB XData/YData identify first/last pixel CENTERS, whereas
            % the recipe identifies image edges; retain the half-pixel shift.
            image(ax, 'CData', asset.rgb, ...
                'XData', [x+iw/(2*nc), x+iw-iw/(2*nc)], ...
                'YData', [y+ih/(2*nr), y+ih-ih/(2*nr)]);
        case "line"
            line(ax, [x number(r,'x2_px')], [y number(r,'y2_px')], ...
                'Color', parseColor(r.color, [0 0 0]), ...
                'LineWidth', number(r,'line_width_px')*72/dpi);
        case "text"
            tw = number(r, 'width_px', 0);
            th = number(r, 'height_px', 0);
            ha = fallback(r.horizontal_alignment, 'left');
            va = fallback(r.vertical_alignment, 'top');
            switch ha
                case 'center', x = x + tw/2;
                case 'right', x = x + tw;
                case 'left'
                otherwise, error('compose:Alignment', 'Invalid horizontal alignment.');
            end
            switch va
                case 'center', y = y + th/2; va = 'middle';
                case 'bottom', y = y + th;
                case 'top'
                otherwise, error('compose:Alignment', 'Invalid vertical alignment.');
            end
            weight = fallback(r.font_weight, 'normal');
            if strcmp(weight, 'regular'), weight = 'normal'; end
            text(ax, x, y, char(r.text), 'Interpreter', 'none', ...
                'FontName', fallback(r.font, 'Arial'), 'FontUnits', 'points', ...
                'FontSize', number(r,'font_px')*72/dpi, 'FontWeight', weight, ...
                'Color', parseColor(r.color, [0 0 0]), ...
                'HorizontalAlignment', ha, 'VerticalAlignment', va, 'Clipping', 'on');
    end
end
drawnow;
rgb = print(fig, '-RGBImage', sprintf('-r%d', dpi));
if ~isequal(size(rgb), [h w 3])
    error('compose:UnexpectedRasterSize', ...
        'Renderer changed declared canvas dimensions; received %s, expected [%d %d 3].', mat2str(size(rgb)), h, w);
end
% Native graphics can round isolated RGB values by one level. Restore only
% exact, integer-positioned 1:1 image rectangles, after confirming that no
% later recipe element is meant to appear on top of the source screenshot.
rgb = restoreNativePixels(rgb, T, packageDir, assets);
end


function rgb = restoreNativePixels(rgb, T, packageDir, assets)
for k = 1:height(T)
    r = T(k,:);
    if r.record_type ~= "image", continue; end
    asset = assets(adjacentPNG(packageDir, r.source_png));
    x = number(r, 'x_px'); y = number(r, 'y_px');
    w = number(r, 'width_px'); h = number(r, 'height_px');
    if any(abs([x y]-round([x y])) > 1e-8) || ...
            abs(w-size(asset.rgb,2)) > 1e-8 || abs(h-size(asset.rgb,1)) > 1e-8
        continue
    end
    for j = k+1:height(T)
        later = T(j,:);
        if later.record_type == "canvas", continue; end
        lx = number(later,'x_px'); ly = number(later,'y_px');
        if later.record_type == "line"
            x2 = number(later,'x2_px'); y2 = number(later,'y2_px');
            pad = number(later,'line_width_px')/2;
            bounds = [min(lx,x2)-pad, min(ly,y2)-pad, max(lx,x2)+pad, max(ly,y2)+pad];
        else
            bounds = [lx, ly, lx+number(later,'width_px',0), ly+number(later,'height_px',0)];
        end
        if bounds(1) < x+w && bounds(3) > x && bounds(2) < y+h && bounds(4) > y
            error('compose:NativeOverlay', ...
                'A later element overlaps native image %s; exact-pixel restoration would erase that annotation.', r.source_png);
        end
    end
    rgb(round(y)+(1:round(h)), round(x)+(1:round(w)), :) = asset.rgb;
end
end


function [fig, ax] = pixelFigure(w, h, background, dpi)
fig = figure('Visible', 'off', 'Color', background, 'Units', 'pixels', ...
    'Position', [1 1 w h], 'MenuBar', 'none', 'ToolBar', 'none', ...
    'NumberTitle', 'off', 'InvertHardcopy', 'off');
fig.PaperUnits = 'inches';
fig.PaperSize = [w h]/dpi;
fig.PaperPosition = [0 0 w h]/dpi;
fig.PaperPositionMode = 'manual';
ax = axes(fig, 'Units', 'normalized', 'Position', [0 0 1 1], ...
    'XLim', [0 w], 'YLim', [0 h], 'YDir', 'reverse', ...
    'DataAspectRatio', [1 1 1], 'Visible', 'off', 'NextPlot', 'add');
end


function writeAtlas(atlas, path, extension)
if strcmpi(extension, '.png')
    imwrite(atlas, path);
    return
end
if strcmpi(extension, '.pdf')
    writeRasterPDF(atlas, path);
else
    % Native vector print can resample embedded images to the display DPI.
    % An SVG wrapper around the exact PNG preserves all atlas pixels.
    pngPath = [tempname '.png'];
    cleanup = onCleanup(@() delete(pngPath)); %#ok<NASGU>
    imwrite(atlas, pngPath);
    fid = fopen(pngPath, 'rb');
    bytes = fread(fid, Inf, '*uint8');
    fclose(fid);
    encoded = matlab.net.base64encode(bytes);
    fid = fopen(path, 'wb');
    if fid < 0, error('compose:WriteError', 'Cannot write %s.', path); end
    closeOutput = onCleanup(@() fclose(fid)); %#ok<NASGU>
    fprintf(fid, '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="%d" height="%d" viewBox="0 0 %d %d">', ...
        size(atlas,2), size(atlas,1), size(atlas,2), size(atlas,1));
    fprintf(fid, '<image width="%d" height="%d" xlink:href="data:image/png;base64,%s"/></svg>\n', ...
        size(atlas,2), size(atlas,1), encoded);
end
end


function writeRasterPDF(atlas, path)
% A minimal one-page PDF with a losslessly compressed RGB image stream.
% Using the bundled JVM for DEFLATE avoids optional toolboxes and preserves
% native pixel dimensions; no JPEG conversion or vector-print resampling.
buffer = java.io.ByteArrayOutputStream();
compressor = java.util.zip.DeflaterOutputStream(buffer);
bytes = reshape(permute(atlas, [3 2 1]), [], 1);
compressor.write(typecast(bytes, 'int8'), 0, numel(bytes));
compressor.finish();
compressed = typecast(buffer.toByteArray(), 'uint8');
compressor.close();
w = size(atlas,2);
h = size(atlas,1);
pageW = w*72/100;
pageH = h*72/100;
content = sprintf('q\n%.8f 0 0 %.8f 0 0 cm\n/Im0 Do\nQ\n', pageW, pageH);
fid = fopen(path, 'wb');
if fid < 0, error('compose:WriteError', 'Cannot write %s.', path); end
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '%%PDF-1.4\n');
offset = zeros(1,5);
offset(1) = ftell(fid);
fprintf(fid, '1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n');
offset(2) = ftell(fid);
fprintf(fid, '2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n');
offset(3) = ftell(fid);
fprintf(fid, ['3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 %.8f %.8f] ' ...
    '/Resources << /XObject << /Im0 4 0 R >> >> /Contents 5 0 R >>\nendobj\n'], pageW, pageH);
offset(4) = ftell(fid);
fprintf(fid, ['4 0 obj\n<< /Type /XObject /Subtype /Image /Width %d /Height %d ' ...
    '/ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter /FlateDecode /Length %d >>\nstream\n'], ...
    w, h, numel(compressed));
fwrite(fid, compressed, 'uint8');
fprintf(fid, '\nendstream\nendobj\n');
offset(5) = ftell(fid);
fprintf(fid, '5 0 obj\n<< /Length %d >>\nstream\n%sendstream\nendobj\n', numel(content), content);
xref = ftell(fid);
fprintf(fid, 'xref\n0 6\n0000000000 65535 f \n');
fprintf(fid, '%010d 00000 n \n', offset);
fprintf(fid, 'trailer\n<< /Size 6 /Root 1 0 R >>\nstartxref\n%d\n%%%%EOF\n', xref);
end


function path = adjacentPNG(folder, value)
name = char(value);
if isempty(name) || ~isempty(regexp(name, '[/\\:]', 'once'))
    error('compose:NonAdjacentSource', 'source_png must be an adjacent PNG basename.');
end
path = canonicalPath(fullfile(folder, name));
[parent, ~, extension] = fileparts(path);
if ~strcmpi(parent, folder) || ~strcmpi(extension,'.png') || ~isfile(path)
    error('compose:NonAdjacentSource', 'Missing/non-adjacent PNG: %s.', name);
end
end


function path = canonicalPath(path)
path = char(java.io.File(char(path)).getCanonicalPath());
end


function value = number(row, key, default)
field = row.(key);
if strlength(field) == 0 && nargin == 3
    value = default;
else
    value = str2double(field);
end
if ~isscalar(value) || ~isfinite(value)
    error('compose:NonFiniteNumber', 'Missing/non-finite %s in layout.csv.', key);
end
end


function value = fallback(value, default)
if strlength(value) == 0
    value = default;
else
    value = char(value);
end
end


function color = parseColor(value, default)
if strlength(value) == 0
    color = default;
    return
end
value = char(value);
if isempty(regexp(value, '^#[0-9a-fA-F]{6}$', 'once'))
    error('compose:BadColor', 'Colors must be RGB hexadecimal strings, for example #ffffff.');
end
color = [hex2dec(value(2:3)), hex2dec(value(4:5)), hex2dec(value(6:7))]/255;
end


function digest = sha256File(path)
fid = fopen(path, 'rb');
if fid < 0, error('compose:ReadError', 'Cannot open %s.', path); end
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
hasher = java.security.MessageDigest.getInstance('SHA-256');
while ~feof(fid)
    bytes = fread(fid, 1024*1024, '*uint8');
    hasher.update(typecast(bytes, 'int8'));
end
hashBytes = typecast(hasher.digest(), 'uint8');
digest = lower(reshape(dec2hex(hashBytes,2).', 1, []));
end


function rgb = readPNG(path)
[raw, map, alpha] = imread(path);
if ~isempty(map)
    idx = double(raw);
    if isinteger(raw) || islogical(raw), idx = idx + 1; end
    rgb = uint8(round(255*reshape(map(idx(:),:), size(raw,1), size(raw,2), 3)));
else
    if isa(raw, 'uint16')
        raw = uint8(round(double(raw)/257));
    elseif ~isa(raw, 'uint8')
        raw = uint8(round(255*double(raw)));
    end
    if size(raw,3) == 1, raw = repmat(raw,1,1,3); end
    rgb = raw;
end
if ~isempty(alpha)
    if isinteger(alpha)
        a = double(alpha)/double(intmax(class(alpha)));
    else
        a = double(alpha);
    end
    % Supplied nTop crops are opaque; support alpha on the white canvas too.
    rgb = uint8(round(double(rgb).*a + 255*(1-a)));
end
end
