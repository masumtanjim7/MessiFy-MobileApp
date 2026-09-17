from rest_framework import serializers
from .models import Mess, Membership


class MembershipSerializer(serializers.ModelSerializer):
    user_name = serializers.ReadOnlyField(source='user.full_name')
    user_email = serializers.ReadOnlyField(source='user.email')
    user_phone = serializers.ReadOnlyField(source='user.phone_number')

    class Meta:
        model = Membership
        fields = ['id', 'user', 'user_name', 'user_email', 'user_phone', 'role', 'is_active', 'joined_at']
        read_only_fields = ['user', 'role', 'joined_at']


class MessSerializer(serializers.ModelSerializer):
    member_count = serializers.SerializerMethodField()
    my_role = serializers.SerializerMethodField()

    class Meta:
        model = Mess
        fields = ['id', 'name', 'address', 'join_code', 'created_by', 'member_count', 'my_role', 'created_at']
        read_only_fields = ['join_code', 'created_by', 'created_at']

    def get_member_count(self, obj):
        return obj.memberships.filter(is_active=True).count()

    def get_my_role(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            membership = obj.memberships.filter(user=request.user).first()
            return membership.role if membership else None
        return None

    def create(self, validated_data):
        user = self.context['request'].user
        mess = Mess.objects.create(created_by=user, **validated_data)
        # The creator is automatically enrolled as the first MANAGER
        Membership.objects.create(
            user=user,
            mess=mess,
            role=Membership.Role.MANAGER
        )
        return mess


class JoinMessSerializer(serializers.Serializer):
    join_code = serializers.CharField(max_length=10, required=True)

    def validate_join_code(self, value):
        code = value.strip().upper()
        if not Mess.objects.filter(join_code=code).exists():
            raise serializers.ValidationError("Invalid join code. No mess found with this code.")
        return code