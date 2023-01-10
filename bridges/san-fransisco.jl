### A Pluto.jl notebook ###
# v0.19.18

using Markdown
using InteractiveUtils

# ╔═╡ 25066caa-8008-11ed-2d04-e9e0658ed5d9
using GeoJSON, DataFrames, CSV, StatsBase, GeoDataFrames

# ╔═╡ a9b4440a-4704-41a2-9281-ca2f24261d84
using GeoFormatTypes

# ╔═╡ 1a3e1b04-cf81-4cc2-8714-2d7e543a918a
using Plots

# ╔═╡ d75b99f3-3936-4ce1-8138-b04764651ddd
using ArchGDAL

# ╔═╡ e51ab25b-0a52-4dcb-9125-b35cbf149e41
using LazySets

# ╔═╡ 5a9a02b5-1041-47a0-9501-c69ec836f1b2
# include("utils/units.jl"); # typically want to include this in a file

# ╔═╡ 5239bee1-72f4-48cc-98b9-4ea96c1bb3ee
md"""
###### Using San Fransisco as an example
"""

# ╔═╡ 6627e69f-9f07-4eb4-ac24-5048054947d6
city = joinpath("data", "san-fransisco")

# ╔═╡ f3c2c1a3-13e5-4d5b-859c-9937adbc7df4
energy_file = joinpath(city, "energy.csv")

# ╔═╡ 99ea3428-1c9f-4e55-a4fb-9a2d4b1ce344
energy_geolocations_file = joinpath(city, "sf-geolocated.csv")

# ╔═╡ 04c04b46-a98e-4190-aaf8-0af492472189
footprints_file = joinpath(city, "footprints.geojson")

# ╔═╡ a0294d33-ac86-4562-9f63-c6867be54f54


# ╔═╡ 8ab4f900-901d-4725-8b73-8fae514ee7c5
md"""
###### Now extracting information about each of these datasets and processing it into a digestible format. 

_Note:_ The latitudes and longitudes used by SF to link each building are terrible (the location they give is in the middle of the street). I used [this](https://www.geocod.io/) website to geocode the street addresses to lat lons by just uploading the csv doc. Quality seem pretty great and it only cost me like ~$1. I'm happy to pay for it again if it saves us more than 10 minutes of time
"""

# ╔═╡ 115c39d1-743a-4d8f-9e2f-301eeb6cec0a
energy = CSV.read(energy_geolocations_file, DataFrame)

# ╔═╡ 25754513-175b-4fc1-9025-01353bc39782
# ╠═╡ disabled = true
#=╠═╡
energy = CSV.read(energy_file, DataFrame; delim=',', ntasks=1);
  ╠═╡ =#

# ╔═╡ 05fa79b9-52a0-4194-a4e9-0d7e2e78326c
md"""
Huge variety of column names, we really just want a few:
"""

# ╔═╡ f0f2447c-080d-42a5-9221-284c3aa52d19
names(energy)

# ╔═╡ 4c39c315-f998-4469-8442-0cc2b25b842d
md"""
Initial Preprocesing to make sure we can extract what we want
"""

# ╔═╡ ecb7e92d-ab9c-475b-9db4-d59aa9f27711
# dropmissing!(energy, Symbol("Full.Address"));

# ╔═╡ 6c95fffd-d00b-4191-a02f-4f0dfc7795c9
# filter!( x -> length(split(x["Full.Address"], "\n")) ≥ 3, energy);

# ╔═╡ c3e943a9-59ba-4a76-a209-0b5c33e293dd
begin
locations::Vector{Vector{Float64}} = []
for i = 1:nrow(energy)
	push!(locations, [energy.Longitude[i], energy.Latitude[i]])
end
end

# ╔═╡ c4bce56a-c268-49da-904f-3b6a71dadb1d
begin
	# locations = [ parse.(Float64, split(strip(split(x, "\n")[3], ['(',')']), ", ")) for x in energy[:,"Full.Address"] ]
	# locations′ = [ [x[2],x[1]] for x in locations ]
	
	# energy[:, "latitude" ] = first.(locations)
	# energy[:, "longitude"] = last.(locations)
	# energy[:, "id"] 	   = string.(hash.(energy[:,"Full.Address"]))
	energy[:, "geometry"]  = ArchGDAL.createpoint.(locations)

	location_terms = ["latitude", "longitude"]
end;

# ╔═╡ b5cae365-b65e-4217-8c8b-99fa841b4d3c
locations

# ╔═╡ e036033d-c228-418c-9986-1f1b68a9fa40
energy.geometry

# ╔═╡ 9f0f78c2-f1d3-4efe-bba2-edb63f8a4ced
locations_region = ArchGDAL.closerings!(ArchGDAL.createpolygon(convex_hull(locations)))

# ╔═╡ bb71c3be-ff5c-4da5-b00c-3c8056786810
md"""
Sample of the bounding box for the city data:
"""

# ╔═╡ f9aee858-6158-4817-bb17-3a5f5db573b4
begin
Plots.plot(locations_region, color="white")

Plots.plot!(energy.geometry, color="black")
Plots.plot!(energy.geometry[100], color="red")

test_region = ArchGDAL.buffer(energy.geometry[100], 0.003)
Plots.plot!(test_region, color="red", alpha=0.5)
end

# ╔═╡ 71984149-3905-424c-be5d-d9408740410e
test_points = filter(x -> ArchGDAL.contains(test_region, x.geometry), energy);

# ╔═╡ 9382193e-d531-439e-a0ae-d6e16a7144a9
md"""
Test region
"""

# ╔═╡ 5e72d441-440e-4a75-9b31-e6b09cb56fa1
energy_columns = [ string(x) * " Site EUI (kBtu/ft2)" for x in collect(2011:2021) ];

# ╔═╡ 658c10fc-78ae-4157-8281-aac04de6a999
begin
name_mapping = []
years = string.(collect(2011:2021))
for (i, term) in enumerate(energy_columns)
	push!(name_mapping, Pair(term, years[i]))
end
name_mapping
end

# ╔═╡ 97b349ea-7d56-40b3-a750-8b61d271a42d
rename!(energy, name_mapping...);

# ╔═╡ 80ca82ce-f7e5-4f24-b44a-159fff71f8d1
md"""
##### Building Footprints
"""

# ╔═╡ e3eb78d5-ad22-4465-9fc5-92ed9953b070
begin
footprints = select(GeoDataFrames.read(footprints_file), [:geometry, :globalid]);
rename!(footprints, :globalid => :id)
footprints.id = string.(hash.(footprints.id))

filter!(
	x -> GeoDataFrames.contains(locations_region, ArchGDAL.centroid(x.geometry)), footprints 
);
end

# ╔═╡ 674f797b-5e6e-4298-9eb9-9714c5d0f9da
test_buildings = filter(x -> ArchGDAL.contains(test_region, x.geometry), footprints);

# ╔═╡ d0bcaf10-0e79-425f-b2b6-a1d66afe49c1
begin
Plots.plot(test_buildings.geometry, color="white")
Plots.plot!(test_points.geometry, color="indianred")
end

# ╔═╡ 07787662-a45b-4770-bb2a-c73fb205b02d
@info nrow(footprints)

# ╔═╡ e4a16264-52ef-4ca4-932b-973b09966274
begin
	regionlist = []
	for building_point in energy.geometry
		footprint_id = missing
		for (boundary_index, boundary_geom) in enumerate(footprints.geometry)
			if GeoDataFrames.contains(boundary_geom, building_point)
				footprint_id = footprints[boundary_index, "id"]
				break
			end
		end
		push!(regionlist, footprint_id)
	end
end

# ╔═╡ a1a59fb6-6b77-4ef7-9460-d44168a88330
regionlist

# ╔═╡ fb7022f6-53d8-40a7-9129-913dae62a564
md"""
hmmm... something is wrong here. let's take a small sample of buildings and see what's happening.
"""

# ╔═╡ 9afc732e-dd56-493d-afb4-342e1ab7a398
regionlist

# ╔═╡ fd874732-2c12-4eb5-bb2f-d4ca50f90c35
nrow(energy)

# ╔═╡ 2ce8e3db-2951-45a9-8fe9-aa5c25f108a9
length(regionlist)

# ╔═╡ 8fd3d1ac-1e8d-4208-9c87-d4321cb80a98
energy[:,:footprint_id] = regionlist

# ╔═╡ 7eeff048-004a-4389-8693-a22e1750d6b3
begin
dropmissing!(energy, :footprint_id)
unique!(energy, :footprint_id)
end;

# ╔═╡ 0979c276-1226-49df-877c-eeca6d6c2d48
energyᵪ = select(energy, ["footprint_id", "Floor Area", "geometry", years...]);

# ╔═╡ df643f5f-312a-44c7-ad90-5f5eb90194ee
energyₖ = dropmissing(stack(energyᵪ, years));

# ╔═╡ a4939d43-ec3e-4c91-9aab-e23d4d19d459
@info "Number of unique buildings:" length(unique(energyₖ.footprint_id))

# ╔═╡ 3c7a5238-5ef3-403d-acd8-c85e54012bb5
energyₖ[:,"year"] = parse.(Int16, energyₖ[:,"variable"]);

# ╔═╡ 05bc8893-44eb-4bd0-a8f8-b1535d8f1e5b
md"""
###### Energy should always be stored in units of MWh
"""

# ╔═╡ c0052413-6d50-45e2-974b-d38239a3efbf
energyₖ[:,"energy"] = energyₖ[:,"Floor Area"] .* energyₖ[:,"value"] .* 0.00029301453352086; # should use the util for units, Pluto makes it hard to work with modules

# ╔═╡ 3bb0f502-9ef8-442f-bc79-5f2130033625
begin
energyₖ[:,"area"] = energyₖ[:,"Floor Area"] .* 0.092903
select!(energyₖ, :footprint_id, :geometry, :year, Not(["value", "variable", "Floor Area"]))
end

# ╔═╡ 68b5faff-18f1-4eed-a92f-c46fccad7df4
Plots.histogram(
	energyₖ.year, 
	color="white", 
	bins=length(unique(energyₖ.year)),
	xticks = 2011:2021
)

# ╔═╡ 63af50ae-f9ee-4997-b154-067b38c3ac56
unique(energyₖ.year)

# ╔═╡ 4c63bb6d-e8cf-4a41-b48f-4f2f9773c04f
energyₒ = combine(groupby(energyₖ, :year), :energy => sum, renamecols=false)

# ╔═╡ 702ec963-9ed2-47ca-b054-1338178851f2
md"""
So this is the percent of the total apparent energy from sf (18,000 MWh per day), which seems right on par with the regular estimate that buildings use about 40% of total energy
"""

# ╔═╡ 63f5f29a-5ec0-407a-a9f4-6a285bacf8fa
energyₒ.energy ./ (18000 * 365)

# ╔═╡ f2e512c6-8be2-459f-93f1-81ca0170ae41
md"""
Might want to ignore the data from 2011, it looks a bit sus
"""

# ╔═╡ 7bf8836c-92ba-42cf-9c8a-1379e4eff2f7
filter!(x -> x.year > 2011, energyₖ);

# ╔═╡ c7d21486-ab1f-4252-a723-31a0936468f6


# ╔═╡ a81b33e9-0d2b-47ee-bd5f-5ee3b0e16d6a
# now we finally have two cleaned datasets which are ready to work with the rest of the analysis!

# ╔═╡ fc5e5d2a-71d7-46e0-864d-21662fd694af
energyₖ

# ╔═╡ beedb78b-fc11-49a5-8b95-9f784d75891e
energy_out = joinpath(city, "prepped", "energy-k.csv")
CSV.write(energy_out, select(energyₖ, Not([:geometry])))

# ╔═╡ f6118bdd-844e-4261-a1bd-b57325395bf6
footprintsₖ = filter(x -> x.id ∈ string.(unique(energyₖ.footprint_id)), footprints)

# ╔═╡ 72c52f0c-edd9-4e24-807a-f9444282e780
footprints_out = joinpath(city, "prepped", "footprints-k.geojson")
GeoDataFrames.write(footprints_out, footprintsₖ; geom_column=:geometry, crs=GeoFormatTypes.EPSG(4326), driver="GeoJSON")