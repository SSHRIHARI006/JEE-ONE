import { Paper, Typography, Box, Chip } from "@mui/material";

const severityTone = {
  Critical: "error",
  High: "warning",
  Medium: "info",
  Stable: "success",
};

const severityRank = {
  Critical: 4,
  High: 3,
  Medium: 2,
  Stable: 1,
};

export default function ActiveCasesTable({ activeCases, selectedCaseId, onSelectCase }) {
  const prioritizedCases = [...activeCases].sort((a, b) => {
    const bySeverity = (severityRank[b.severity] || 0) - (severityRank[a.severity] || 0);
    if (bySeverity !== 0) {
      return bySeverity;
    }
    return a.id.localeCompare(b.id);
  });

  return (
    <Paper className="panel-card" sx={{ p: 1.5, flex: 1, minHeight: 220 }}>
      <Typography variant="subtitle1" sx={{ mb: 1.4, fontWeight: 700 }}>
        Active Cases
      </Typography>

      <Box className="scroll-stack">
        {prioritizedCases.map((item) => {
          const active = item.id === selectedCaseId;
          const critical = item.severity === "Critical";
          return (
            <Box
              key={item.id}
              onClick={() => onSelectCase(item.id)}
              className={`stream-card ${active ? "active" : ""} ${critical ? "critical" : ""}`}
            >
              <Box sx={{ display: "flex", justifyContent: "space-between", mb: 1, gap: 1 }}>
                <Typography sx={{ fontSize: 13, fontWeight: 700 }}>{item.id}</Typography>
                <Box sx={{ display: "flex", gap: 0.8 }}>
                  {critical ? <Chip size="small" color="error" label="PRIORITY" /> : null}
                  <Chip size="small" color={severityTone[item.severity] || "default"} label={item.severity} />
                </Box>
              </Box>
              <Typography sx={{ fontSize: 12, opacity: 0.86 }}>Stage: {item.stage}</Typography>
              <Typography sx={{ fontSize: 11, opacity: 0.7 }}>{item.location.label}</Typography>
            </Box>
          );
        })}
      </Box>
    </Paper>
  );
}