import { Paper, Typography, Chip, Box } from "@mui/material";

const severityTone = {
  Critical: "error",
  High: "warning",
  Medium: "info",
  Stable: "success",
};

export default function CaseDetailsPanel({ selectedCase }) {
  return (
    <Paper className="panel-card" sx={{ p: 1.5 }}>
      <Box sx={{ display: "flex", alignItems: "center", justifyContent: "space-between", mb: 1.2 }}>
        <Typography variant="subtitle1" sx={{ fontWeight: 700 }}>
          Case Details
        </Typography>
        <Chip size="small" color={severityTone[selectedCase?.severity] || "default"} label={selectedCase?.severity} />
      </Box>

      <Box className="vitals-grid">
        <Box>
          <Typography className="metric-label">SpO2</Typography>
          <Typography className="metric-value">{selectedCase?.vitals?.spo2}%</Typography>
        </Box>
        <Box>
          <Typography className="metric-label">Heart Rate</Typography>
          <Typography className="metric-value">{selectedCase?.vitals?.hr} bpm</Typography>
        </Box>
        <Box>
          <Typography className="metric-label">Blood Pressure</Typography>
          <Typography className="metric-value">{selectedCase?.vitals?.bp}</Typography>
        </Box>
      </Box>

      <Typography className="metric-label" sx={{ mt: 1.3 }}>
        Symptoms
      </Typography>
      <Box sx={{ display: "flex", gap: 0.8, flexWrap: "wrap", mb: 1.2 }}>
        {(selectedCase?.symptoms || []).map((symptom) => (
          <Chip key={symptom} size="small" label={symptom} variant="outlined" />
        ))}
      </Box>

      <Typography className="metric-label">Required Resources</Typography>
      <Box sx={{ display: "flex", gap: 0.8, flexWrap: "wrap" }}>
        {(selectedCase?.requiredResources || []).map((resource) => (
          <Chip key={resource} size="small" color="primary" label={resource} />
        ))}
      </Box>
    </Paper>
  );
}