# EFDCLGT_LR_Uncertainty

The main goal of this package is to provide two proxy models for two models which have been developed but not be given to me for some reasons:

* The upstream model: the distribution / samples of inflow (qser.inp) and concentration (wqpsc.inp) boundary conditions, which in principle should be derived by propagate input uncertainty (the distribution of weather forecasting and others) and parameter distribution of the upstream model. Since I will not waste my time reverse-engineering the dynamic, a simple "random push-pull mapping" is used to add some uncertainty to input while keeping its dynamic up to a constant.
* The state tracking model: the distribution / samples of initial state is given by a developed Kalman Filter, but I can only see the mean but not covariance and original model. As I will not waste my time to re-develop a KF-like model, a simple noise model based on random walk is employed to add noise to initial / restarting initial concentration.  

## Random push-pull mapping

A Poisson process `P(λ)` is sampled to define a partition of the timestamp vector. The partition point is mapped to a new location following Normal noise `N(0, σ²)`, so every section is enlarged or shrunken in time axis.

![local_mult](https://i.imgur.com/e6ECcQu.png)
![global_mult](https://i.imgur.com/DLGzyil.png)
![global_single](https://i.imgur.com/BXjOxwn.png)
![local_single](https://i.imgur.com/9hjQdlJ.png)

## Random walk based noise

Given `X(t) = X(t-1) + ϵ, ϵ ∼ N(μ, Σ)`, I estimate the multivariate normal distribution and add the noise to the initial state. The sample comes from 120 days of restarting the file (simply estimation of mean and covariance for their diff) and `Σ` is not invertible. So $X(t) = X(t-1) + μ +  ∑ᵢ zᵢXᵢ, zᵢ ∼ N(0, 1) i.i.d$ is used.
