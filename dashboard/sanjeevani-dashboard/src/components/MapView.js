import { useEffect, useState } from "react";
import { Paper, Typography, Box, Chip } from "@mui/material";
import { MapContainer, TileLayer, Marker, Polyline, useMap } from "react-leaflet";
import L from "leaflet";
import "leaflet/dist/leaflet.css";

const ORS_API_KEY =
  "eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6IjMyMGNjOGI4ODc2YTQ4NTI4ZTMzNmYwNGI3NjE0YmNiIiwiaCI6Im11cm11cjY0In0=";

const PUNE_CENTER = [18.5204, 73.8567];

const compatibilityTone = {
  full: "success",
  partial: "warning",
  risky: "error",
};

const createIcon = (label, color) =>
  L.divIcon({
    className: "custom-div-icon",
    html: `<div style="background-color:${color};width:30px;height:30px;border-radius:50%;display:flex;align-items:center;justify-content:center;color:white;font-weight:bold;border:2px solid white;box-shadow:0 4px 6px rgba(0,0,0,0.3);">${label}</div>`,
    iconSize: [30, 30],
    iconAnchor: [15, 15],
  });

function ChangeView({ center }) {
  const map = useMap();
  useEffect(() => {
    if (center) map.flyTo(center, 13, { animate: true });
  }, [center, map]);
  return null;
}

export default function MapView({ selectedCase, selectedHospital }) {
  const [routeCoords, setRouteCoords] = useState([]);

  // Real GPS positions from API data
  const patientPos =
    selectedCase?.location?.lat
      ? [selectedCase.location.lat, selectedCase.location.lng]
      : PUNE_CENTER;

  const hospitalPos =
    selectedHospital?.latitude
      ? [selectedHospital.latitude, selectedHospital.longitude]
      : null;

  // Use ambulance GPS if available, otherwise simulate offset from patient
  const ambulancePos =
    selectedCase?.ambulance?.lat
      ? [selectedCase.ambulance.lat, selectedCase.ambulance.lng]
      : [patientPos[0] + 0.008, patientPos[1] - 0.008];

  // Fetch real road route via ORS whenever case or hospital changes
  useEffect(() => {
    if (!selectedCase || !hospitalPos) {
      setRouteCoords([]);
      return;
    }

    const fetchRoute = async () => {
      try {
        const res = await fetch(
          "https://api.openrouteservice.org/v2/directions/driving-car/geojson",
          {
            method: "POST",
            headers: {
              Authorization: ORS_API_KEY,
              "Content-Type": "application/json",
            },
            body: JSON.stringify({
              coordinates: [
                [ambulancePos[1], ambulancePos[0]], // ORS: [lng, lat]
                [patientPos[1], patientPos[0]],
                [hospitalPos[1], hospitalPos[0]],
              ],
            }),
          }
        );
        const data = await res.json();
        if (data.features?.length > 0) {
          const pts = data.features[0].geometry.coordinates.map((c) => [c[1], c[0]]);
          setRouteCoords(pts);
        }
      } catch (err) {
        console.error("ORS route error:", err);
      }
    };

    fetchRoute();
  }, [selectedCase?.id, selectedHospital?.id]);

  return (
    <Paper
      className="panel-card map-card"
      sx={{ height: "500px", display: "flex", flexDirection: "column", overflow: "hidden" }}
    >
      <Box
        sx={{ p: 2, display: "flex", justifyContent: "space-between", borderBottom: "1px solid #eee" }}
      >
        <Box>
          <Typography variant="subtitle1" fontWeight={700}>
            EOR Situational Map
          </Typography>
          <Typography variant="caption" sx={{ opacity: 0.7 }}>
            Case: {selectedCase?.id || "--"} | GPS:{" "}
            {patientPos[0].toFixed(4)}, {patientPos[1].toFixed(4)}
          </Typography>
        </Box>
        <Chip
          size="small"
          color={compatibilityTone[selectedHospital?.compatibility] || "default"}
          label={selectedHospital ? `Route: ${selectedHospital.name}` : "Pending Selection..."}
        />
      </Box>

      <Box sx={{ flexGrow: 1, position: "relative" }}>
        <MapContainer center={patientPos} zoom={13} style={{ height: "100%", width: "100%" }}>
          <TileLayer url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png" />
          <ChangeView center={patientPos} />

          {routeCoords.length > 0 && (
            <Polyline
              positions={routeCoords}
              pathOptions={{ color: "#1890ff", weight: 5, opacity: 0.8 }}
            />
          )}

          <Marker position={patientPos} icon={createIcon("P", "#ff4d4f")} />
          {hospitalPos && (
            <Marker position={hospitalPos} icon={createIcon("H", "#2e7d32")} />
          )}
          <Marker position={ambulancePos} icon={createIcon("🚑", "#0288d1")} />
        </MapContainer>
      </Box>
    </Paper>
  );
}
