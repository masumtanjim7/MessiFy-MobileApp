from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from messes.permissions import IsActiveMessMember, IsMessManager
from .models import MonthCycle
from .serializers import MonthCycleSerializer


class MonthCycleListCreateView(generics.ListCreateAPIView):
    """
    GET: List all month cycles for a given mess (Active members only).
    POST: Start a new month cycle (Managers only).
    """
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
    """
    GET: Retrieve the currently ACTIVE month cycle for a mess.
    """
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
    """
    PATCH: Change month state (ACTIVE -> LOCKED -> SETTLED).
    Managers only.
    """
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