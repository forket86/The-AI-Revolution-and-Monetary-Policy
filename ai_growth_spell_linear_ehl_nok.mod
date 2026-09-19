// ============================================================
// ai_growth_spell_linear_ehl_nok.mod
// Linearized NK model WITHOUT physical capital,
// with external habit, Rotemberg price rigidity,
// proper EHL wage rigidity,
// and switchable natural-rate Taylor rule.
//
// All endogenous variables are deviations from steady state:
// - real variables are log deviations
// - pi, piw, R, rn are deviations in quarterly rates
//
// Growth experiment:
// MATLAB feeds the full path for gexo directly.
// Example:
//   gexo_t = Delta_g for t=1,...,H
//   gexo_t = rho_g^(t-H)*Delta_g for t>H
// so growth jumps up as a step function and mean-reverts smoothly after.
//
// use_nat = 0  -> standard Taylor rule
// use_nat = 1  -> Taylor rule with natural-rate term
// ============================================================

var
    c n y a g
    pi piw R
    mc w lambda uc
    wstar muw
    cn nn yn rn lambdan ucn wn mcn
    ygap
;

varexo gexo eR;

parameters
    beta sigma varphi
    phiP epsilon
    theta_w eps_w
    rho_R phi_pi phi_x phi_r
    hab use_nat
    psi_n
    nbar
    mcss yss css wss lambdass
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

nbar    = 0.33;

// -------------------------
// Steady state objects
// -------------------------
mcss = (epsilon-1)/epsilon;
yss  = nbar;
css  = yss;
wss  = mcss;

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
// Sticky-price, sticky-wage economy
// ------------------------------------------------------------

// Habit block
uc = -(sigma/(1-hab))*(c - hab*c(-1));
lambda = (uc - beta*hab*uc(+1))/(1-beta*hab);

// Euler equation for bonds
lambda = lambda(+1) + R - pi(+1);

// Production
y = a + n;

// Factor prices
//w = mc + y - n;

w = mc + y - n - psi_n*(n - n(-1)) + beta*psi_n*(n(+1) - n);

// Proper EHL wage block
wstar = varphi*n - lambda;
muw   = w - wstar;
piw   = beta*piw(+1) - kappa_w*muw;
w     = w(-1) + piw - pi;

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
// Natural economy: flexible prices and flexible wages
// ------------------------------------------------------------

ucn = -(sigma/(1-hab))*(cn - hab*cn(-1));
lambdan = (ucn - beta*hab*ucn(+1))/(1-beta*hab);

// Natural real rate
rn = lambdan - lambdan(+1);

// Natural production
yn = a + nn;

// Natural marginal cost
mcn = 0;

// Natural factor prices
//wn = yn - nn;
wn = mcn + yn - nn - psi_n*(nn - nn(-1)) + beta*psi_n*(nn(+1) - nn);

// Flexible wage condition
wn = varphi*nn - lambdan;

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
end;

steady;
check;