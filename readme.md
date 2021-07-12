# EFDCLGT_LR_Uncertainty

The main goal of this package is to provide two proxy models for two models which have been developed but not be given to me for some reasons:

* The upstream model: the distribution / samples of inflow (qser.inp) and concentration (wqpsc.inp) boundary conditions, which in principle should be derived by propagate input uncertainty (the distribution of weather forecasting and others) and parameter distribution of the upstream model. Since I will not waste my time reverse-engineering the dynamic, a simple "random push-pull mapping" is used to add some uncertainty to input while keeping its dynamic up to a constant.
* The state tracking model: the distribution / samples of initial state is given by a developed Kalman Filter, but I can only see the mean but not covariance and original model. As I will not waste my time to re-develop a KF-like model, a simple noise model based on random walk is employed to add noise to initial / restarting initial concentration.

## Methods

### Random push-pull mapping

A Poisson process `P(λ)` is sampled to define a partition of the timestamp vector. The partition point is mapped to a new location following Normal noise `N(0, σ²)`, so every section is enlarged or shrunken in time axis.

![local_mult](https://i.imgur.com/e6ECcQu.png)
![global_mult](https://i.imgur.com/DLGzyil.png)
![global_single](https://i.imgur.com/BXjOxwn.png)
![local_single](https://i.imgur.com/9hjQdlJ.png)

### Random walk based noise

Given `log(X(t)) = log(X(t-1)) + ϵ, ϵ ∼ N(μ, Σ)`, I estimate the multivariate normal distribution and add the noise to the initial state. The sample comes from 120+ days of restarting the file (simply estimation of logarithm of mean and covariance for their diff) and `Σ` is not invertible. So `log(X(t)) = log(X(t-1)) + μ +  ∑ᵢ zᵢXᵢ, zᵢ ∼ N(0, 1) i.i.d` is used.

## Usage

```julia
using EFDCLGT_LR_Uncertainty

# `$WATER_UPSTREAM/1/qser.inp`, `$WATER_UPSTREAM/1/wqpsc.inp`, ..., `WATER_UPSTREAM/10/wqpsc.inp` will be created.
random_push()

# `WATER_UPSTREAM` will be overridden by string `dst_root`
random_push(dst_root)

# default arguments: n=10, λ=1/24, σ=5
random_push(dst_root, n, λ, σ)

# Create "$WATER_META/pdfd.bson" and `$WATER_UPSTREAM/1/wqini.inp`, ..., `$WATER_UPSTREAM/10/wqini.inp`
random_initial_state()

# `WATER_UPSTREAM` will be overridden by string `dst_root`
random_initial_state(dst_root)

# default arguments: n=10, coef=0.1
random_initial_state(dst_root, n, coef)
```

