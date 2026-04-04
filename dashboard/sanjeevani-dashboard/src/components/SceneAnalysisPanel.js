import { Paper, Typography, Chip, Box, LinearProgress } from "@mui/material";

const severityColor = (score) => {
  if (score >= 8) return "#ef4444";
  if (score >= 5) return "#f59e0b";
  if (score >= 3) return "#3b82f6";
  return "#6b7280";
};

const bloodSeverityColor = {
  severe: "#ef4444",
  significant: "#ef4444",
  moderate: "#f59e0b",
  minor: "#3b82f6",
  none: "#6b7280",
};

export default function SceneAnalysisPanel({ sceneContext }) {
  if (!sceneContext || !sceneContext.scene_summary) {
    return (
      <Paper className="panel-card" sx={{ p: 1.5 }}>
        <Typography variant="subtitle1" sx={{ fontWeight: 700, mb: 0.5 }}>
          🔍 Scene Analysis
        </Typography>
        <Typography variant="body2" sx={{ color: "#94a3b8", fontStyle: "italic" }}>
          No scene photo submitted for this case.
        </Typography>
      </Paper>
    );
  }

  const severity = sceneContext.severity_estimate || 0;
  const mechanism = sceneContext.mechanism_of_injury || "unknown";
  const patientCount = sceneContext.patient_count || 1;
  const consciousness = sceneContext.consciousness_estimate || "unclear";
  const injuries = sceneContext.visible_injuries || [];
  const blood = sceneContext.blood_loss || {};
  const hazards = sceneContext.scene_hazards || [];
  const vehicleDamage = sceneContext.vehicle_damage_severity || "none";
  const resources = sceneContext.recommended_resources || [];
  const summary = sceneContext.scene_summary || "";

  return (
    <Paper className="panel-card" sx={{ p: 1.5 }}>
      {/* Header row */}
      <Box sx={{ display: "flex", alignItems: "center", justifyContent: "space-between", mb: 1.2 }}>
        <Typography variant="subtitle1" sx={{ fontWeight: 700 }}>
          🔍 AI Scene Analysis
        </Typography>
        <Chip
          size="small"
          label={`Severity ${severity}/10`}
          sx={{
            fontWeight: 700,
            bgcolor: severityColor(severity) + "22",
            color: severityColor(severity),
            border: `1px solid ${severityColor(severity)}44`,
          }}
        />
      </Box>

      {/* Severity bar */}
      <Box sx={{ mb: 1.5 }}>
        <LinearProgress
          variant="determinate"
          value={severity * 10}
          sx={{
            height: 6,
            borderRadius: 3,
            bgcolor: "#1e293b",
            "& .MuiLinearProgress-bar": {
              bgcolor: severityColor(severity),
              borderRadius: 3,
            },
          }}
        />
      </Box>

      {/* Mechanism + Patient count */}
      <Box className="vitals-grid" sx={{ mb: 1 }}>
        <Box>
          <Typography className="metric-label">Mechanism</Typography>
          <Typography className="metric-value" sx={{ textTransform: "capitalize" }}>
            {mechanism}
          </Typography>
        </Box>
        <Box>
          <Typography className="metric-label">Victims</Typography>
          <Typography className="metric-value">{patientCount}</Typography>
        </Box>
        <Box>
          <Typography className="metric-label">Consciousness</Typography>
          <Typography className="metric-value" sx={{ textTransform: "capitalize" }}>
            {consciousness}
          </Typography>
        </Box>
      </Box>

      {/* Visible injuries */}
      {injuries.length > 0 && (
        <Box sx={{ mb: 1 }}>
          <Typography className="metric-label" sx={{ mb: 0.5 }}>
            Visible Injuries
          </Typography>
          <Box sx={{ display: "flex", gap: 0.5, flexWrap: "wrap" }}>
            {injuries.map((inj) => (
              <Chip
                key={inj}
                size="small"
                label={inj}
                sx={{
                  bgcolor: "#ef444422",
                  color: "#fca5a5",
                  border: "1px solid #ef444444",
                  fontWeight: 600,
                  fontSize: "0.7rem",
                }}
              />
            ))}
          </Box>
        </Box>
      )}

      {/* Blood loss */}
      {blood.present && (
        <Box sx={{ mb: 1, display: "flex", alignItems: "center", gap: 1 }}>
          <Typography className="metric-label" sx={{ mb: 0 }}>
            Blood Loss:
          </Typography>
          <Chip
            size="small"
            label={blood.severity || "unknown"}
            sx={{
              fontWeight: 700,
              textTransform: "capitalize",
              bgcolor: (bloodSeverityColor[blood.severity] || "#6b7280") + "22",
              color: bloodSeverityColor[blood.severity] || "#6b7280",
            }}
          />
        </Box>
      )}

      {/* Vehicle + Hazards row */}
      <Box className="vitals-grid" sx={{ mb: 1 }}>
        <Box>
          <Typography className="metric-label">Vehicle Damage</Typography>
          <Typography className="metric-value" sx={{ textTransform: "capitalize" }}>
            {vehicleDamage}
          </Typography>
        </Box>
        <Box sx={{ gridColumn: "span 2" }}>
          <Typography className="metric-label">Scene Hazards</Typography>
          <Box sx={{ display: "flex", gap: 0.4, flexWrap: "wrap", mt: 0.3 }}>
            {hazards.length > 0 ? (
              hazards.map((h) => (
                <Chip
                  key={h}
                  size="small"
                  label={h}
                  variant="outlined"
                  sx={{ fontSize: "0.65rem", color: "#f59e0b", borderColor: "#f59e0b44" }}
                />
              ))
            ) : (
              <Typography variant="caption" sx={{ color: "#64748b" }}>
                None reported
              </Typography>
            )}
          </Box>
        </Box>
      </Box>

      {/* Recommended resources */}
      {resources.length > 0 && (
        <Box sx={{ mb: 1 }}>
          <Typography className="metric-label" sx={{ mb: 0.5 }}>
            Recommended Resources
          </Typography>
          <Box sx={{ display: "flex", gap: 0.5, flexWrap: "wrap" }}>
            {resources.map((r) => (
              <Chip key={r} size="small" color="primary" label={r} sx={{ fontWeight: 600, fontSize: "0.7rem" }} />
            ))}
          </Box>
        </Box>
      )}

      {/* Scene summary */}
      <Box
        sx={{
          mt: 1,
          p: 1.2,
          borderRadius: 2,
          bgcolor: "#0f172a",
          border: "1px solid #1e293b",
        }}
      >
        <Typography variant="caption" sx={{ color: "#64748b", fontWeight: 700, letterSpacing: 0.5 }}>
          SCENE SUMMARY
        </Typography>
        <Typography variant="body2" sx={{ color: "#cbd5e1", mt: 0.5, lineHeight: 1.5 }}>
          {summary}
        </Typography>
      </Box>
    </Paper>
  );
}
