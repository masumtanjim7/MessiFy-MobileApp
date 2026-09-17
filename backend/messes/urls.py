from django.urls import path
from .views import MessListCreateView, JoinMessView, MessMembersListView

urlpatterns = [
    path('', MessListCreateView.as_view(), name='mess_list_create'),
    path('join/', JoinMessView.as_view(), name='join_mess'),
    path('<int:mess_id>/members/', MessMembersListView.as_view(), name='mess_members_list'),
]