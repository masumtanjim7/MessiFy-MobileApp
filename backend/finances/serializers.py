from rest_framework import serializers
from .models import Deposit, Expense
from meals.models import MonthCycle


class DepositSerializer(serializers.ModelSerializer):
    member_name = serializers.ReadOnlyField(source='membership.user.full_name')

    class Meta:
        model = Deposit
        fields = [
            'id', 
            'cycle', 
            'membership', 
            'member_name', 
            'amount', 
            'date', 
            'status', 
            'notes', 
            'created_at'
        ]
        read_only_fields = ['created_at']

    def validate(self, attrs):
        cycle = attrs.get('cycle') or (self.instance.cycle if self.instance else None)
        if cycle and cycle.status != MonthCycle.Status.ACTIVE:
            raise serializers.ValidationError("Cannot record deposits in a locked or settled cycle.")
        return attrs


class ExpenseSerializer(serializers.ModelSerializer):
    spent_by_name = serializers.ReadOnlyField(source='spent_by.user.full_name')

    class Meta:
        model = Expense
        fields = [
            'id', 
            'cycle', 
            'spent_by', 
            'spent_by_name', 
            'category', 
            'amount', 
            'date', 
            'description', 
            'receipt_image', 
            'created_at'
        ]
        read_only_fields = ['created_at']

    def validate(self, attrs):
        cycle = attrs.get('cycle') or (self.instance.cycle if self.instance else None)
        if cycle and cycle.status != MonthCycle.Status.ACTIVE:
            raise serializers.ValidationError("Cannot record expenses in a locked or settled cycle.")
        return attrs