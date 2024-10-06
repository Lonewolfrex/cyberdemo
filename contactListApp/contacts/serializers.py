# contacts/serializers.py
from rest_framework import serializers
from .models import Contact

class ContactSerializer(serializers.ModelSerializer):
    class Meta:
        model = Contact
        fields = ['id', 'name', 'email', 'phone', 'address', 'user']  # Adjust according to your model fields
        read_only_fields = ['user']  # Prevent users from modifying this field directly
