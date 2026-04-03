import { Paper, Typography, Chip } from "@mui/material";

const notificationTone = {
  "Not Sent": "default",
  Sent: "info",
  Acknowledged: "warning",
  Preparing: "success",
};

export default function NotificationPanel({ selectedCase }) {
  return (
    <Paper className="panel-card" sx={{ p: 1.5 }}>
      <Typography variant="subtitle1" sx={{ fontWeight: 700, mb: 1.1 }}>
        Hospital Notification
      </Typography>

      <Chip
        label={selectedCase?.notification || "Not Sent"}
        color={notificationTone[selectedCase?.notification] || "default"}
      />
    </Paper>
  );
}