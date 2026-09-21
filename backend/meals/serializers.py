from rest_framework import serializers
from .models import MonthCycle, DailyMeal


class MonthCycleSerializer(serializers.ModelSerializer):
    class Meta:
        model = MonthCycle
        fields = [
            'id', 
            'mess', 
            'name', 
            'start_date', 
            'end_date', 
            'status', 
            'created_at', 
            'updated_at'
        ]
        read_only_fields = ['created_at', 'updated_at']

    def validate(self, attrs):
        mess = attrs.get('mess') or (self.instance.mess if self.instance else None)
        status = attrs.get('status', MonthCycle.Status.ACTIVE)

        if status == MonthCycle.Status.ACTIVE and mess:
            active_query = MonthCycle.objects.filter(mess=mess, status=MonthCycle.Status.ACTIVE)
            if self.instance:
                active_query = active_query.exclude(pk=self.instance.pk)
            if active_query.exists():
                raise serializers.ValidationError({
                    "status": "An active month cycle already exists for this mess. Lock or settle it before creating a new one."
                })
        return attrs


class DailyMealSerializer(serializers.ModelSerializer):
    member_name = serializers.ReadOnlyField(source='membership.user.full_name')
    total_meals = serializers.ReadOnlyField()

    class Meta:
        model = DailyMeal
        fields = [
            'id',
            'cycle',
            'membership',
            'member_name',
            'date',
            'breakfast',
            'lunch',
            'dinner',
            'total_meals',
            'notes',
            'created_at',
            'updated_at'
        ]
        read_only_fields = ['total_meals', 'created_at', 'updated_at']

    def validate(self, attrs):
        cycle = attrs.get('cycle') or (self.instance.cycle if self.instance else None)
        if cycle and cycle.status != MonthCycle.Status.ACTIVE:
            raise serializers.ValidationError("Cannot log or modify meals in a locked or settled cycle.")
        return attrs


class BulkMealEntryItemSerializer(serializers.Serializer):
    membership_id = serializers.IntegerField()
    breakfast = serializers.DecimalField(max_digits=3, decimal_places=1, min_value=0)
    lunch = serializers.DecimalField(max_digits=3, decimal_places=1, min_value=0)
    dinner = serializers.DecimalField(max_digits=3, decimal_places=1, min_value=0)
    notes = serializers.CharField(max_length=100, required=False, allow_blank=True)


class BulkMealSubmitSerializer(serializers.Serializer):
    date = serializers.DateField()
    entries = BulkMealEntryItemSerializer(many=True)