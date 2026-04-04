import { useEffect, useMemo, useRef, useState } from "react";
import { Box, Typography, Chip } from "@mui/material";

import CaseIntakePanel from "../components/CaseIntakePanel";
import CaseDetailsPanel from "../components/CaseDetailsPanel";
import HospitalPanel from "../components/HospitalPanel";
import AmbulancePanel from "../components/AmbulancePanel";
import MapView from "../components/MapView";
import NotificationPanel from "../components/NotificationPanel";
import ActiveCasesTable from "../components/ActiveCasesTable";
import EventFlow from "../components/EventFlow";
import SceneAnalysisPanel from "../components/SceneAnalysisPanel";

const API_BASE = process.env.REACT_APP_API_BASE || "http://10.23.46.111:8000";
const POLL_INTERVAL_MS = 5000;

// ---------------------------------------------------------------------------
// Map API case shape → Dashboard component shape
// ---------------------------------------------------------------------------
const URGENCY_TO_SEVERITY = {
  CRITICAL: "Critical",
  HIGH: "High",
  MEDIUM: "Medium",
  LOW: "Stable",
};

const SOURCE_TYPE_LABEL = {
  ambulance: "Ambulance",
  public: "Public App",
  call_center: "Call Center",
};

function deriveStage(apiCase) {
  if (apiCase.ambulance?.id) return "ASSIGNED";
  if ((apiCase.hospitals || []).length > 0) return "RECOMMENDED";
  if (apiCase.severity_score > 0) return "TRIAGED";
  return "CREATED";
}

function transformCase(apiCase) {
  const urgency = (apiCase.urgency_level || "").toUpperCase();
  return {
    id: apiCase.case_id,
    source: SOURCE_TYPE_LABEL[apiCase.source_type] || apiCase.source_type,
    timestamp: apiCase.timestamp
      ? new Date(apiCase.timestamp).toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })
      : "--:--",
    severity: URGENCY_TO_SEVERITY[urgency] || urgency,
    stage: deriveStage(apiCase),
    location: {
      lat: apiCase.latitude ?? 18.5204,
      lng: apiCase.longitude ?? 73.8567,
      label: apiCase.latitude
        ? `${Number(apiCase.latitude).toFixed(4)}, ${Number(apiCase.longitude).toFixed(4)}`
        : "Unknown",
    },
    symptoms: [],
    vitals: {
      spo2: apiCase.spo2 ?? "--",
      hr: "--",
      bp: apiCase.systolic_bp ? `${apiCase.systolic_bp}/--` : "--/--",
    },
    requiredResources: [
      apiCase.required_specialist,
      apiCase.needs_icu ? "ICU" : null,
    ].filter(Boolean),
    ambulance: apiCase.ambulance
      ? {
          id: apiCase.ambulance.id,
          status: apiCase.ambulance.status,
          lat: apiCase.ambulance.latitude,
          lng: apiCase.ambulance.longitude,
          eta: apiCase.ambulance.eta_to_patient,
        }
      : { id: null, status: "available" },
    hospitals: (apiCase.hospitals || []).map((h) => ({
      id: h.hospital_id,
      name: h.hospital_name,
      latitude: h.latitude,
      longitude: h.longitude,
      eta: h.eta,
      icu: h.available_icu_beds,
      ventilators: h.available_icu_beds,
      load: Math.round(h.load_percentage ?? 0),
      compatibility: (h.compatibility || "risky").toLowerCase(),
      score: h.score,
    })),
    sceneContext: apiCase.scene_context || null,
  };
}

// ---------------------------------------------------------------------------
// Dashboard
// ---------------------------------------------------------------------------
export default function Dashboard() {
  const [cases, setCases] = useState([]);
  const [selectedCaseId, setSelectedCaseId] = useState(null);
  const [selectedHospitalsByCase, setSelectedHospitalsByCase] = useState({});
  const [syncClock, setSyncClock] = useState(new Date());
  const [apiError, setApiError] = useState(false);
  const hasInitialized = useRef(false);

  // Live clock
  useEffect(() => {
    const t = setInterval(() => setSyncClock(new Date()), 1000);
    return () => clearInterval(t);
  }, []);

  // Poll /api/cases/ every 5 s
  useEffect(() => {
    const fetchCases = async () => {
      try {
        const res = await fetch(`${API_BASE}/api/cases/`);
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        const data = await res.json();
        const transformed = data.map(transformCase);
        setApiError(false);

        // Auto-select first case and default hospital on first load
        if (!hasInitialized.current && transformed.length > 0) {
          setSelectedCaseId(transformed[0].id);
          const defaults = {};
          transformed.forEach((c) => {
            if (c.hospitals.length > 0) defaults[c.id] = c.hospitals[0].id;
          });
          setSelectedHospitalsByCase(defaults);
          hasInitialized.current = true;
        } else {
          // Keep defaults for any new cases that arrive
          setSelectedHospitalsByCase((prev) => {
            const updated = { ...prev };
            transformed.forEach((c) => {
              if (!updated[c.id] && c.hospitals.length > 0) {
                updated[c.id] = c.hospitals[0].id;
              }
            });
            return updated;
          });
        }

        setCases(transformed);
      } catch (err) {
        console.error("[Dashboard] API fetch failed:", err);
        setApiError(true);
      }
    };

    fetchCases();
    const interval = setInterval(fetchCases, POLL_INTERVAL_MS);
    return () => clearInterval(interval);
  }, []);

  // Derived views
  const selectedCase = useMemo(
    () => cases.find((c) => c.id === selectedCaseId) || cases[0] || null,
    [cases, selectedCaseId]
  );

  const selectedHospitalId = selectedCase ? selectedHospitalsByCase[selectedCase.id] : null;
  const selectedHospital =
    selectedCase?.hospitals.find((h) => h.id === selectedHospitalId) || null;

  const incomingCases = useMemo(
    () => cases.filter((c) => c.stage === "CREATED" || c.stage === "TRIAGED"),
    [cases]
  );

  const activeCases = useMemo(
    () =>
      cases.filter((c) =>
        ["TRIAGED", "RECOMMENDED", "ASSIGNED", "NOTIFIED"].includes(c.stage)
      ),
    [cases]
  );

  const onHospitalSelect = (hospitalId) => {
    setSelectedHospitalsByCase((prev) => ({
      ...prev,
      [selectedCase.id]: hospitalId,
    }));
  };

  // Phase 1 Smart Dispatch — POST /api/ambulances/dispatch/
  const onAssignAmbulance = async () => {
    if (!selectedCase || selectedCase.ambulance?.id) return;
    try {
      const res = await fetch(`${API_BASE}/api/ambulances/dispatch/`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          case_id: selectedCase.id,
          latitude: selectedCase.location.lat,
          longitude: selectedCase.location.lng,
        }),
      });
      if (!res.ok) {
        const err = await res.json();
        console.error("[Dashboard] Dispatch error:", err);
        return;
      }
      const data = await res.json();
      // Optimistically update UI before next poll
      setCases((prev) =>
        prev.map((c) => {
          if (c.id !== selectedCase.id) return c;
          return {
            ...c,
            stage: "ASSIGNED",
            ambulance: {
              id: data.ambulance_id,
              status: "dispatched",
              lat: data.ambulance_lat,
              lng: data.ambulance_lng,
              eta: data.eta_to_patient,
            },
          };
        })
      );
    } catch (err) {
      console.error("[Dashboard] Dispatch failed:", err);
    }
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
            JIVAN AI Command Center
          </Typography>
          <Typography className="title-sub" variant="body2">
            We do not optimize for distance, we optimize for time to treatment.
          </Typography>
        </Box>
        <Box className="header-stats">
          <Chip label={`Selected ${selectedCase?.id || "--"}`} color="secondary" />
          <Chip label={`${activeCases.length} Active`} color="error" />
          <Chip label={`${incomingCases.length} Incoming`} color="warning" />
          <Chip
            label={apiError ? "API Offline" : `Live Sync ${syncClock.toLocaleTimeString()}`}
            color={apiError ? "default" : "success"}
          />
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
          <SceneAnalysisPanel sceneContext={selectedCase?.sceneContext} />
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
