from django.contrib import admin
from .models import Mess, Membership

@admin.register(Mess)
class MessAdmin(admin.ModelAdmin):
    list_display = ('name', 'join_code', 'created_by', 'created_at')
    search_fields = ('name', 'join_code')
    readonly_fields = ('join_code', 'created_at', 'updated_at')


@admin.register(Membership)
class MembershipAdmin(admin.ModelAdmin):
    list_display = ('user', 'mess', 'role', 'is_active', 'joined_at')
    list_filter = ('role', 'is_active', 'mess')
    search_fields = ('user__email', 'user__full_name', 'mess__name')