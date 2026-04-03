from django.contrib import admin
from django.urls import path
from api.views import HospitalRankerView

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/rank-hospitals/', HospitalRankerView.as_view(), name='rank_hospitals'),
    
]