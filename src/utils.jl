"""
    to_unit_cube(x, lb, ub)

Affine linear map from [lb, ub] to [0,1]^dim.
"""
function to_unit_cube(x, lb, ub)
    if length(lb) != length(ub) || !all(lb .<= ub)
        throw(ArgumentError("lowerbounds, upperbounds have different lengths or
                        lowerbounds are not componentwise less or equal to upperbounds"))
    end
    (x .- lb) ./ (ub .- lb)
end

"""
    from_unit_cube(x, lb, ub)

Affine linear map from [0,1]^dim to [lb, ub].
"""
function from_unit_cube(x, lb, ub)
    if length(lb) != length(ub) || !all(lb .<= ub)
        throw(ArgumentError("lowerbounds, upperbounds have different lengths or
                        lowerbounds are not componentwise less or equal to upperbounds"))
    end
    x .* (ub .- lb) .+ lb
end
