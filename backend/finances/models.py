from decimal import Decimal
from django.db import models
from django.core.exceptions import ValidationError
from django.utils import timezone
from messes.models import Mess, Membership
from meals.models import MonthCycle


class Deposit(models.Model):
    class Status(models.TextChoices):
        PENDING = 'PENDING', 'Pending'
        APPROVED = 'APPROVED', 'Approved'
        REJECTED = 'REJECTED', 'Rejected'

    cycle = models.ForeignKey(
        MonthCycle, 
        on_delete=models.CASCADE, 
        related_name='deposits'
    )
    membership = models.ForeignKey(
        Membership, 
        on_delete=models.CASCADE, 
        related_name='deposits'
    )
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    date = models.DateField(default=timezone.now)
    status = models.CharField(
        max_length=15, 
        choices=Status.choices, 
        default=Status.APPROVED
    )
    notes = models.CharField(max_length=255, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-date', '-created_at']

    def clean(self):
        if self.cycle.status != MonthCycle.Status.ACTIVE:
            raise ValidationError(f"Deposits cannot be modified because cycle '{self.cycle.name}' is {self.cycle.status.lower()}.")
        if self.membership.mess_id != self.cycle.mess_id:
            raise ValidationError("Member does not belong to this mess cycle.")
        if self.amount <= Decimal('0.00'):
            raise ValidationError("Deposit amount must be greater than zero.")

    def save(self, *args, **kwargs):
        self.clean()
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.membership.user.full_name} deposited {self.amount} ({self.status})"


class Expense(models.Model):
    class Category(models.TextChoices):
        BAZAAR = 'BAZAAR', 'Daily Bazaar (Meal Cost)'
        UTILITY = 'UTILITY', 'Utility (Gas/Water/Electricity)'
        RENT = 'RENT', 'House Rent'
        MAID = 'MAID', 'Cook / Maid Salary'
        OTHER = 'OTHER', 'Other Shared Expense'

    cycle = models.ForeignKey(
        MonthCycle, 
        on_delete=models.CASCADE, 
        related_name='expenses'
    )
    spent_by = models.ForeignKey(
        Membership, 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True, 
        related_name='expenses_spent'
    )
    category = models.CharField(
        max_length=20, 
        choices=Category.choices, 
        default=Category.BAZAAR
    )
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    date = models.DateField(default=timezone.now)
    description = models.CharField(max_length=255)
    receipt_image = models.ImageField(upload_to='receipts/%Y/%m/', blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-date', '-created_at']

    def clean(self):
        if self.cycle.status != MonthCycle.Status.ACTIVE:
            raise ValidationError(f"Expenses cannot be modified because cycle '{self.cycle.name}' is {self.cycle.status.lower()}.")
        if self.spent_by and self.spent_by.mess_id != self.cycle.mess_id:
            raise ValidationError("Shopper does not belong to this mess cycle.")
        if self.amount <= Decimal('0.00'):
            raise ValidationError("Expense amount must be greater than zero.")

    def save(self, *args, **kwargs):
        self.clean()
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.category}: {self.amount} ({self.description})"