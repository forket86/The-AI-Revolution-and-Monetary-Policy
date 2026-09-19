// ============================================================
// ai_growth_spell_linear_ehl_nok_tank_2labor_unified_w.mod
// Linearized NK model WITHOUT physical capital,
// with external habit, Rotemberg price rigidity,
// proper EHL wage rigidity,
// and switchable natural-rate Taylor rule.
//
// TANK extension with two household types:
// - Ricardian households choose consumption/labor and satisfy Euler equation.
// - Hand-to-mouth households choose labor but consume current labor income.
// - Aggregate consumption and labor keep the original names c and n.
//
// This preserves the old MATLAB interface as much as possible:
// old aggregate variables remain c, n, y, pi, piw, R, rn, yn, cn, ygap, etc.
// ============================================================

var
    c n y a g
    pi piw R
    mc w lambda uc
    wstar muw
    cn nn yn rn lambdan ucn wn mcn
    ygap

    cR cH nR nH
    lambdaR lambdaH ucR ucH

    cRn cHn nRn nHn
    lambdaRn lambdaHn ucRn ucHn
;

varexo gexo eR;

parameters
    beta sigma varphi
    phiP epsilon
    theta_w eps_w
    rho_R phi_pi phi_x phi_r
    hab use_nat
    psi_n
    omega_htm
    nbar
    mcss yss css wss lambdass
    cRss cHss nRss nHss
    cR_share cH_share nR_share nH_share
    kappa_p kappa_w
;

// -------------------------
// Calibration
// -------------------------
beta    = 0.99;
sigma   = 1.0;
varphi  = 1.0;
phiP    = 100.0;  // Rotemberg cost price rigidity a higher value means more rigid prices
epsilon = 6.0;

theta_w = 0.75;    // Calvo wage stickiness 
eps_w   = 6.0;     // elasticity across labor types

rho_R   = 0.0;
phi_pi  = 1.5;
phi_x   = 0.5;
phi_r   = 1.00;

hab     = 0.0;     // external habit
use_nat = 1.0;     // MATLAB will overwrite this
psi_n   = 0.0;     // labor adjustment cost

omega_htm = 0.3;  // share of hand-to-mouth households

nbar    = 0.33;

// -------------------------
// Steady state objects
// -------------------------
mcss = (epsilon-1)/epsilon;
yss  = nbar;
css  = yss;
wss  = mcss;

// Type-specific steady states and log-linear aggregation weights.
// Baseline normalization: both types work the same steady-state hours.
// Hand-to-mouth households consume current labor income; Ricardians receive the
// remaining aggregate resources, including profits/transfers.
nRss = nbar;
nHss = nbar;
cHss = wss*nHss;
cRss = (css - omega_htm*cHss)/(1-omega_htm);

cR_share = (1-omega_htm)*cRss/css;
cH_share = omega_htm*cHss/css;
nR_share = (1-omega_htm)*nRss/nbar;
nH_share = omega_htm*nHss/nbar;

// marginal utility of wealth at steady state with habit
lambdass = (1-beta*hab)*(css*(1-hab))^(-sigma);

// Rotemberg price Phillips slope
kappa_p = (epsilon-1)/phiP;

// EHL wage Phillips slope (first-order)
kappa_w = (1-theta_w)*(1-beta*theta_w)/(theta_w*(1+eps_w*varphi));

// ============================================================
// Linear model
// ============================================================
model(linear);

// ------------------------------------------------------------
// Exogenous productivity-growth path
// ------------------------------------------------------------
g = gexo;
a = a(-1) + g;

// ------------------------------------------------------------
// Sticky-price, sticky-wage TANK economy
// ------------------------------------------------------------

// Ricardian household: habit and marginal utility of wealth
ucR = -(sigma/(1-hab))*(cR - hab*cR(-1));
lambdaR = (ucR - beta*hab*ucR(+1))/(1-beta*hab);

// Keep old names as Ricardian objects for backward compatibility
uc = ucR;
lambda = lambdaR;

// Ricardian Euler equation for bonds
lambdaR = lambdaR(+1) + R - pi(+1);

// Hand-to-mouth household: habit and marginal utility of wealth
ucH = -(sigma/(1-hab))*(cH - hab*cH(-1));
lambdaH = (ucH - beta*hab*ucH(+1))/(1-beta*hab);

// Aggregation. The original aggregate names c and n are preserved.
// Since variables are log deviations, exact aggregation uses steady-state shares.
c = cR_share*cR + cH_share*cH;
n = nR_share*nR + nH_share*nH;

// Production
y = a + n;

// Factor prices, using aggregate labor
w = mc + y - n - psi_n*(n - n(-1)) + beta*psi_n*(n(+1) - n);

// Household intratemporal labor-supply conditions.
// There is one common desired/reset wage wstar, faced by both household types.
wstar = varphi*nR - lambdaR;
wstar = varphi*nH - lambdaH;

// EHL wage Phillips curve: one aggregate market wage w and one desired wage wstar.
muw   = w - wstar;
piw   = beta*piw(+1) - kappa_w*muw;
w     = w(-1) + piw - pi;

// Hand-to-mouth budget constraint: consume current labor income
cH = w + nH;

// Resource constraint
y = c;

// Rotemberg price Phillips curve
pi = beta*pi(+1) + kappa_p*mc;

// Output gap
ygap = y - yn;

// Taylor rule
R = rho_R*R(-1)
    + (1-rho_R)*(phi_pi*pi + phi_x*ygap + use_nat*phi_r*rn)
    + eR;

// ------------------------------------------------------------
// Natural TANK economy: flexible prices and flexible wages
// ------------------------------------------------------------

// Ricardian natural household
ucRn = -(sigma/(1-hab))*(cRn - hab*cRn(-1));
lambdaRn = (ucRn - beta*hab*ucRn(+1))/(1-beta*hab);

// Keep old natural names as Ricardian natural objects for compatibility
ucn = ucRn;
lambdan = lambdaRn;

// Natural real rate
rn = lambdaRn - lambdaRn(+1);

// Hand-to-mouth natural household
ucHn = -(sigma/(1-hab))*(cHn - hab*cHn(-1));
lambdaHn = (ucHn - beta*hab*ucHn(+1))/(1-beta*hab);

// Natural aggregation. The original natural aggregate names cn and nn are preserved.
// Since variables are log deviations, exact aggregation uses steady-state shares.
cn = cR_share*cRn + cH_share*cHn;
nn = nR_share*nRn + nH_share*nHn;

// Natural production
yn = a + nn;

// Natural marginal cost
mcn = 0;

// Natural factor prices, using aggregate natural labor
wn = mcn + yn - nn - psi_n*(nn - nn(-1)) + beta*psi_n*(nn(+1) - nn);

// Flexible-wage intratemporal conditions for both household types.
// There is one common natural wage wn, faced by both household types.
wn = varphi*nRn - lambdaRn;
wn = varphi*nHn - lambdaHn;

// Natural hand-to-mouth budget constraint
cHn = wn + nHn;

// Natural resource constraint
yn = cn;

end;

// ============================================================
// Initial values
// ============================================================
initval;
c = 0;
n = 0;
y = 0;
a = 0;
g = 0;

pi = 0;
piw = 0;
R = 0;
mc = 0;
w = 0;
lambda = 0;
uc = 0;
wstar = 0;
muw = 0;

cn = 0;
nn = 0;
yn = 0;
rn = 0;
lambdan = 0;
ucn = 0;
wn = 0;
mcn = 0;

ygap = 0;

cR = 0;
cH = 0;
nR = 0;
nH = 0;
lambdaR = 0;
lambdaH = 0;
ucR = 0;
ucH = 0;

cRn = 0;
cHn = 0;
nRn = 0;
nHn = 0;
lambdaRn = 0;
lambdaHn = 0;
ucRn = 0;
ucHn = 0;
end;

steady;
check;
