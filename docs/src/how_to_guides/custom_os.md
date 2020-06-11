# How to define custom observation schemes?
***
To define custom observation schemes use the struct `GeneralObs`. You can read more about it [here](@ref non_linear_non_gsn). It allows you to define any observation scheme.

!!! tip
    By default `GeneralObs` requires from the user to pass a `LinearGsnObs` approximation to the `GeneralObs`. This is meant to be used in an MCMC setting, when such an approximation is necessary. However, if your application does not require `LinearGsnObs` approximation, then simply pass an irrelevant instance of `LinearGsnObs` to a constructor of `GeneralObs` (or define a custom constructor for `GeneralObs` that does not require from the user for `LinearGsnObs` to be passed, and instead, creates and passes an irrelevant instance of `LinearGsnObs` internally).
