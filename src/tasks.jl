abstract type AbstractTask end

struct GetLowerbound <: AbstractTask end
struct GetUpperbound <: AbstractTask end
struct GetSense <: AbstractTask end

"""
Evaluate the objective function at points `xs`.
"""
struct EvalObjective <: AbstractTask
    xs
end

function log_task(_::GetLowerbound)
    @info "Task: GetLowerbound"
end

function log_task(_::GetUpperbound)
    @info "Task: GetUpperbound"
end

function log_task(_::GetSense)
    @info "Task: GetSense"
end

function log_task(task::EvalObjective)
    @info "Task: EvalObjective; xs = $(task.xs)"
end
