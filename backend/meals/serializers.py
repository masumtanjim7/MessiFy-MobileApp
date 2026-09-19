from rest_framework import serializers
from .models import MonthCycle


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