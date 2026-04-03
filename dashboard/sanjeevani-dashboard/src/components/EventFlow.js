import { Paper, Typography } from "@mui/material";

const flow = ["CREATED", "TRIAGED", "RECOMMENDED", "ASSIGNED", "NOTIFIED"];

export default function EventFlow({ selectedCase }) {
  const currentIndex = flow.indexOf(selectedCase?.stage || "CREATED");

  return (
    <Paper className="panel-card" sx={{ p: 1.5 }}>
      <Typography variant="subtitle1" sx={{ fontWeight: 700, mb: 1.1 }}>
        Event Flow
      </Typography>

      {flow.map((step, index) => {
        const done = index <= currentIndex;
        return (
          <Typography key={step} className={`flow-step ${done ? "done" : ""}`}>
            {done ? "[x]" : "[ ]"} {step}
          </Typography>
        );
      })}
    </Paper>
  );
}