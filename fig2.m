clear; clc; close all;

% PACKAGE NOTE: Configure the Dynare 7.0 path for the computer used for the test.
%addpath('/Applications/Dynare/7.0-arm64/matlab')
addpath('C:\dynare\7.0\matlab')
savepath

%% Slope of the NKPC under Rotemberg
epsilon = 6.0;
phiP    = 100.0;
SlopeR=(epsilon-1)/phiP;
%% Slope of the NKPC under Calvo
theta=0.75;
beta    = 0.99;
SlopeC=(1-theta)*(1-beta*theta)/theta;

phiP_implied=(epsilon-1)/SlopeC;


% ------------------------------------------------------------
% PACKAGE NOTE: Change scenario settings here; clear at startup discards Command Window variables.
% User choices
% ------------------------------------------------------------
T = 240;             % total simulation length (quarters)
Tplot = 70;          % quarters shown in figures
delta_g = 0.0025;    % quarterly extra TFP growth = +1 annualized pp
rho_g_path = 0.70;   % smooth decay AFTER the announced extension
preH = 4*10;         % first phase length
rollingShocks = 1;
doExtension = 0;     % =1 add extension announcement, =0 no extension
printfigs=1;
q_decay = 20;
debug = 0;
do_no_nomrate = 0; 
wageRigidity=1;
tank=0;
habit = 0.0; 
plot_rstar = 0;
outdirname = '';

if wageRigidity==0
    modfile = 'ai_growth_spell_linear_ehl_nok_nothetaw';
else
    if tank==0
        modfile = 'ai_growth_spell_linear_ehl_nok'; % FOcus
    else
        modfile = 'ai_growth_spell_linear_ehl_nok_tank'; % FOcus
    end
end


plotvars = {'g', 'pi', 'ygap', 'R', 'rn'};
plotlabels = {'A. TFP growth', 'B. Inflation', 'C. Output gap', 'D. Nominal interest rate'};
plotlabels_subtext = {'annualized percentage points', 'annualized percent dev. from steady state', 'percentage points', 'annualized percent dev. from steady state'};
plotlims = {[-0.2 1.4], [-1 1], [-0.2 0.8] [-1 2]};

if (habit > 0.0) & (plot_rstar == 1)
    plotlims = {[-0.8 1.2], [-1 1], [-0.2 0.8] [-1.5 2]};
end


% Cases refer to ADDITIONAL duration announced after the first phase
cases(1).extension = 12;   % 3 more years
cases(1).use_nat   = 0;
cases(1).name      = 'Standard Taylor';

cases(2).extension = 12;
cases(2).use_nat   = 1;
cases(2).name      = 'Natural-rate Taylor';

% ------------------------------------------------------------
% Output folder for figures
% ------------------------------------------------------------
if debug==1
    figdir = fullfile(pwd, 'figures_debug', outdirname);
else
    figdir = fullfile(pwd, 'figures', outdirname);
end


if ~exist(figdir, 'dir')
    mkdir(figdir);
end

% ------------------------------------------------------------
% Load Dynare model once
% ------------------------------------------------------------
dynare(modfile, 'noclearall');
global M_ oo_ options_

Mbase   = M_;
oobase  = oo_;
optbase = options_;

results = struct();

for j = 1:numel(cases)

    % Reset model objects
    M_ = Mbase;
    oo_ = oobase;
    options_ = optbase;

    % Switch policy rule
    set_param_value('use_nat', cases(j).use_nat);
    set_param_value('hab', habit)

    % Recompute steady state
    steady;

    % Locate shock
    id_gexo = find(strcmp(cellstr(M_.exo_names), 'gexo'));
    if isempty(id_gexo)
        error('Could not find gexo in M_.exo_names.');
    end

    % Basic indexing
    maxlag = double(M_.maximum_lag);
    if ~isscalar(maxlag) || ~isfinite(maxlag)
        error('M_.maximum_lag is not a valid scalar.');
    end
    maxlag = round(maxlag);

    nendo = double(M_.endo_nbr);
    if ~isscalar(nendo) || ~isfinite(nendo)
        error('M_.endo_nbr is not a valid scalar.');
    end
    nendo = round(nendo);

    extH = cases(j).extension;

    if maxlag < 0
        error('Invalid Dynare timing: maximum_lag is negative.');
    end

    % First simulated period in Dynare storage
    t0 = round(1 + maxlag);

    % --------------------------------------------------------
    % Build stitched path
    % We'll store:
    %   column 1      = quarter 0 (initial steady state)
    %   columns 2:T+1 = quarters 1..T
    % --------------------------------------------------------
    stitched = nan(nendo, T + 1);

    % --------------------------------------------------------
    % Initial setup from steady state
    % --------------------------------------------------------
    options_.periods = T;
    oo_ = perfect_foresight_setup(M_, options_, oo_);% WP

    % Initial state = steady state (linear model => zeros)
    stitched(:,1) = 0;

    % History block for Dynare
    if maxlag > 0
        hist_block = oo_.endo_simul(:, 1:maxlag);
    else
        hist_block = zeros(nendo,0);
    end

    % Solver options
    options_.stack_solve_algo = 0;
    options_.solve_algo = 4;
    options_.maxit = 500;
    options_.tolf = 1e-10;
    options_.tolx = 1e-10;

    if rollingShocks == 1
        % ========================================================
        % PHASE 1: rolling unexpected contemporaneous shocks
        % ========================================================
        for iq = 1:(preH+q_decay)

            Trem = T - (iq - 1);

            options_.periods = Trem;
            oo_ = perfect_foresight_setup(M_, options_, oo_);% WP
            oo_.exo_simul(:) = 0;

            % Carry current history into this solve
            if maxlag > 0
                oo_.endo_simul(:, 1:maxlag) = hist_block;
            end

            % Only the current quarter's higher growth is known now
            if iq >= preH % Decay after end of pre-period
                oo_.exo_simul(t0, id_gexo) = delta_g * rho_g_path^(iq - preH);
            else          % Flat during unexpected growth
                oo_.exo_simul(t0, id_gexo) = delta_g;
            end


            % Solve
            [oo_, ~] = perfect_foresight_solver(M_, options_, oo_); %WP

            % Store realized current-quarter outcome
            store_col = round(iq + 1);
            sim_col   = round(t0);

            if store_col < 1 || store_col > size(stitched,2)
                error('Invalid storage index in phase 1.');
            end
            if sim_col < 1 || sim_col > size(oo_.endo_simul,2)
                error('Invalid simulation index in phase 1.');
            end

            stitched(:, store_col) = oo_.endo_simul(:, sim_col);

            % Update history block for next quarter
            if maxlag > 0
                hist_cols = sim_col : sim_col + maxlag - 1;
                if any(hist_cols < 1) || any(hist_cols > size(oo_.endo_simul,2))
                    error('Invalid history update indices in phase 1.');
                end
                hist_block = oo_.endo_simul(:, hist_cols);
            end
        end
    else
        % ========================================================
        % PHASE 1: quarter 1 surprise announcement of preH periods
        % ========================================================
        options_.periods = T;

        oo_ = perfect_foresight_setup(M_, options_, oo_);% WP
        oo_.exo_simul(:) = 0;

        if maxlag > 0
            oo_.endo_simul(:, 1:maxlag) = hist_block;
        end

        % At quarter 1, agents learn the whole preH path
        end_pre = min(t0 + preH - 1, size(oo_.exo_simul,1));
        oo_.exo_simul(t0:end_pre, id_gexo) = delta_g;

        [oo_, ~] = perfect_foresight_solver(M_, options_, oo_); %WP

        % Store realized quarters 1..preH
        stitched(:, 2:preH+1) = oo_.endo_simul(:, t0:t0+preH-1);

        % Update history block to the end of quarter preH
        if maxlag > 0
            hist_cols = (t0 + preH - maxlag):(t0 + preH - 1);
            hist_block = oo_.endo_simul(:, hist_cols);
        end
    end

    % ========================================================
    % PHASE 2: continuation after the initial phase
    % ========================================================
    Trem = T - preH - q_decay;

    options_.periods = Trem;
    oo_ = perfect_foresight_setup(M_, options_, oo_);% WP
    oo_.exo_simul(:) = 0;

    % Start from the state reached after phase 1
    if maxlag > 0
        oo_.endo_simul(:, 1:maxlag) = hist_block;
    end

    if doExtension == 1
        % Announced extension: constant elevated growth for extH quarters
        end_const = min(t0 + extH - 1, size(oo_.exo_simul,1));
        oo_.exo_simul(t0:end_const, id_gexo) = delta_g;

        % After extension: geometric decay
        if end_const < size(oo_.exo_simul,1)
            for it = end_const + 1 : size(oo_.exo_simul,1)
                oo_.exo_simul(it, id_gexo) = delta_g * rho_g_path^(it - end_const);
            end
        end
    end

    % If doExtension==0, oo_.exo_simul remains zero:
    % this is the zero-shock continuation from the end of phase 1.

    [oo_, ~] = perfect_foresight_solver(M_, options_, oo_); %WP

    % Append continuation path
    store_cols = (preH + 2 + q_decay):(T + 1);   % quarters preH+1 ... T
    sim_cols   = t0:(t0 + Trem - 1);

    if length(store_cols) ~= length(sim_cols)
        error('Phase-2 storage length mismatch.');
    end
    if any(sim_cols < 1) || any(sim_cols > size(oo_.endo_simul,2))
        error('Invalid simulation indices in phase 2.');
    end

    stitched(:, store_cols) = oo_.endo_simul(:, sim_cols);

    disp(['Solved case: extensionFlag = ', num2str(doExtension), ...
        ', extension = ', num2str(extH), ...
        ', use_nat = ', num2str(cases(j).use_nat)]);

    % --------------------------------------------------------
    % Store transformed series
    % --------------------------------------------------------
    results(j).name      = cases(j).name;
    results(j).extension = extH;
    results(j).use_nat   = cases(j).use_nat;

    for v = 1:numel(plotvars)
        idx = find(strcmp(cellstr(M_.endo_names), plotvars{v}));
        if isempty(idx)
            error('Variable %s not found in M_.endo_names.', plotvars{v});
        end

        raw = stitched(idx,:)';

        switch plotvars{v}
            case {'a','y','yn','c','cn','n','nn','w','wn'}
                tr = 100*raw;   % log deviations -> percent

            case {'pi','piw','R','rn','g'}
                tr = 400*raw;   % quarterly deviations -> annualized pp

            case 'ygap'
                tr = 100*raw;   % log gap -> percentage points

            otherwise
                tr = raw;
        end

        results(j).(plotvars{v}) = tr;
    end
end




% ------------------------------------------------------------
% Expected TFP-growth path for plotting in top panel
% ------------------------------------------------------------
g_expected = zeros(T+1,1);

% ------------------------------------------------------------
% Plot style
% ------------------------------------------------------------
lw = 2;
styles = {'-','--'};
make_tt = @(yy) 0:min(Tplot, length(yy)-1);

title_fs = 8;
label_fs = 7;
tick_fs  = 11;
yellow_rgb = [0.9290 0.6940 0.1250];




% ============================================================
% Figure 1: 10y surprise
% ============================================================

fig1 = figure('Color','w','Position',[100 100 1450 900]);

if debug==1
    wplot = 3; hplot = 3;
else
    wplot = 2; hplot = 2;
end

if do_no_nomrate==1
    maxit = wplot*hplot - 1;
else
    maxit = wplot*hplot;
end

t = tiledlayout(wplot, hplot);
% PACKAGE NOTE: Case 1 sets use_nat=0. The article caption says r* is tracked; see README.
idx_cases = [1];
names_here = {results(idx_cases).name};
ext_here = results(idx_cases(1)).extension;

for v = 1:(maxit)
    if v ~= numel(plotvars)
        nexttile(v); hold on; box on;
    else
        nexttile(v+1); hold on; box on;
    end

    for jj = 1:numel(idx_cases)
        jc = idx_cases(jj);
        yy = results(jc).(plotvars{v});
        tt = make_tt(yy);
        plot(tt, yy(1:length(tt)), 'LineStyle', styles{jj}, 'LineWidth', lw, 'Color', '#3E89E1');

        if strcmp(plotvars{v}, 'g')
            yy_2 = results(jc).("rn")*0;
            yy_3 = results(jc).rn; % Natural rate
            plot(tt, yy_2(1:length(tt)), 'Linestyle', '--', 'Color', "#8E0000", 'LineWidth', lw);  

            if plot_rstar==1
                plot(tt, yy_3(1:length(tt)), 'Linestyle', ':', 'Color', "#E1C863", 'LineWidth', lw);
            end

        end
    end

    ylim(plotlims{v});
    xlim([0 Tplot]);

    yline(0,'Linewidth', 1.5, 'Color', 'Black', 'LineStyle', '--');
    xline(preH, 'LineWidth',2, 'Color', '#626461', 'LineStyle', '-');
    set(gca, 'FontSize', tick_fs);
    tit=title(plotlabels{v}, 'Interpreter','tex', 'FontSize', title_fs);

    if debug==0
        yl=ylabel(plotlabels_subtext{v}, 'FontSize', title_fs - 1)
    else
        yl = ylabel('');
    end

    xlabel('quarter', 'FontSize', label_fs);

    % Format ticks
    cyticks = yticks;
    yticklabels(compose('%.1f', cyticks));

    % Turn grid off
    grid off; box off;

    % Position ylab above axis
    set(yl, 'Units', 'normalized', 'Position', [0 1.02], 'Rotation', 0, 'HorizontalAlignment', 'left')
    set(tit, 'Units', 'normalized', 'Position', [0 1.06], 'Rotation', 0, 'HorizontalAlignment', 'left')

    ax = gca;
    ax.LineWidth = 1;
    ax.FontSize = 7;
    set(gca, 'FontName', 'Arial')
end

lg = legend('', '', '', 'Box', 'off');
lg.Layout.Tile = 'South';

% Add legend to tile 1
nexttile(1);
if plot_rstar==1
    legend('TFP growth', 'Expected TFP growth', 'Natural rate (\itr*)', '', '', '', '', 'Location', 'Southoutside', 'box', 'off', 'Fontsize', 9)
else
    legend('TFP growth', 'Expected TFP growth', '', '', '', '', 'Location', 'Southoutside', 'box', 'off', 'Fontsize', 9)
end


set(fig1, 'PaperOrientation', 'landscape');
set(fig1, 'PaperUnits', 'normalized');
set(fig1, 'PaperPosition', [0 0 1 1]);

if printfigs==1
    print(fig1, fullfile(figdir, 'fig2.pdf'), ...
        '-dpdf', '-fillpage');
    print(fig1, fullfile(figdir, 'fig2.png'), '-dpng')
end
