from rest_framework import generics, status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from .models import Mess, Membership
from .serializers import MessSerializer, JoinMessSerializer, MembershipSerializer
from .permissions import IsActiveMessMember, IsMessManager


class MessListCreateView(generics.ListCreateAPIView):
    """
    GET: List all messes the current user belongs to.
    POST: Create a new mess and enroll the creator as Manager.
    """
    permission_classes = [IsAuthenticated]
    serializer_class = MessSerializer

    def get_queryset(self):
        return Mess.objects.filter(memberships__user=self.request.user, memberships__is_active=True)


class JoinMessView(APIView):
    """
    POST: Join an existing mess using its 6-character code.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = JoinMessSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        join_code = serializer.validated_data['join_code']

        mess = Mess.objects.get(join_code=join_code)
        user = request.user

        membership, created = Membership.objects.get_or_create(
            user=user,
            mess=mess,
            defaults={'role': Membership.Role.MEMBER}
        )

        if not created:
            if not membership.is_active:
                membership.is_active = True
                membership.save()
                return Response({"detail": "Re-joined mess successfully."}, status=status.HTTP_200_OK)
            return Response({"detail": "You are already a member of this mess."}, status=status.HTTP_400_BAD_REQUEST)

        return Response(
            {"detail": f"Successfully joined {mess.name}.", "mess_id": mess.id}, 
            status=status.HTTP_201_CREATED
        )


class MessMembersListView(generics.ListAPIView):
    """
    GET: List all active members of a specific mess.
    Requires the requesting user to be an active member of that mess.
    """
    permission_classes = [IsAuthenticated, IsActiveMessMember]
    serializer_class = MembershipSerializer

    def get_queryset(self):
        mess_id = self.kwargs['mess_id']
        return Membership.objects.filter(mess_id=mess_id, is_active=True)


class ManageMemberRoleView(APIView):
    """
    PATCH: Change a member's role (MANAGER/MEMBER) or deactivate them.
    Guarded: Only accessible by current Mess Managers.
    """
    permission_classes = [IsAuthenticated, IsMessManager]

    def patch(self, request, mess_id, membership_id):
        membership = Membership.objects.filter(id=membership_id, mess_id=mess_id).first()
        if not membership:
            return Response({"detail": "Membership record not found."}, status=status.HTTP_404_NOT_FOUND)

        new_role = request.data.get('role')
        is_active = request.data.get('is_active')

        if new_role and new_role in Membership.Role.values:
            membership.role = new_role
        if is_active is not None:
            membership.is_active = bool(is_active)

        membership.save()
        return Response(MembershipSerializer(membership).data, status=status.HTTP_200_OK)