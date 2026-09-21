from django.contrib import admin
from .models import MonthCycle, DailyMeal


@admin.register(MonthCycle)
class MonthCycleAdmin(admin.ModelAdmin):
    list_display = ('name', 'mess', 'status', 'start_date', 'end_date', 'created_at')
    list_filter = ('status', 'mess')
    search_fields = ('name', 'mess__name')


@admin.register(DailyMeal)
class DailyMealAdmin(admin.ModelAdmin):
    list_display = ('date', 'membership', 'breakfast', 'lunch', 'dinner', 'total_meals', 'cycle')
    list_filter = ('date', 'cycle', 'cycle__mess')
    search_fields = ('membership__user__full_name', 'membership__user__email')