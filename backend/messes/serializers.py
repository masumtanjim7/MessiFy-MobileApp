from rest_framework import serializers
from .models import Mess, Membership


class MembershipSerializer(serializers.ModelSerializer):
    user_name = serializers.ReadOnlyField(source='user.full_name')
    user_email = serializers.ReadOnlyField(source='user.email')
    user_phone = serializers.ReadOnlyField(source='user.phone_number')

    class Meta:
        model = Membership
        fields = [
            'id',
            'user',
            'user_name',
            'user_email',
            'user_phone',
            'role',
            'is_active',
            'joined_at',
        ]
        read_only_fields = ['user', 'role', 'joined_at']


class MessSerializer(serializers.ModelSerializer):
    member_count = serializers.SerializerMethodField()
    my_role = serializers.SerializerMethodField()
    invite_code = serializers.CharField(source='join_code', read_only=True)

    class Meta:
        model = Mess
        fields = [
            'id',
            'name',
            'address',
            'join_code',
            'invite_code',
            'created_by',
            'member_count',
            'my_role',
            'created_at',
        ]
        read_only_fields = ['join_code', 'invite_code', 'created_by', 'created_at']

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
            role=Membership.Role.MANAGER,
        )
        return mess


class JoinMessSerializer(serializers.Serializer):
    join_code = serializers.CharField(max_length=10, required=False)
    invite_code = serializers.CharField(max_length=10, required=False)

    def validate(self, attrs):
        code = attrs.get('join_code') or attrs.get('invite_code')
        if not code:
            raise serializers.ValidationError(
                {"join_code": "Join/Invite code is required."}
            )
        code = code.strip().upper()
        if not Mess.objects.filter(join_code=code).exists():
            raise serializers.ValidationError(
                {"join_code": "Invalid join code. No mess found with this code."}
            )
        attrs['join_code'] = code
        return attrs