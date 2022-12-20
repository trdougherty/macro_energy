module Units

export parseMetric

function parseMetric(energy_values::Real)
    energy_values * 0.00315
end

function parseMetric(energy_values::Vector{Real})
    energy_values .* 0.00315
end
end