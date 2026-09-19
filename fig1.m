clear; clc; close all;


% PACKAGE NOTE: Figure 1 uses FRED. The Haver addpath below is a legacy local path; see README.
% This will be used to pull data from Haver
addpath('O:\PROJ_LIB\Presentations\Chartbook\Data\Dataset Creation\cbd');
graphname = 'fig1';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Productivity Data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%  FRED Pull: GDPA
% Build URL
% PACKAGE NOTE: Add a personal FRED key for testing; do not share a copy containing the key.
api_key = '';
series_ids = {'GDPA', 'OPHNFB', 'MFPNFBS'};
series_names = {'GDPA', 'LP', 'NFTFP'};
fred = struct();

for i = 1:numel(series_ids)
    series_id = series_ids{i};

    url = sprintf(['https://api.stlouisfed.org/fred/series/observations?' ...
               'series_id=%s&api_key=%s&file_type=json'], ...
               series_id, api_key);

    % Fetch data
    data = webread(url);
    obs = data.observations;
    dates_str = {obs.date}';
    values_str = {obs.value}';
    values = str2double(values_str);
    dates = datetime(dates_str, 'InputFormat', 'yyyy-MM-dd');
    fred(i).data = renamevars(table(dates, values), ["values", "dates"], [string(series_names{i}), "Date"]); 

    % Wait (to avoid FRED whining)
    pause(1)
end

% Merge FRED data together
for i = 1:(numel(series_ids) - 1)
    if i ==1
        data = fred(1).data;
    end
    data = outerjoin(data, fred(i + 1).data, "Keys", "Date", "Type", "Full", "MergeKeys", true);
end

data = table2timetable(data);

% Add growth rate variables 
data.NFTFPgrowth = [repelem(NaN, 4)'; ((data.NFTFP(5:end)./data.NFTFP(1:(end-4))) - 1)*100];
data.LPgrowth = [repelem(NaN, 4)'; ((data.LP(5:end)./data.LP(1:(end-4))) - 1)*100];

% Log-Level
data.logLP = log(data.LP);

% Smooth
data.LPgrowth_smoothed = smoothdata(data.LPgrowth, 1, "movmean", 12);
data.NFTFPgrowth_smoothed = smoothdata(data.NFTFPgrowth, 1, "movmean", 12);




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figure 1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
date_beg = datetime(2011, 1, 1);
date_mid1 = datetime(2019, 10, 1);
date_mid2 = datetime(2023, 1, 1);


titles = {"percent"};
seriesnamesa = {"LPgrowth"};
tiledlayout(1, numel(seriesnamesa))


for j = 1
    nexttile(j);
    hold on;
   
    plotdata = data(~isnan(data.(seriesnamesa{j})), :);
    

    avg_pre = mean(plotdata{(plotdata.Date >= date_beg) & (plotdata.Date <= date_mid1), [seriesnamesa{j}]});
    dates_pre = plotdata.Properties.RowTimes((plotdata.Date >= date_beg) & (plotdata.Date <= date_mid1));
    avg_post = mean(plotdata{(plotdata.Date >= date_mid2), [seriesnamesa{j}]});
    dates_post = plotdata.Properties.RowTimes((plotdata.Date >= date_mid2));

    l1 = plot(plotdata.Date, plotdata.(seriesnamesa{j}), 'LineStyle', '-', 'LineWidth', 2, 'Color', "#5D9EDA");
    l2 = plot(dates_pre, repelem(avg_pre, numel(dates_pre))', 'LineStyle', '--', 'LineWidth', 1, 'Color', 'Black');
    l3 = plot(dates_post, repelem(avg_post, numel(dates_post))', 'LineStyle', '--', 'LineWidth', 1, 'Color', 'Black');
    
    % Y label: horizontal, top
    set(gca, 'FontName', 'Arial', 'FontSize', 9);
    ylleft=ylabel(titles{j}, 'FontSize', 9);
    set(ylleft, 'Units', 'Normalized', 'Position', [0 1.005], 'HorizontalAlignment', 'left', 'Rotation', 0)

    yline(0, 'k-', 'LineWidth', 0.5);
    xline(datetime(2022, 11, 30), 'Color', '#626461', 'LineWidth', 2)
    datetick('x', 'yyyy', 'keepticks');
    grid off;


    % Annotations showing averages
    xpre=dates_pre(floor(numel(dates_pre)/4));
    ypre=avg_pre*2.4;
    t1=text(xpre, ypre, sprintf("2011-19 Average: %.1f%%", string(avg_pre)), 'FontSize', 8)

    xpost=dates_post(floor(numel(dates_post)/4 + 1));
    ypost = 4;
    t2=text(xpost, ypost, sprintf("%s-26 Average: %.1f%%", string(year(date_mid2)), string(avg_post)), 'FontSize', 8);

    t3=text(datetime(2023, 1, 31), 7.5, "Public debut of ChatGPT", 'FontSize', 8);


    % Change Formatting of x-axis
    xlim([date_beg, plotdata.Date(end)]);
    xticks(datetime(int16(((year(date_beg):1:year(plotdata.Date(end))))), 1, 1))

    curxticks = year(xticks);
    curxticks_str = string(curxticks(curxticks >= year(date_beg)));
    xticks_formatted = cellstr(curxticks_str);
    xticks_formatted = cell2mat(cellfun(@(s) strcat("'", s(3:4)), xticks_formatted, 'Uniformoutput', false));
    loc_2000 = (find(curxticks_str=="2000"));
    if numel(loc_2000) == 0
        loc_2000 = 0;
        xticks_final = [curxticks_str(1) ...
                        xticks_formatted(2:length(xticks_formatted))];
    else
        xticks_final = [string(curxticks(curxticks < year(date_beg))) ...
                curxticks_str(1) ...
                xticks_formatted(2:loc_2000 - 1) ...
                curxticks_str(loc_2000) ...
                xticks_formatted((loc_2000 + 1):length(xticks_formatted))];
    end

    labels_keep = ["2011", "'16", "'21", "'26"];
    xticks_final(~ismember(xticks_final, labels_keep)) = "";
    xticklabels(xticks_final)
    xtickangle(0)

end

% Adjust figure parameters
fig = gcf;
fig.Units = 'inches';
fig.Position = [1 1 9 6];
pos = fig.Position; % Gets [left bottom width height]
fig.PaperPositionMode = 'manual';
fig.PaperSize = [pos(3) pos(4)]; 
fig.PaperPosition = [0 0 pos(3) pos(4)];


% PACKAGE NOTE: The figures directory must exist before this script saves its output.
% Save figure
print(gcf, ['./figures/' graphname '.png'],'-dpng');
print(gcf, ['./figures/' graphname '.pdf'],'-dpdf');
