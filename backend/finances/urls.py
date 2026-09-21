from django.urls import path
from .views import DepositListCreateView, ExpenseListCreateView

urlpatterns = [
    path('messes/<int:mess_id>/deposits/', DepositListCreateView.as_view(), name='deposits_list_create'),
    path('messes/<int:mess_id>/expenses/', ExpenseListCreateView.as_view(), name='expenses_list_create'),
]