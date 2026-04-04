JIVAN Emergency Intelligence System

Overview
JIVAN is an emergency triage and routing platform that combines deterministic decision logic with LLM-assisted understanding and explainability.
The system now supports:
- DB-backed single-case routing
- Batch optimization for mass-casualty scenarios
- Optional image-informed triage context (multimodal)

Core Capabilities
1. Single-case triage and routing
- Reads patient/case context from MySQL
- Computes severity and requirements deterministically
- Recommends hospitals using ETA, load, intake delay, and compatibility
- Assigns nearest available ambulance

2. Batch optimization and load balancing
- Processes 5+ critical patients as a global assignment problem
- Prioritizes by severity and time-to-critical
- Applies capacity-aware and saturation-aware penalties
- Distributes patients across hospitals to reduce overload risk

3. Multimodal scene-aware triage
- Accepts optional scene image context through the pipeline
- Uses image-derived severity hints as contextual intelligence
- Keeps final decision deterministic
- Uses AI for interpretation and explanation, not control logic

Architecture
- LLM layer: extraction, interpretation, explainability
- Deterministic layer: triage scoring, routing, batch assignment, load balancing
- Persistence layer: MySQL reads/writes for cases, triage, recommendations, assignment, logs

Main Workflow Paths
- Public single-case flow
- Medic/ambulance flow
- Batch mass-casualty flow
- Fallback path in backend wrapper when agent execution fails

Database Integration Status
- Reads from DB:
	- hospitals + dynamic status
	- ambulances
	- latest case/patient and critical batch patients
- Writes to DB:
	- triage
	- recommendations
	- ambulance assignment
	- hospital dynamic updates (batch)
	- event logs

Project Structure (Key)
- AGENT-WORKFLOW/logic/agents: extraction, triage interpretation, decision routing, explanation
- AGENT-WORKFLOW/logic/services: triage, hospital scoring, ambulance assignment, routing, batch optimization
- AGENT-WORKFLOW/logic/pipelines: public, medic, batch orchestration
- AGENT-WORKFLOW/logic/views: API-style entrypoints used by backend wrapper
- AGENT-WORKFLOW/logic/utils/db_store.py: MySQL access and persistence helpers
- backend/main_api/api/workflow_wrapper.py: Django-side integration bridge

Environment
Required in AGENT-WORKFLOW/.env:
- ANTHROPIC_API_KEY=...
- ANTHROPIC_MODEL=...
- DATABASE_LINK=mysql://<user>:<password>@127.0.0.1:3306/<db_name>

Dependencies
Install from:
- AGENT-WORKFLOW/req.txt

Run (when DB and env are configured)
1. Activate venv in AGENT-WORKFLOW
2. Single workflow smoke test:
	 - python3 smoke_test.py
3. Batch workflow smoke test:
	 - python3 batch_smoke_test.py

Design Principles
- Deterministic decisions for reliability
- AI used only where interpretation or explanation is needed
- No hard overrides from image context
- Backward-compatible pipeline behavior when optional inputs are absent

Current Focus
- Stable DB-backed execution
- High-quality explainability
- Mass-casualty distribution without hospital overload
