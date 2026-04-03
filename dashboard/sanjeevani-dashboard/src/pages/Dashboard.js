import { useEffect, useMemo, useState } from "react";
import { Box, Typography, Chip } from "@mui/material";

import CaseIntakePanel from "../components/CaseIntakePanel";
import CaseDetailsPanel from "../components/CaseDetailsPanel";
import HospitalPanel from "../components/HospitalPanel";
import AmbulancePanel from "../components/AmbulancePanel";
import MapView from "../components/MapView";
import NotificationPanel from "../components/NotificationPanel";
import ActiveCasesTable from "../components/ActiveCasesTable";
import EventFlow from "../components/EventFlow";

export default function Dashboard() {
  const initialCases = useMemo(
    () => [
      {
        id: "C-24101",
        source: "Ambulance",
        timestamp: "14:02",
        severity: "Critical",
        stage: "TRIAGED",
        location: { x: 26, y: 58, label: "Sector 14 Junction" },
        symptoms: ["Chest pain", "Breathlessness"],
        vitals: { spo2: 82, hr: 132, bp: "84/58" },
        requiredResources: ["ICU", "Ventilator", "Cardiologist"],
        ambulance: { id: "AMB-12", status: "en route" },
        notification: "Sent",
        hospitals: [
          {
            id: "H-1",
            name: "City Trauma Institute",
            eta: 9,
            icu: 3,
            ventilators: 2,
            load: 68,
            compatibility: "full",
            score: 14,
            position: { x: 72, y: 32 },
          },
          {
            id: "H-2",
            name: "Metro General",
            eta: 6,
            icu: 1,
            ventilators: 1,
            load: 84,
            compatibility: "partial",
            score: 17,
            position: { x: 60, y: 74 },
          },
          {
            id: "H-3",
            name: "NorthCare Multi-Speciality",
            eta: 12,
            icu: 6,
            ventilators: 5,
            load: 49,
            compatibility: "full",
            score: 18,
            position: { x: 82, y: 66 },
          },
        ],
      },
      {
        id: "C-24102",
        source: "Public App",
        timestamp: "14:05",
        severity: "High",
        stage: "RECOMMENDED",
        location: { x: 38, y: 42, label: "NH44 Flyover" },
        symptoms: ["Head injury", "Disorientation"],
        vitals: { spo2: 91, hr: 118, bp: "102/66" },
        requiredResources: ["CT Scan", "Neurosurgeon"],
        ambulance: { id: null, status: "available" },
        notification: "Not Sent",
        hospitals: [
          {
            id: "H-4",
            name: "Apex Neuro Center",
            eta: 11,
            icu: 2,
            ventilators: 2,
            load: 62,
            compatibility: "full",
            score: 13,
            position: { x: 70, y: 47 },
          },
          {
            id: "H-5",
            name: "State Civil Hospital",
            eta: 7,
            icu: 0,
            ventilators: 1,
            load: 88,
            compatibility: "risky",
            score: 23,
            position: { x: 57, y: 61 },
          },
          {
            id: "H-6",
            name: "Lifeline Medical Hub",
            eta: 13,
            icu: 5,
            ventilators: 4,
            load: 52,
            compatibility: "full",
            score: 16,
            position: { x: 84, y: 73 },
          },
        ],
      },
      {
        id: "C-24103",
        source: "Call Center",
        timestamp: "14:08",
        severity: "Medium",
        stage: "CREATED",
        location: { x: 18, y: 30, label: "Old City Market" },
        symptoms: ["Fracture suspicion", "Pain"],
        vitals: { spo2: 96, hr: 102, bp: "116/76" },
        requiredResources: ["Orthopedic", "X-Ray"],
        ambulance: { id: null, status: "available" },
        notification: "Not Sent",
        hospitals: [
          {
            id: "H-7",
            name: "Regional Ortho Unit",
            eta: 8,
            icu: 1,
            ventilators: 0,
            load: 55,
            compatibility: "full",
            score: 12,
            position: { x: 48, y: 35 },
          },
          {
            id: "H-8",
            name: "Central District Hospital",
            eta: 5,
            icu: 0,
            ventilators: 0,
            load: 81,
            compatibility: "partial",
            score: 18,
            position: { x: 43, y: 48 },
          },
          {
            id: "H-9",
            name: "Pioneer MedCare",
            eta: 12,
            icu: 3,
            ventilators: 2,
            load: 40,
            compatibility: "full",
            score: 15,
            position: { x: 74, y: 26 },
          },
        ],
      },
    ],
    []
  );

  const [cases, setCases] = useState(initialCases);
  const [selectedCaseId, setSelectedCaseId] = useState(initialCases[0].id);
  const [syncClock, setSyncClock] = useState(new Date());
  const [selectedHospitalsByCase, setSelectedHospitalsByCase] = useState(() => ({
    [initialCases[0].id]: initialCases[0].hospitals[0].id,
    [initialCases[1].id]: initialCases[1].hospitals[0].id,
    [initialCases[2].id]: initialCases[2].hospitals[0].id,
  }));

  useEffect(() => {
    const clockTimer = setInterval(() => {
      setSyncClock(new Date());
    }, 1000);

    return () => clearInterval(clockTimer);
  }, []);

  useEffect(() => {
    const stageOrder = ["CREATED", "TRIAGED", "RECOMMENDED", "ASSIGNED", "NOTIFIED"];

    const timer = setInterval(() => {
      setCases((prevCases) =>
        prevCases.map((item, index) => {
          const currentStageIndex = stageOrder.indexOf(item.stage);
          const shouldAdvance = Math.random() > 0.7;
          const nextStage =
            shouldAdvance && currentStageIndex < stageOrder.length - 1
              ? stageOrder[currentStageIndex + 1]
              : item.stage;

          const hospitals = item.hospitals.map((hospital) => ({
            ...hospital,
            eta: Math.max(3, hospital.eta + (Math.random() > 0.5 ? 1 : -1)),
            load: Math.min(96, Math.max(32, hospital.load + (Math.random() > 0.5 ? 2 : -2))),
          }));

          const notification =
            nextStage === "NOTIFIED"
              ? "Preparing"
              : nextStage === "ASSIGNED"
              ? "Acknowledged"
              : item.notification;

          if (index === 0) {
            return {
              ...item,
              stage: nextStage,
              notification,
              hospitals,
            };
          }

          return {
            ...item,
            stage: nextStage,
            hospitals,
          };
        })
      );
    }, 5500);

    return () => clearInterval(timer);
  }, []);

  const selectedCase = useMemo(
    () => cases.find((entry) => entry.id === selectedCaseId) || cases[0],
    [cases, selectedCaseId]
  );

  const selectedHospitalId = selectedHospitalsByCase[selectedCase?.id];
  const selectedHospital = selectedCase?.hospitals.find((h) => h.id === selectedHospitalId) || null;

  const incomingCases = useMemo(
    () => cases.filter((item) => item.stage === "CREATED" || item.stage === "TRIAGED"),
    [cases]
  );

  const activeCases = useMemo(
    () => cases.filter((item) => ["TRIAGED", "RECOMMENDED", "ASSIGNED", "NOTIFIED"].includes(item.stage)),
    [cases]
  );

  const onHospitalSelect = (hospitalId) => {
    setSelectedHospitalsByCase((prev) => ({
      ...prev,
      [selectedCase.id]: hospitalId,
    }));
  };

  const onAssignAmbulance = () => {
    setCases((prevCases) =>
      prevCases.map((item) => {
        if (item.id !== selectedCase.id || item.ambulance.id) {
          return item;
        }

        const generatedId = `AMB-${Math.floor(20 + Math.random() * 79)}`;
        return {
          ...item,
          stage: "ASSIGNED",
          ambulance: {
            id: generatedId,
            status: "en route",
          },
          notification: selectedHospital ? "Sent" : "Not Sent",
        };
      })
    );
  };

  return (
    <Box className="command-shell">

      <Box className="ambient-glow ambient-glow-left" />
      <Box className="ambient-glow ambient-glow-right" />

      {/* HEADER */}
      <Box className="command-header">
        <Box>
          <Typography className="title-mark" variant="overline">
            Emergency Operations Relay
          </Typography>
          <Typography className="title-main" variant="h4">
            Sanjeevani AI Command Center
          </Typography>
          <Typography className="title-sub" variant="body2">
            We do not optimize for distance, we optimize for time to treatment.
          </Typography>
        </Box>
        <Box className="header-stats">
          <Chip label={`Selected ${selectedCase?.id || "--"}`} color="secondary" />
          <Chip label={`${activeCases.length} Active`} color="error" />
          <Chip label={`${incomingCases.length} Incoming`} color="warning" />
          <Chip label={`Live Sync ${syncClock.toLocaleTimeString()}`} color="success" />
          <Chip label={`Tracking ${cases.length} Cases`} color="info" />
        </Box>
      </Box>

      {/* MAIN LAYOUT */}
      <Box className="command-grid">

        {/* LEFT PANEL */}
        <Box className="left-zone panel-zone">
          <CaseIntakePanel
            incomingCases={incomingCases}
            selectedCaseId={selectedCase?.id}
            onSelectCase={setSelectedCaseId}
          />
          <ActiveCasesTable
            activeCases={activeCases}
            selectedCaseId={selectedCase?.id}
            onSelectCase={setSelectedCaseId}
          />
        </Box>

        {/* CENTER MAP */}
        <Box className="center-zone panel-zone">
          <MapView
            selectedCase={selectedCase}
            selectedHospital={selectedHospital}
          />
        </Box>

        {/* RIGHT PANEL */}
        <Box className="right-zone panel-zone">
          <CaseDetailsPanel selectedCase={selectedCase} />
          <HospitalPanel
            selectedCase={selectedCase}
            selectedHospitalId={selectedHospitalId}
            onSelectHospital={onHospitalSelect}
          />
          <AmbulancePanel
            selectedCase={selectedCase}
            onAssignAmbulance={onAssignAmbulance}
          />
          <NotificationPanel selectedCase={selectedCase} />
          <EventFlow selectedCase={selectedCase} />
        </Box>
      </Box>
    </Box>
  );
}