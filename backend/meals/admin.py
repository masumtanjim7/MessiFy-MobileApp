from django.contrib import admin
from .models import MonthCycle


@admin.register(MonthCycle)
class MonthCycleAdmin(admin.ModelAdmin):
    list_display = ('name', 'mess', 'status', 'start_date', 'end_date', 'created_at')
    list_filter = ('status', 'mess')
    search_fields = ('name', 'mess__name')