from django.utils import timezone
from rest_framework import generics, status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny

from messes.permissions import IsActiveMessMember, IsMessManager
from meals.models import MonthCycle, DailyMeal
from .models import Deposit, Expense
from .serializers import DepositSerializer, ExpenseSerializer
from .services import calculate_cycle_balance_sheet


class DepositListCreateView(generics.ListCreateAPIView):
    """
    GET: List deposits for a specific mess.
    POST: Record a member deposit (Managers only).
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
    POST: Record a daily bazaar or shared expense (Managers only).
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


class BalanceSheetView(APIView):
    """
    GET: Retrieve real-time dynamic balance sheet for a month cycle.
    Accessible by all active members of the mess.
    """
    permission_classes = [IsAuthenticated, IsActiveMessMember]

    def get(self, request, mess_id, cycle_id):
        cycle = MonthCycle.objects.filter(id=cycle_id, mess_id=mess_id).first()
        if not cycle:
            return Response({"detail": "Month cycle not found."}, status=status.HTTP_404_NOT_FOUND)

        data = calculate_cycle_balance_sheet(cycle)
        return Response(data, status=status.HTTP_200_OK)


class CloseMonthCycleView(APIView):
    """
    POST: Finalizes a month cycle, marks status as SETTLED, and freezes records.
    Managers only.
    """
    permission_classes = [IsAuthenticated, IsMessManager]

    def post(self, request, mess_id, cycle_id):
        cycle = MonthCycle.objects.filter(id=cycle_id, mess_id=mess_id).first()
        if not cycle:
            return Response({"detail": "Month cycle not found."}, status=status.HTTP_404_NOT_FOUND)

        if cycle.status == MonthCycle.Status.SETTLED:
            return Response({"detail": "This cycle is already settled."}, status=status.HTTP_400_BAD_REQUEST)

        # Freeze cycle
        cycle.status = MonthCycle.Status.SETTLED
        cycle.end_date = timezone.now().date()
        cycle.save()

        # Compute final snapshot
        final_summary = calculate_cycle_balance_sheet(cycle)

        return Response({
            "detail": f"Month cycle '{cycle.name}' settled successfully.",
            "final_summary": final_summary
        }, status=status.HTTP_200_OK)


class AutomationDailySummaryView(APIView):
    """
    GET: Internal automation endpoint queried by n8n to inspect 
    today's meal counts and active cycle balance.
    """
    permission_classes = [AllowAny]

    def get(self, request, mess_id):
        today = timezone.now().date()
        active_cycle = MonthCycle.objects.filter(mess_id=mess_id, status=MonthCycle.Status.ACTIVE).first()
        
        if not active_cycle:
            return Response({"error": "No active cycle found for this mess."}, status=status.HTTP_404_NOT_FOUND)

        today_meals = DailyMeal.objects.filter(cycle=active_cycle, date=today)
        sheet = calculate_cycle_balance_sheet(active_cycle)

        return Response({
            "date": str(today),
            "mess_name": active_cycle.mess.name,
            "active_cycle": active_cycle.name,
            "current_meal_rate": sheet["financial_overview"]["meal_rate"],
            "total_meals_today": float(sum(m.total_meals for m in today_meals)),
            "members_logged_today": today_meals.count(),
            "total_active_members": sheet["financial_overview"]["active_members_count"],
            "cash_in_hand": sheet["financial_overview"]["cash_in_hand"]
        }, status=status.HTTP_200_OK)