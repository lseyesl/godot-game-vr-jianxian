# Town Greybox Layout

The town layout follows `docs/concept-art/Town Concept Design.png` rather than a single north-gate route. Godot coordinates use negative Z as north, positive Z as south, negative X as west, and positive X as east.

## Gates and Walls

- North gate: `GatePaifang` at `(0, 0, -32)`, using `assets/models/Gate/Gate.glb`.
- South gate: `SouthGatePaifang` at `(0, 0, 28)`, using `assets/models/Gate/Gate.glb`.
- West gate: `WestGatePaifang` at `(-24, 0, 10)`, using `assets/models/Gate/Gate.glb`.
- Wall segments live under `TownWalls` and use `assets/models/Wall/Wall_2x3.glb`.

## Main Street and Quest Anchors

- Main street runs north-south from the north gate through `MarketStreet` to the south gate.
- `MarketStreet` sits at `(0, 0, 8)`, matching the concept map's center-south market.
- `Inn` remains a top-level quest anchor at `(-12, 0, 6)`, west of the market near the canal/waterwheel route.
- `Tavern` remains a top-level quest anchor at `(10, 0, 12)`, east-southeast near the temple/tea district.
- `ReturnToTownTrigger` sits at `(12, 3, 24)` on the southeast return edge.

## District Markers

- West canal: `WestDistrict/CanalMarker` at `(-10, 0, 8)`.
- Waterwheel: `WestDistrict/WaterwheelMarker` at `(-18, 0, 10)`.
- West farmland: `WestDistrict/FarmlandWestMarker` at `(-20, 0, 2)`.
- Northwest farmland: `WestDistrict/FarmlandNorthWestMarker` at `(-22, 0, -14)`.
- Southwest farmland: `WestDistrict/FarmlandSouthWestMarker` at `(-24, 0, 20)`.
- Yamen: `EastDistrict/YamenMarker` at `(16, 0, 2)`.
- Dock: `EastDistrict/DockMarker` at `(22, 0, 10)`.
- Temple: `SouthEastDistrict/TempleMarker` at `(12, 0, 18)`.
- Granary: `NorthEastDistrict/GranaryMarker` at `(8, 0, -16)`.
- Blacksmith: `NorthEastDistrict/BlacksmithMarker` at `(14, 0, -12)`.
- Forestry: `NorthEastDistrict/ForestryMarker` at `(18, 0, -24)`.
- Fishing village: `NorthEastDistrict/FishingVillageMarker` at `(24, 0, -18)`.

This keeps the current quest flow intact while making the greybox read as the concept map's multi-gate, water-linked town.
