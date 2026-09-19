# Replication package: The AI Revolution and Monetary Policy

**Authors:** Gadi Barlevy, Jonas D. M. Fisher, Will Pennington, and Alessandro Villa  
**Publication:** *Chicago Fed Letter*, No. 528, September 2026, Federal Reserve Bank of Chicago  
**DOI:** [10.21033/cfl-2026-528](https://doi.org/10.21033/cfl-2026-528)

[Article and technical appendix](https://www.chicagofed.org/publications/chicago-fed-letter/2026/528)

## Citation

Barlevy, Gadi, Jonas D. M. Fisher, Will Pennington, and Alessandro Villa. 2026. “The AI Revolution and Monetary Policy.” *Chicago Fed Letter*, No. 528, September. Federal Reserve Bank of Chicago. https://doi.org/10.21033/cfl-2026-528.

## Overview and contents

This package contains MATLAB scripts and Dynare model files for the article's empirical figure and model simulations, including the habit-persistence and hand-to-mouth exercises in the technical appendix. 

| File | Purpose |
| --- | --- |
| `fig1.m` | Downloads FRED data and plots U.S. nonfarm business labor productivity growth. |
| `fig2.m` | Simulates a ten-year productivity-growth increase with agents repeatedly surprised. |
| `fig3_fig4.m` | Simulates anticipated productivity growth and compares monetary policy rules; creates both figures 3 and 4. |
| `ai_growth_spell_linear_ehl_nok.mod` | Model used for the baseline and habit-persistence exercises. |
| `ai_growth_spell_linear_ehl_nok_tank.mod` | Model with Ricardian and hand-to-mouth households. |

Script names are lowercase. There are no separate `fig3.m` or `fig4.m` files. Keep the two `.mod` files in the same folder as the three scripts.

## Requirements

- **MATLAB.** The supplied figure PDFs identify MATLAB R2025a as their generating version. The code uses MATLAB tables, timetables, strings, and graphics; GNU Octave compatibility has not been established for this package.
- **Dynare 7.0** for `fig2.m` and `fig3_fig4.m`. The supplied Dynare logs report version 7.0. See the [Dynare 7.0 release information](https://www.dynare.org/new-dynare-release/dynare-7.0-released/) for compatibility; it lists MATLAB R2020a through R2025b. Use the build appropriate for your operating system and processor.
- **Internet access and a personal FRED API key** for `fig1.m` only. Obtain a key from the [FRED API key page](https://fred.stlouisfed.org/docs/api/api_key.html).
- Write access to the package folder, where figures and Dynare-generated files are saved.

The clean package contains only the five source files listed above, this README, and an empty `figures/` directory. Dynare-generated MATLAB files and incomplete older figures have been excluded.

No Haver connection is needed by the supplied data-download code. No additional paid MATLAB toolbox is explicitly called by the three scripts; an end-to-end dependency check has not been completed.

## Initial setup

1. Extract the package and set MATLAB's **Current Folder** to the directory containing this README and the scripts. Output paths are relative to that directory.

2. Before running `fig1.m`, ensure the figure directory exists:

   ```matlab
   if ~exist('figures', 'dir')
       mkdir('figures');
   end
   ```

3. In `fig1.m`, find the assignment `api_key = '';` and insert your own FRED API key between the quotes. Keep the key out of any copy you redistribute. Comment out the obsolete `addpath` statement associated with the Haver comment near the top of this script; the FRED workflow does not use it.

4. In **both** `fig2.m` and `fig3_fig4.m`, configure the `addpath` statement near the top to point to the `matlab` subdirectory of your Dynare 7.0 installation. Enable only the appropriate path, adjusting it if your installation is elsewhere:

   ```matlab
   % Windows
   addpath('C:\dynare\7.0\matlab')

   % macOS, Apple Silicon
   addpath('/Applications/Dynare/7.0-arm64/matlab')

   % macOS, Intel
   addpath('/Applications/Dynare/7.0-x86_64/matlab')
   ```

   The supplied scripts enable the Windows path. On an Apple Silicon Mac, comment out that line and uncomment the existing macOS line. On an Intel Mac, use the matching Intel installation path. For Linux or a custom installation, use its actual Dynare `matlab` directory. The `savepath` call is optional and may be commented out if you do not want to save the MATLAB search path permanently or lack permission to do so.

5. In the **User choices** section of both model scripts, set:

   ```matlab
   printfigs = 1;
   wageRigidity = 1;
   debug = 0;
   do_no_nomrate = 0;
   ```

   **The supplied `fig3_fig4.m` has `printfigs = 0`: change it to `1` to save figures 3 and 4.** The `wageRigidity = 0` branch refers to a model file that is not included.

## Running the replication

Edit the settings **inside each script**, then save the files before running. All three scripts begin with `clear`, so assigning configuration variables only in the Command Window does not override their internal settings. They also close existing figure windows.

### Figure 1: productivity data

Run:

```matlab
fig1
```

The plotted series is `OPHNFB`, transformed to four-quarter percentage growth. The current script also downloads `GDPA` and `MFPNFBS`, although they are not plotted. Figure 1 does not require Dynare and needs to be run only once.

### Main-text model figures

Set the following values in **both** `fig2.m` and `fig3_fig4.m`:

```matlab
habit = 0;
tank = 0;
plot_rstar = 0;
outdirname = '';
```

Then run:

```matlab
fig2
fig3_fig4
```


### Technical-appendix exercises

For each exercise, change these four settings in **both** model scripts, save them, and rerun `fig2` followed by `fig3_fig4`. Keep `printfigs = 1`.

| Exercise | `habit` | `tank` | `plot_rstar` | `outdirname` |
| --- | ---: | ---: | ---: | --- |
| Habit persistence | `0.7` | `0` | `1` | `'habit'` |
| Hand-to-mouth households | `0` | `1` | `1` | `'tank'` |

The TANK model sets `omega_htm = 0.3`, corresponding to a 30% share of hand-to-mouth households. `tank = 1` selects that model; it does not set the household share to 100%. The `plot_rstar` setting controls whether the natural rate is displayed; it does not choose the monetary policy rule.

## Output locations

Each figure is saved in **PDF and PNG** format when export is enabled. The model scripts create their output directories automatically. Rerunning an exercise overwrites files with the same names.

| Location and file stem | Intended publication figure |
| --- | --- |
| `figures/fig1` | Main-text figure 1 |
| `figures/fig2` | Main-text figure 2 |
| `figures/fig3` | Main-text figure 3 |
| `figures/fig4` | Main-text figure 4 |
| `figures/habit/fig2` | Appendix figure A3, subject to the policy-rule caveat below |
| `figures/habit/fig3` | Appendix figure A4 |
| `figures/habit/fig4` | Appendix figure A5 |
| `figures/tank/fig2` | Appendix figure A6 |
| `figures/tank/fig3` | Appendix figure A7 |
| `figures/tank/fig4` | Appendix figure A8 |
