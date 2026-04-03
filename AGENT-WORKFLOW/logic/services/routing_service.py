from math import sqrt
from datetime import datetime, timezone

from logic.models.ambulance_model import RouteMetricsModel, RouteModel
from logic.models.patient_model import CoordinatesModel


def compute_distance_km(source: CoordinatesModel, destination: CoordinatesModel) -> float:
    lat_diff = source.latitude - destination.latitude
    lon_diff = source.longitude - destination.longitude
    return round(max(sqrt((lat_diff * 111.0) ** 2 + (lon_diff * 111.0) ** 2), 3.0), 2)


def compute_eta_minutes(distance_km: float, speed_kmph: float, traffic_level: str) -> int:
    traffic_factor = {"low": 1.0, "medium": 1.25, "high": 1.5}.get(traffic_level, 1.25)
    base_time_hours = distance_km / speed_kmph if speed_kmph > 0 else 0
    return max(int(round(base_time_hours * 60 * traffic_factor)), 1)


def build_route(case_id: str, source: CoordinatesModel, destination_hospital_id: str, destination: CoordinatesModel) -> RouteModel:
    distance_km = compute_distance_km(source, destination)
    traffic_level = "high" if distance_km > 15 else "medium" if distance_km > 6 else "low"
    eta = compute_eta_minutes(distance_km=distance_km, speed_kmph=35.0, traffic_level=traffic_level)
    eta = min(max(eta, 8), 25)

    return RouteModel(
        case_id=case_id,
        source=source,
        destination_hospital_id=destination_hospital_id,
        route_metrics=RouteMetricsModel(
            distance_km=distance_km,
            estimated_travel_time=eta,
            traffic_level=traffic_level,
        ),
        route_polyline=f"polyline-{case_id}-{destination_hospital_id}",
        timestamp=datetime.now(timezone.utc).isoformat(),
    )
