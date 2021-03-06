Quick readme: 

See demo.m on how to generate random samples, with several examples.

In more detail:

The main component of this package is the function 
sample in sample.m
to sample according to a density proportional to a given function of the form 

f(x) = exp(-sum f_i(x_i)) 

restricted to a polyhedron defined by
{Aineq x <= bineq, Aeq x = beq, lb <= x <= ub}

The function f is specified by a vector function of its 1st and 2nd.
Only the first derivative is required. For uniform sampling this is empty ([]).
If the first derivative is a function handle, then the function and its second derivatives must also be provided.

This core function sample.m is supplemented by functions to: 
1. find an initial feasible point 
2. test convergence of the sampling algorithm with Effective Sample Size and a uniformity test (if target is uniform).

You can set up the parameters for sampling via a struct called opts. Here are some parameters you may want to set:

                        maxTime: 86400 (max sampling time in seconds)
                        maxStep: 300000 (maximum number of steps)

 
The output of sample is a struct "o" with fields including:

                samples: dim x #steps


