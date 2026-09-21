from django.urls import path
from .views import (
    DepositListCreateView, 
    ExpenseListCreateView,
    BalanceSheetView,
    CloseMonthCycleView
)

urlpatterns = [
    path('messes/<int:mess_id>/deposits/', DepositListCreateView.as_view(), name='deposits_list_create'),
    path('messes/<int:mess_id>/expenses/', ExpenseListCreateView.as_view(), name='expenses_list_create'),
    path('messes/<int:mess_id>/cycles/<int:cycle_id>/balance-sheet/', BalanceSheetView.as_view(), name='cycle_balance_sheet'),
    path('messes/<int:mess_id>/cycles/<int:cycle_id>/close/', CloseMonthCycleView.as_view(), name='close_month_cycle'),
]