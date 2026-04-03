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

export default function CaseIntakePanel({ incomingCases, selectedCaseId, onSelectCase }) {
  const prioritizedCases = [...incomingCases].sort((a, b) => {
    const bySeverity = (severityRank[b.severity] || 0) - (severityRank[a.severity] || 0);
    if (bySeverity !== 0) {
      return bySeverity;
    }
    return a.timestamp.localeCompare(b.timestamp);
  });

  return (
    <Paper className="panel-card" sx={{ p: 1.5 }}>
      <Typography variant="subtitle1" sx={{ mb: 1.4, fontWeight: 700 }}>
        Incoming Cases
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
              <Box sx={{ display: "flex", justifyContent: "space-between", gap: 1, mb: 1 }}>
                <Typography sx={{ fontSize: 13, fontWeight: 700 }}>{item.id}</Typography>
                <Box sx={{ display: "flex", gap: 0.8 }}>
                  {critical ? <Chip size="small" color="error" label="PRIORITY" /> : null}
                  <Chip size="small" color={severityTone[item.severity] || "default"} label={item.severity} />
                </Box>
              </Box>
              <Typography sx={{ fontSize: 12, opacity: 0.86 }}>{item.source}</Typography>
              <Typography sx={{ fontSize: 11, opacity: 0.7 }}>Reported {item.timestamp}</Typography>
            </Box>
          );
        })}
      </Box>
    </Paper>
  );
}