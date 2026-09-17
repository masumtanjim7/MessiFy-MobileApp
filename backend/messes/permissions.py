from rest_framework.permissions import BasePermission
from .models import Membership


class IsActiveMessMember(BasePermission):
    """
    Allows access only to active members of the target mess.
    Expects 'mess_id' in URL parameters or 'mess' on the object.
    """
    message = "You must be an active member of this mess to perform this action."

    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False

        mess_id = view.kwargs.get('mess_id')
        if not mess_id:
            return True

        return Membership.objects.filter(
            mess_id=mess_id,
            user=request.user,
            is_active=True
        ).exists()


class IsMessManager(BasePermission):
    """
    Allows access only to managers of the target mess.
    """
    message = "Only mess managers have permission to perform this action."

    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False

        mess_id = view.kwargs.get('mess_id')
        if not mess_id:
            return True

        return Membership.objects.filter(
            mess_id=mess_id,
            user=request.user,
            role=Membership.Role.MANAGER,
            is_active=True
        ).exists()