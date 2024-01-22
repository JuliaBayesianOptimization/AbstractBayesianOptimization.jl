- callbacks can be e.g.
  - eval objective and update the surrogate model
  - get lower and upper bounds and set up normalizers
  - eval objective and init. model (or a TR)
- a task together with a callback forms pair saying what information is needed and what will happen once that information is available
- BOAlg needs to have a mechanism for creating (task, callback) pairs according to the current stage
  - set up normalizers
  - initial sampling, create a dsm from dsm specification
  - running optimization
    - in TuRBO this means sometimes setting up new TRs, i.e., need inititial sampling
- it should not create tasks for evaluation if the budget is exhausted
- maybe create some sort of task manager struct?

```Julia
mutable struct BasicBO{T <: some_paramteric_type_of_dsm, P <: AbstractPolicy}
    specification
    initial_task_callback_pairs # vector of tuples
    dsm::Union{Nothing, T}
    policy::P
    domain_normalizer
    sense_normalizer
    stats
end

function BO_alg(specification)
    # init dsm, policy, domain_normalizer, sense_normalizer, stats to nothing but include the concrete type T via
    # BasicBO{T}(..., nothing, nothing, nothing,..)
end


function ask(basic_bo::BasicBO)
    if !isempty(initial_task_callback_pairs)    
        # initialization part
        return popfirst!(initial_task_callback_pairs)
    else
        # optimization part
        return (EvalObjective(next_batch(basic_bo)), ys -> update!(basic_bo, xs, ys)) # compute next batch xs, eval objective at xs, update stats and dsm in callback

        # in TuRBO, if tr needs to be updated (this needs to be marked by a flag in dsm), policy is not called in next iteration and the the callback initializes a tr and disables flag for initialization in next iteration.
    end
end
```

- configuration contains settings for creating a bo_alg consisting of: 
  - dsm, policy, domain_normalizer, sense_normalizer, stats
- initial_tasks contain setting up normalizers and dsm
- the types of domain and range should be passed in configuration s.t. the type of bo_alg is concrete