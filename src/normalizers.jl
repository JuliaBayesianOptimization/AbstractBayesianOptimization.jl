# Idea: normalizers should be used by the DSM when getting / sending request that containts
# points from domain or objective values, at the initialization of DSM a DomainNormalizer and
# SenseNormalizer is created

"""
Convert between box constraint domain from and into a unit cube.
"""
struct DomainNormalizer{ S <: Real}
    # original box constraints
    lb::Vector{S}
    ub::Vector{S}
end

"""
    normalize(x, domain_normalizer)

Affine linear map from [domain_normalizer.lb, domain_normalizer.ub] to [0,1]^dim.
"""
function normalize(x, domain_normalizer::DomainNormalizer)
    lb, ub = domain_normalizer.lb, domain_normalizer.ub
    if length(lb) != length(ub) || !all(lb .<= ub)
        throw(ArgumentError("lowerbounds, upperbounds have different lengths or
                        lowerbounds are not componentwise less or equal to upperbounds"))
    end
    (x .- lb) ./ (ub .- lb)
end

"""
    unnormalize(x, domain_normalizer)

Affine linear map from [0,1]^dim to [domain_normalizer.lb, domain_normalizer.ub].
"""
function unnormalize(x, domain_normalizer::DomainNormalizer)
    lb, ub = domain_normalizer.lb, domain_normalizer.ub
    if length(lb) != length(ub) || !all(lb .<= ub)
        throw(ArgumentError("lowerbounds, upperbounds have different lengths or
                        lowerbounds are not componentwise less or equal to upperbounds"))
    end
    x .* (ub .- lb) .+ lb
end

"""
Convert minimization problems into maximization problems by multiplying objective with minus one,
maximization problems remain unchanged.
"""
struct SenseNormalizer
    # original sense
    sense::Sense
end

normalize(y, sense_normalizer::SenseNormalizer) = y * sense_normalizer.sense
unnormalize(y, sense_normalizer::SenseNormalizer) = y * sense_normalizer.sense
