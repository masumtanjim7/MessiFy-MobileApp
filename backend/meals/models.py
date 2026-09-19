from django.db import models
from django.core.exceptions import ValidationError
from django.utils import timezone
from messes.models import Mess


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
            # Ensure only one cycle can be ACTIVE per mess
            models.UniqueConstraint(
                fields=['mess'],
                condition=models.Q(status='ACTIVE'),
                name='unique_active_month_cycle_per_mess'
            )
        ]

    def clean(self):
        # Validate that an active cycle does not overlap another active one
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