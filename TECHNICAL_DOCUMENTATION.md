# HU-1: Citizen Waste Reporting Node
Technical Implementation: Integrated Geolocator and Camera packages to capture real-time metadata.

**Validation:**
[x] Auto-extraction of Latitude and Longitude.
[x] Category selection (Critical Point vs. Recycling).
[x] Image state persistence for cloud upload simulation.

**AWS Alignment:** 
Uses S3 for image storage and DynamoDB for metadata indexing.

# HU-2 & HU-3: Recycler Logistics & State Machine
Technical Implementation: Developed a reactive state machine to handle collection lifecycles.

**Logic Flow:** 
Available ➔ In Progress (Claimed by Recycler) ➔ Completed.

**Geospatial Logic:** 
Implementation of a 5km radius filter using Haversine formula (simulated in MockService) to prevent recycler burnout and optimize routes.

**Validation:**
[x] Real-time UI updates when a pin status changes.
[x] Visual feedback (SnackBars) for action confirmation.

# HU-4: Administrative BI Dashboard
Technical Implementation: Data aggregation engine that transforms raw reports into environmental metrics.

**Environmental Formulas:**
- CO2 Saved = Total Mass (kg) x 2.5
- Landfill Diversion = SUM(Completed Reports)

**Validation:**
[x] Interactive Heatmap showing waste density in Medellín.
[x] Dynamic counters for social and environmental impact.