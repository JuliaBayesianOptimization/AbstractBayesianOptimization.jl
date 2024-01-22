abstract type AbstractTask end

struct GetBoxConstraints <: AbstractTask end
struct GetSense <: AbstractTask end

"""
Evaluate the objective function at points `xs`.
"""
struct EvalObjective <: AbstractTask
    xs
end

function log_task(_::GetBoxConstraints)
    @info "Task: GetBoxConstraints"
end

function log_task(_::GetSense)
    @info "Task: GetSense"
end

function log_task(task::EvalObjective)
    @info "Task: EvalObjective; xs = $(task.xs)"
end
