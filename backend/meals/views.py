from django.db import transaction
from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from messes.models import Membership
from messes.permissions import IsActiveMessMember, IsMessManager
from .models import MonthCycle, DailyMeal
from .serializers import (
    MonthCycleSerializer, 
    DailyMealSerializer, 
    BulkMealSubmitSerializer
)


class MonthCycleListCreateView(generics.ListCreateAPIView):
    serializer_class = MonthCycleSerializer

    def get_permissions(self):
        if self.request.method == 'POST':
            return [IsAuthenticated(), IsMessManager()]
        return [IsAuthenticated(), IsActiveMessMember()]

    def get_queryset(self):
        mess_id = self.kwargs['mess_id']
        return MonthCycle.objects.filter(mess_id=mess_id)

    def perform_create(self, serializer):
        serializer.save(mess_id=self.kwargs['mess_id'])


class ActiveMonthCycleView(generics.RetrieveAPIView):
    permission_classes = [IsAuthenticated, IsActiveMessMember]
    serializer_class = MonthCycleSerializer

    def get_object(self):
        mess_id = self.kwargs['mess_id']
        return MonthCycle.objects.filter(mess_id=mess_id, status=MonthCycle.Status.ACTIVE).first()

    def retrieve(self, request, *args, **kwargs):
        instance = self.get_object()
        if not instance:
            return Response(
                {"detail": "No active month cycle found for this mess."}, 
                status=status.HTTP_404_NOT_FOUND
            )
        serializer = self.get_serializer(instance)
        return Response(serializer.data)


class UpdateMonthCycleStatusView(APIView):
    permission_classes = [IsAuthenticated, IsMessManager]

    def patch(self, request, mess_id, cycle_id):
        cycle = MonthCycle.objects.filter(id=cycle_id, mess_id=mess_id).first()
        if not cycle:
            return Response({"detail": "Month cycle not found."}, status=status.HTTP_404_NOT_FOUND)

        new_status = request.data.get('status')
        if new_status not in MonthCycle.Status.values:
            return Response({"detail": f"Invalid status. Choose from: {MonthCycle.Status.values}"}, status=status.HTTP_400_BAD_REQUEST)

        cycle.status = new_status
        if new_status in [MonthCycle.Status.LOCKED, MonthCycle.Status.SETTLED] and not cycle.end_date:
            from django.utils import timezone
            cycle.end_date = timezone.now().date()

        cycle.save()
        return Response(MonthCycleSerializer(cycle).data, status=status.HTTP_200_OK)


class DailyMealListView(generics.ListAPIView):
    """
    GET: View meal logs for a mess.
    Supports optional query filters: ?date=YYYY-MM-DD or ?cycle_id=ID
    """
    permission_classes = [IsAuthenticated, IsActiveMessMember]
    serializer_class = DailyMealSerializer

    def get_queryset(self):
        mess_id = self.kwargs['mess_id']
        queryset = DailyMeal.objects.filter(cycle__mess_id=mess_id)

        target_date = self.request.query_params.get('date')
        cycle_id = self.request.query_params.get('cycle_id')

        if target_date:
            queryset = queryset.filter(date=target_date)
        if cycle_id:
            queryset = queryset.filter(cycle_id=cycle_id)

        return queryset


class BulkMealEntryView(APIView):
    """
    POST: Record or update meals in bulk for all members on a single date.
    Managers only.
    """
    permission_classes = [IsAuthenticated, IsMessManager]

    def post(self, request, mess_id):
        serializer = BulkMealSubmitSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        entry_date = serializer.validated_data['date']
        entries = serializer.validated_data['entries']

        active_cycle = MonthCycle.objects.filter(mess_id=mess_id, status=MonthCycle.Status.ACTIVE).first()
        if not active_cycle:
            return Response(
                {"detail": "Cannot record meals without an active month cycle."}, 
                status=status.HTTP_400_BAD_REQUEST
            )

        saved_records = []
        with transaction.atomic():
            for item in entries:
                membership = Membership.objects.filter(
                    id=item['membership_id'], 
                    mess_id=mess_id, 
                    is_active=True
                ).first()
                if not membership:
                    continue

                meal, _ = DailyMeal.objects.update_or_create(
                    cycle=active_cycle,
                    membership=membership,
                    date=entry_date,
                    defaults={
                        'breakfast': item['breakfast'],
                        'lunch': item['lunch'],
                        'dinner': item['dinner'],
                        'notes': item.get('notes', ''),
                    }
                )
                saved_records.append(meal)

        return Response(
            {"detail": f"Successfully updated {len(saved_records)} meal entries for {entry_date}."},
            status=status.HTTP_200_OK
        )