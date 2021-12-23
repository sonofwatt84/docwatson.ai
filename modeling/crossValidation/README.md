# Cross-Validation

All good statistical models need to be evaluated with out-of-sample data. In my research I use a lot of custom cross-validation scripts because of the architecture of the models that we use. We often need to isolate the variance of individual storm events, so we apply a leave-one-storm-out cross-validation, which is just a more specific form of a leave-one-group-out cross-validation. This is particularly useful in this application because the cross-validation results are close to what an operational prediction of an event would have been.  

We usually use custom scripts like these for cross-validation because unfortunately leave-one-group-out cross-validations are not well supported in many libraries, and often we're applying pre-processing steps that must be done fold-by-fold.
