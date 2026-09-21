from decimal import Decimal
from django.db import models
from django.core.exceptions import ValidationError
from django.utils import timezone
from messes.models import Mess, Membership


class MonthCycle(models.Model):
    class Status(models.TextChoices):
        ACTIVE = 'ACTIVE', 'Active'
        LOCKED = 'LOCKED', 'Locked'
        SETTLED = 'SETTLED', 'Settled'

    mess = models.ForeignKey(
        Mess, 
        on_delete=models.CASCADE, 
        related_name='month_cycles'
    )
    name = models.CharField(
        max_length=50, 
        help_text="e.g. September 2026"
    )
    start_date = models.DateField(default=timezone.now)
    end_date = models.DateField(blank=True, null=True)
    status = models.CharField(
        max_length=15, 
        choices=Status.choices, 
        default=Status.ACTIVE
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-start_date']
        constraints = [
            models.UniqueConstraint(
                fields=['mess'],
                condition=models.Q(status='ACTIVE'),
                name='unique_active_month_cycle_per_mess'
            )
        ]

    def clean(self):
        if self.status == self.Status.ACTIVE:
            active_cycles = MonthCycle.objects.filter(
                mess=self.mess, 
                status=self.Status.ACTIVE
            ).exclude(pk=self.pk)
            if active_cycles.exists():
                raise ValidationError("There is already an active month cycle for this mess. Close or lock it first.")

    def save(self, *args, **kwargs):
        self.clean()
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.mess.name} - {self.name} ({self.status})"


class DailyMeal(models.Model):
    cycle = models.ForeignKey(
        MonthCycle, 
        on_delete=models.CASCADE, 
        related_name='meals'
    )
    membership = models.ForeignKey(
        Membership, 
        on_delete=models.CASCADE, 
        related_name='meal_logs'
    )
    date = models.DateField(default=timezone.now)
    breakfast = models.DecimalField(max_digits=3, decimal_places=1, default=Decimal('0.0'))
    lunch = models.DecimalField(max_digits=3, decimal_places=1, default=Decimal('0.0'))
    dinner = models.DecimalField(max_digits=3, decimal_places=1, default=Decimal('0.0'))
    notes = models.CharField(max_length=100, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-date', 'membership__user__full_name']
        unique_together = ('cycle', 'membership', 'date')

    @property
    def total_meals(self):
        return self.breakfast + self.lunch + self.dinner

    def clean(self):
        # Freeze changes if the fiscal cycle is not ACTIVE
        if self.cycle.status != MonthCycle.Status.ACTIVE:
            raise ValidationError(f"Meals cannot be added or edited because the cycle '{self.cycle.name}' is {self.cycle.status.lower()}.")
        # Ensure the member actually belongs to the same mess as the cycle
        if self.membership.mess_id != self.cycle.mess_id:
            raise ValidationError("Membership mess and Cycle mess mismatch.")

    def save(self, *args, **kwargs):
        self.clean()
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.date} | {self.membership.user.full_name}: {self.total_meals} meals"