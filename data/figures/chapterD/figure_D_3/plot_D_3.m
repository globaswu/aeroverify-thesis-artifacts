function outputFile = plot_D_3(outputFile)
scriptDir = fileparts(mfilename('fullpath'));
if nargin < 1 || isempty(outputFile)
    outputFile = fullfile(scriptDir, 'plot_D_3.png');
end
outputFile = char(outputFile);
outputDir = fileparts(outputFile);
if ~isempty(outputDir) && ~isfolder(outputDir), mkdir(outputDir); end
dataFile = fullfile(scriptDir, 'figure_D_3.csv');
T = readtable(dataFile, 'TextType', 'string', 'VariableNamingRule', 'preserve');
set(groot, 'defaultAxesFontName', 'Times New Roman'); set(groot, 'defaultTextFontName', 'Times New Roman');
P = sortrows(T(T.record_type == "profile", :), 'input_physical'); S = T(T.record_type == "survival", :);
x = unique(S.input_physical,'sorted'); threshold = unique(S.normalized_hvi_threshold,'sorted');
probability = reshape(S.conditional_exceedance_probability,numel(threshold),numel(x));
displayValue = reshape(S.display_log10_exceedance_probability,numel(threshold),numel(x));
fig=figure('Color','w','Visible','off','Position',[100 100 850 1050]); tl=tiledlayout(fig,3,1,'TileSpacing','compact','Padding','compact');
ax=nexttile(tl); imagesc(ax,x,log10(threshold),displayValue); set(ax,'YDir','normal'); hold(ax,'on'); [c,h]=contour(ax,x,log10(threshold),probability,[.01 .1 .5],'LineColor',[.13 .13 .13],'LineWidth',.8); clabel(c,h,'FontSize',7); xlabel(ax,'Aspect ratio, AR [-]'); ylabel(ax,'Normalized HVI threshold [-]'); yticks(ax,[-8 -6 -4 -2 0]); yticklabels(ax,{'10^{-8}','10^{-6}','10^{-4}','10^{-2}','10^{0}'}); title(ax,'A. Conditional HVI survival field'); cb=colorbar(ax); ylabel(cb,'Conditional exceedance probability'); cb.Ticks=[log10(1/2048) -3 -2 -1 0]; cb.TickLabels={'<=1/2048','10^{-3}','10^{-2}','10^{-1}','1'}; clim(ax,[log10(1/2048) 0]);
ax=nexttile(tl); hold(ax,'on'); semilogy(ax,P.input_physical,positive(P.p90_normalized_hvi),'Color',[.84 .62 .10],'LineWidth',1.6,'DisplayName','90th percentile'); semilogy(ax,P.input_physical,positive(P.p99_normalized_hvi),'Color',[.91 .43 .09],'LineWidth',1.8,'DisplayName','99th percentile'); semilogy(ax,P.input_physical,positive(P.mean_normalized_hvi),'--','Color',[.09 .41 .67],'LineWidth',1.7,'DisplayName','Conditional mean'); semilogy(ax,P.input_physical,positive(P.sampled_profile_maximum_normalized_hvi),'Color',[.13 .13 .13],'LineWidth',2,'DisplayName','Sampled profile maximum'); scatter(ax,P.selected_input_physical(1),P.selected_hvi_normalized(1),72,[.70 .23 .23],'p','filled','Clipping','off','DisplayName','Selected design'); set(ax,'YScale','log'); ylim(ax,[1e-8 1.15]); grid(ax,'on'); xlabel(ax,'Aspect ratio, AR [-]'); ylabel(ax,'Normalized HVI [-]'); title(ax,'B. Conditional quantiles and profile'); legend(ax,'Location','southwest','FontSize',7);
lastPositive=find(P.positive_hvi_fraction>0,1,'last');
if ~isempty(lastPositive) && lastPositive < height(P)
    zeroStart=P.input_physical(lastPositive+1);
    xline(ax,zeroStart,':','Color',[.47 .47 .47],'LineWidth',.8,'HandleVisibility','off');
    text(ax,.98,.20,sprintf('All sampled HVI = 0 for AR >= %g',zeroStart),'Units','normalized', ...
        'HorizontalAlignment','right','FontSize',8,'BackgroundColor','w','Interpreter','none');
end

ax=nexttile(tl); hold(ax,'on'); semilogy(ax,P.input_physical,positive(P.positive_hvi_fraction),'Color',[.91 .43 .09],'LineWidth',2,'DisplayName','Positive-HVI fraction'); semilogy(ax,P.input_physical,positive(P.mean_normalized_hvi),'--','Color',[.09 .41 .67],'LineWidth',1.8,'DisplayName','Conditional mean'); set(ax,'YScale','log'); ylim(ax,[1e-8 1]); grid(ax,'on'); xlabel(ax,'Aspect ratio, AR [-]'); ylabel(ax,'Conditional domain-volume statistic [-]'); title(ax,'C. Positive-HVI support and conditional mean'); legend(ax,'Location','best','FontSize',8);
allAxes=findall(fig,'Type','axes'); for k=1:numel(allAxes), xlim(allAxes(k),[min(x) max(x)]); set(allAxes(k),'YMinorGrid','off','XMinorGrid','off'); end
title(tl,'Frozen sampled-HVI field versus aspect ratio before evaluation 100','FontWeight','bold'); exportgraphics(fig,outputFile,'Resolution',300); close(fig); disp(outputFile);
end
function y=positive(x), y=x; y(y<=0)=NaN; end
