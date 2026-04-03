import { useEffect, useMemo, useState } from "react";
import { Paper, Typography, Box, Chip } from "@mui/material";

const compatibilityTone = {
  full: "success",
  partial: "warning",
  risky: "error",
};

export default function MapView({ selectedCase, selectedHospital }) {
  const patient = selectedCase?.location || { x: 30, y: 50, label: "Unknown" };
  const ambulanceStart = {
    x: Math.max(6, patient.x - 18),
    y: Math.max(8, patient.y - 20),
  };

  const [travelProgress, setTravelProgress] = useState(0);

  useEffect(() => {
    setTravelProgress(0);
    const timer = setInterval(() => {
      setTravelProgress((prev) => (prev >= 1 ? 0 : prev + 0.02));
    }, 130);

    return () => clearInterval(timer);
  }, [selectedCase?.id, selectedHospital?.id]);

  const activeHospitalPos = selectedHospital?.position || { x: 70, y: 30 };

  const ambulancePosition = useMemo(() => {
    if (travelProgress <= 0.5) {
      const t = travelProgress / 0.5;
      return {
        x: ambulanceStart.x + (patient.x - ambulanceStart.x) * t,
        y: ambulanceStart.y + (patient.y - ambulanceStart.y) * t,
      };
    }

    const t = (travelProgress - 0.5) / 0.5;
    return {
      x: patient.x + (activeHospitalPos.x - patient.x) * t,
      y: patient.y + (activeHospitalPos.y - patient.y) * t,
    };
  }, [activeHospitalPos.x, activeHospitalPos.y, ambulanceStart.x, ambulanceStart.y, patient.x, patient.y, travelProgress]);

  return (
    <Paper className="panel-card map-card">
      <Box className="map-head">
        <Box>
          <Typography variant="subtitle1" sx={{ fontWeight: 700 }}>
            Live Situational Map
          </Typography>
          <Typography sx={{ fontSize: 12, opacity: 0.7 }}>
            Case {selectedCase?.id} | {selectedCase?.location?.label}
          </Typography>
        </Box>
        <Chip
          size="small"
          color={compatibilityTone[selectedHospital?.compatibility] || "default"}
          label={selectedHospital ? `Route: ${selectedHospital.name}` : "No Hospital Selected"}
        />
      </Box>

      <Box className="map-surface">
        <svg className="route-layer" viewBox="0 0 100 100" preserveAspectRatio="none">
          <polyline
            points={`${ambulanceStart.x},${ambulanceStart.y} ${patient.x},${patient.y} ${activeHospitalPos.x},${activeHospitalPos.y}`}
            className="route-line-base"
          />
          <polyline
            points={`${ambulanceStart.x},${ambulanceStart.y} ${patient.x},${patient.y} ${activeHospitalPos.x},${activeHospitalPos.y}`}
            className="route-line"
            style={{ strokeDasharray: "160", strokeDashoffset: `${160 - travelProgress * 160}` }}
          />
        </svg>

        <Box className="map-marker ambulance pulse-soft" sx={{ left: `${ambulancePosition.x}%`, top: `${ambulancePosition.y}%` }}>
          A
        </Box>

        <Box className="map-marker patient pulse-strong" sx={{ left: `${patient.x}%`, top: `${patient.y}%` }}>
          P
        </Box>

        {(selectedCase?.hospitals || []).map((hospital) => (
          <Box
            key={hospital.id}
            className={`map-marker hospital pulse-soft ${selectedHospital?.id === hospital.id ? "selected" : ""}`}
            sx={{ left: `${hospital.position.x}%`, top: `${hospital.position.y}%` }}
            title={`${hospital.name} (${hospital.eta} min)`}
          >
            H
          </Box>
        ))}

        <Box className="map-legend">
          <Typography sx={{ fontSize: 11 }}>P: Patient</Typography>
          <Typography sx={{ fontSize: 11 }}>A: Ambulance</Typography>
          <Typography sx={{ fontSize: 11 }}>H: Hospital</Typography>
        </Box>
      </Box>
    </Paper>
  );
}