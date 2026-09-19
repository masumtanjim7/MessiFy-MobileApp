from django.urls import path
from .views import MonthCycleListCreateView, ActiveMonthCycleView, UpdateMonthCycleStatusView

urlpatterns = [
    path('messes/<int:mess_id>/cycles/', MonthCycleListCreateView.as_view(), name='month_cycles_list_create'),
    path('messes/<int:mess_id>/cycles/active/', ActiveMonthCycleView.as_view(), name='active_month_cycle'),
    path('messes/<int:mess_id>/cycles/<int:cycle_id>/status/', UpdateMonthCycleStatusView.as_view(), name='update_cycle_status'),
]