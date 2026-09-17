import random
import string
from django.db import models
from django.conf import settings


def generate_join_code():
    chars = string.ascii_uppercase + string.digits
    return ''.join(random.choices(chars, k=6))


class Mess(models.Model):
    name = models.CharField(max_length=120)
    address = models.TextField(blank=True, null=True)
    join_code = models.CharField(
        max_length=10, 
        unique=True, 
        default=generate_join_code, 
        editable=False
    )
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, 
        on_delete=models.CASCADE, 
        related_name='owned_messes'
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.name} (Code: {self.join_code})"


class Membership(models.Model):
    class Role(models.TextChoices):
        MANAGER = 'MANAGER', 'Manager'
        MEMBER = 'MEMBER', 'Member'

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, 
        on_delete=models.CASCADE, 
        related_name='memberships'
    )
    mess = models.ForeignKey(
        Mess, 
        on_delete=models.CASCADE, 
        related_name='memberships'
    )
    role = models.CharField(
        max_length=20, 
        choices=Role.choices, 
        default=Role.MEMBER
    )
    is_active = models.BooleanField(default=True)
    joined_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('user', 'mess')

    def __str__(self):
        return f"{self.user.full_name} - {self.mess.name} ({self.role})"