# HU-1: Citizen Waste Reporting (Input Node)
## feat: citizen georeferenced waste reporting

Description: As a Citizen, I want to report critical waste points or schedule a recycling pickup using my GPS location and camera, so that I can contribute to the city's cleanliness and sustainability.

**Acceptance Criteria (DoD):**
- System must capture current GPS coordinates (Lat/Lng) automatically.
- System must allow image upload/capture to document the waste type.

# HU-2: Recycler Route Optimization (Operational Node)
## feat: recycler proximity-based map visualization

Description: As a Recycler, I want to view a real-time map with the nearest collection points, so that I can optimize my physical effort and increase my daily material recovery rate.

**Acceptance Criteria (DoD):**
- Map must display pins filtered by proximity (5km radius).
- Pins must be color-coded by type (e.g., Green for Recycling, Red for Critical).
- Recycler must be able to "Claim" a point, changing its state to IN_TRANSIT.

# HU-3: Operational Lifecycle Management (State Machine)
## feat: waste collection lifecycle management

Description: As a Recycler, I want to update the status of a collection point to 'Completed', so that the system can verify the impact and remove the pin from the public map.

**Acceptance Criteria (DoD):**
- Transition states: PENDING ➔ IN_TRANSIT ➔ COMPLETED.
- Once COMPLETED, the record must be archived for administrative analytics.

# HU-4: Administrative Intelligence Dashboard (Data Node)
## feat: admin geospatial analytics & impact metrics

Description: As an Administrator (Authority), I want to visualize a heatmap of waste accumulation and environmental impact metrics, so that I can make data-driven decisions for Medellín’s urban management.

**Acceptance Criteria (DoD):**
- Display a Heatmap based on report density per neighborhood (Comunas).
- Real-time dashboard showing: Total Mass Diverted (Tons) and C02 Emission Offset.
- Filter reports by material type (Plastic, Glass, Paper, Metal).