import { Paper, Typography, Chip, Box } from "@mui/material";

const compatibilityTone = {
  full: "success",
  partial: "warning",
  risky: "error",
};

const labels = ["Best", "Fastest", "Backup"];

export default function HospitalPanel({ selectedCase, selectedHospitalId, onSelectHospital }) {
  return (
    <Paper className="panel-card" sx={{ p: 1.5 }}>
      <Typography variant="subtitle1" sx={{ fontWeight: 700, mb: 1.4 }}>
        Hospital Recommendations
      </Typography>
      <Typography sx={{ fontSize: 11, opacity: 0.72, mb: 1.2 }}>
        Click a decision block to lock route priority.
      </Typography>

      <Box className="scroll-stack">
        {(selectedCase?.hospitals || []).slice(0, 3).map((hospital, index) => {
          const selected = selectedHospitalId === hospital.id;
          return (
            <Box
              key={hospital.id}
              className={`hospital-card ${selected ? "selected" : ""}`}
              onClick={() => onSelectHospital(hospital.id)}
            >
              <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center", gap: 1, mb: 1 }}>
                <Typography sx={{ fontSize: 13, fontWeight: 700 }}>{hospital.name}</Typography>
                <Box sx={{ display: "flex", alignItems: "center", gap: 0.8 }}>
                  <Chip size="small" color="primary" label={labels[index] || "Option"} />
                  {selected ? <Chip size="small" color="success" label="Selected" /> : null}
                </Box>
              </Box>

              <Box sx={{ display: "flex", gap: 0.8, flexWrap: "wrap", mb: 0.8 }}>
                <Chip size="small" label={`ETA ${hospital.eta}m`} />
                <Chip size="small" label={`ICU ${hospital.icu}`} />
                <Chip size="small" label={`Vent ${hospital.ventilators}`} />
                <Chip size="small" label={`Load ${hospital.load}%`} />
              </Box>

              <Chip
                size="small"
                color={compatibilityTone[hospital.compatibility] || "default"}
                label={`Compatibility: ${hospital.compatibility}`}
              />

              <Typography sx={{ fontSize: 11, opacity: 0.72, mt: 0.8 }}>
                Score = ETA + load + mismatch penalty = {hospital.score}
              </Typography>

              <Typography sx={{ fontSize: 11, opacity: selected ? 1 : 0.62, mt: 0.6, fontWeight: selected ? 700 : 500 }}>
                {selected ? "Route actively optimized for this hospital" : "Tap to select this as destination"}
              </Typography>
            </Box>
          );
        })}
      </Box>
    </Paper>
  );
}