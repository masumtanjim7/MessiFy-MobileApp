from rest_framework import generics
from rest_framework.permissions import IsAuthenticated
from messes.permissions import IsActiveMessMember, IsMessManager
from .models import Deposit, Expense
from .serializers import DepositSerializer, ExpenseSerializer


class DepositListCreateView(generics.ListCreateAPIView):
    """
    GET: List deposits for a specific mess/cycle.
    POST: Record a member deposit (Managers can approve directly; members submit pending).
    """
    serializer_class = DepositSerializer

    def get_permissions(self):
        if self.request.method == 'POST':
            return [IsAuthenticated(), IsMessManager()]
        return [IsAuthenticated(), IsActiveMessMember()]

    def get_queryset(self):
        mess_id = self.kwargs['mess_id']
        queryset = Deposit.objects.filter(cycle__mess_id=mess_id)
        cycle_id = self.request.query_params.get('cycle_id')
        member_id = self.request.query_params.get('membership_id')

        if cycle_id:
            queryset = queryset.filter(cycle_id=cycle_id)
        if member_id:
            queryset = queryset.filter(membership_id=member_id)
        return queryset


class ExpenseListCreateView(generics.ListCreateAPIView):
    """
    GET: List expenses for a specific mess.
    POST: Record a daily bazaar or shared mess expense.
    """
    serializer_class = ExpenseSerializer

    def get_permissions(self):
        if self.request.method == 'POST':
            return [IsAuthenticated(), IsMessManager()]
        return [IsAuthenticated(), IsActiveMessMember()]

    def get_queryset(self):
        mess_id = self.kwargs['mess_id']
        queryset = Expense.objects.filter(cycle__mess_id=mess_id)
        cycle_id = self.request.query_params.get('cycle_id')
        category = self.request.query_params.get('category')

        if cycle_id:
            queryset = queryset.filter(cycle_id=cycle_id)
        if category:
            queryset = queryset.filter(category=category)
        return queryset