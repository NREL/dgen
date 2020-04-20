Rooftop availability and orientations are derived from a combination of empirical data from CBECS and RECS, along with a set of general assumptions. When customer types in the model are sampled from the CBECS and RECS microdata, they are assigned not only a value for annual electricity consumption, but several attributes about the size and construction of the associated residential or building. 

Information on the size and orientation of the roof is not included in these attributes; however, we use ancillary attributes to estimate the size of the roof and whether it is pitched or flat. 

Roof size is calculated from the total square footage of the building and the number of floors or stories, as follows:
	total roof area  = total square footage / number of floors

The roof style (pitched or flat) is then determined from the roofing material desciption (ROOFTYPE in RECS, RFCNS in CBECS). For CBECS, we followed the same assumptions as SolarDS:
		Built-up							flat
		Slate or tile shingles				pitched
		Wood shingles/shakes/other wood		pitched
		Asphalt/fiberglass/other shingles	pitched
		Metal surfacing						flat
		Plastic/rubber/synthetic sheeting	flat
		Concrete							flat
		No one major type					flat
		Other								flat
RECS was not used in this way in SolarDS, so we mapped roofing materials as follows:
		Ceramic or Clay Tiles				pitched
		Wood Shingles/Shakes				pitched
		Metal								pitched
		Slate or Synthetic Slate			pitched
		Composition Shingles				pitched
		Asphalt								pitched
		Concrete Tiles						pitched
		Other								flat
We assumed that the "Other" category in RECS encompassed the most common materials used for flat roofing on residential structures, including Plastic/rubber/synthetic sheeting, Modified Bitumen, and Built Up Roof.

For pitched roofs, we assumed that 50% were 2-sided roofs and 50% were 4-sided roofs. For each pitched roof type, we then assumed a uniform distribution of building orientations, as follows:

4-Sided Pitched Roofs Orientations
N-S-E-W = 50%
NW-NE-SE-SW = 50%

2-Sided Pitched Roofs
N-S = 25%
E-W = 25%
NW-SE = 25%
NE-SW = 25%

We assumed all pitched roofs to be angled at 25 degrees from horizontal. For each pitched roof type and orientation, we then assumed panels would only be constructed a single roof side (i.e., roof plane). In other words, for 4-sided roofs, the total rooftop area was scaled down by factors of 0.25 and 0.5 for 2- and 4-sided roofs, respectively. We then applied a multiplier based on the fact that the estimated rooftop area is based on a flat plane, using the assumed slope of 25 degrees, as follows:
	slope area multiplier = 1/cos(25 degrees) = 1.111

We selected the optimal roofplane for each pitched roof orientation as follows:

4-Sided Pitched Roofs - Optimal Roof Plane
N-S-E-W = S
NW-NE-SE-SW = SW (for coincidence with load)

2-Sided Pitched Roofs
N-S = S
E-W = W (for coincidence with load)
NW-SE = SE
NE-SW = SW

For flat roofs, we assume that the total roof area is available for installation of PV. We assume that flat systems are installed, rather than tilted arrays, due to the reduction in panel power density necessitated by the shading requirements of tilted arrays (Denholm and Margolis, 2008).

Shading is handled in dSolar in the same manner as in SolarDS. For both commercial and industrial, regional shading fractions are applied to each customer type bin to reduce the number of buildings into which PV can diffuse. For commercial, a constant factor of 80% is then applied to the available roof top on each remaining building to account for factors such as rooftop-mounted HVAC, etc.


References:
Paul Denholm, Robert M. Margolis, Land-use requirements and the per-capita solar footprint for photovoltaic generation in the United States, Energy Policy, Volume 36, Issue 9, September 2008, Pages 3531-3543

