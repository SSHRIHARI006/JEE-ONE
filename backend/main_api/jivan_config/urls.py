from django.contrib import admin
from django.urls import path

from api.views import (
    SOSView,
    HospitalsView,
    CaseDetailView,
    CasesListView,
    AmbulancesView,
    DispatchView,
    AmbulanceLocationView,
)

urlpatterns = [
    path('admin/', admin.site.urls),

    # Emergency intake
    path('api/sos/', SOSView.as_view(), name='sos'),

    # Hospital catalogue
    path('api/hospitals/', HospitalsView.as_view(), name='hospitals'),

    # Cases — list (dashboard) and detail (flutter)
    path('api/cases/', CasesListView.as_view(), name='cases_list'),
    path('api/cases/<str:case_id>/', CaseDetailView.as_view(), name='case_detail'),

    # Ambulance management
    path('api/ambulances/', AmbulancesView.as_view(), name='ambulances'),
    path('api/ambulances/dispatch/', DispatchView.as_view(), name='ambulance_dispatch'),
    path('api/ambulances/<str:ambulance_id>/location/', AmbulanceLocationView.as_view(), name='ambulance_location'),
]
