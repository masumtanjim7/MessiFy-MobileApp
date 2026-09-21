from django.contrib import admin
from .models import Deposit, Expense


@admin.register(Deposit)
class DepositAdmin(admin.ModelAdmin):
    list_display = ('date', 'membership', 'amount', 'status', 'cycle')
    list_filter = ('status', 'cycle', 'cycle__mess')
    search_fields = ('membership__user__full_name', 'membership__user__email')


@admin.register(Expense)
class ExpenseAdmin(admin.ModelAdmin):
    list_display = ('date', 'category', 'amount', 'spent_by', 'description', 'cycle')
    list_filter = ('category', 'cycle', 'cycle__mess')
    search_fields = ('description', 'spent_by__user__full_name')