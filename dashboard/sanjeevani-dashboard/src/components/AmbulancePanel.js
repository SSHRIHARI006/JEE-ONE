import { Paper, Typography, Button } from "@mui/material";

export default function AmbulancePanel({ selectedCase, onAssignAmbulance }) {
  return (
    <Paper className="panel-card" sx={{ p: 1.5 }}>
      <Typography variant="subtitle1" sx={{ fontWeight: 700, mb: 1.1 }}>
        Ambulance
      </Typography>

      <Typography sx={{ fontSize: 12.5, opacity: 0.88, mb: 0.5 }}>
        Assigned Unit: {selectedCase?.ambulance?.id || "None"}
      </Typography>
      <Typography sx={{ fontSize: 12.5, opacity: 0.88, mb: 1.2 }}>
        Status: {selectedCase?.ambulance?.status || "available"}
      </Typography>

      <Button
        variant="contained"
        color="error"
        fullWidth
        disabled={Boolean(selectedCase?.ambulance?.id)}
        onClick={onAssignAmbulance}
      >
        {selectedCase?.ambulance?.id ? "Ambulance Assigned" : "Assign Nearest Ambulance"}
      </Button>
    </Paper>
  );
}