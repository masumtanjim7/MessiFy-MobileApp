from decimal import Decimal, ROUND_HALF_UP
from django.db.models import Sum
from meals.models import DailyMeal, MonthCycle
from messes.models import Membership
from .models import Deposit, Expense


def round_currency(value):
    """Utility to round values to 2 decimal places using standard financial rounding."""
    return Decimal(value).quantize(Decimal('0.01'), rounding=ROUND_HALF_UP)


def calculate_cycle_balance_sheet(cycle: MonthCycle):
    """
    Computes meal rates, individual member liabilities, deposits, 
    and final settlement balances for a specific MonthCycle.
    """
    # 1. Total bazaar expenses (shared strictly by meal count)
    total_bazaar = cycle.expenses.filter(
        category=Expense.Category.BAZAAR
    ).aggregate(total=Sum('amount'))['total'] or Decimal('0.00')

    # 2. Total common shared expenses (split equally across all active members)
    common_categories = [
        Expense.Category.UTILITY,
        Expense.Category.RENT,
        Expense.Category.MAID,
        Expense.Category.OTHER
    ]
    total_shared_expenses = cycle.expenses.filter(
        category__in=common_categories
    ).aggregate(total=Sum('amount'))['total'] or Decimal('0.00')

    # 3. Aggregate all meals recorded during this cycle
    meal_records = DailyMeal.objects.filter(cycle=cycle)
    total_breakfast = meal_records.aggregate(total=Sum('breakfast'))['total'] or Decimal('0.0')
    total_lunch = meal_records.aggregate(total=Sum('lunch'))['total'] or Decimal('0.0')
    total_dinner = meal_records.aggregate(total=Sum('dinner'))['total'] or Decimal('0.0')
    total_meals = total_breakfast + total_lunch + total_dinner

    # 4. Calculate meal rate (guard against division by zero)
    meal_rate = Decimal('0.00')
    if total_meals > Decimal('0.0'):
        meal_rate = round_currency(total_bazaar / total_meals)

    # 5. Active members in this mess
    memberships = Membership.objects.filter(mess=cycle.mess, is_active=True).select_related('user')
    member_count = memberships.count() or 1
    shared_cost_per_member = round_currency(total_shared_expenses / Decimal(member_count))

    # 6. Build individual financial breakdowns
    member_summaries = []
    total_deposits_collected = Decimal('0.00')

    for member in memberships:
        # Sum member's consumed meals
        member_meals_qs = meal_records.filter(membership=member)
        m_bf = member_meals_qs.aggregate(total=Sum('breakfast'))['total'] or Decimal('0.0')
        m_lu = member_meals_qs.aggregate(total=Sum('lunch'))['total'] or Decimal('0.0')
        m_di = member_meals_qs.aggregate(total=Sum('dinner'))['total'] or Decimal('0.0')
        m_total_meals = m_bf + m_lu + m_di

        # Calculate costs
        member_meal_cost = round_currency(m_total_meals * meal_rate)
        member_total_cost = round_currency(member_meal_cost + shared_cost_per_member)

        # Sum member's approved deposits
        member_deposit = cycle.deposits.filter(
            membership=member,
            status=Deposit.Status.APPROVED
        ).aggregate(total=Sum('amount'))['total'] or Decimal('0.00')

        total_deposits_collected += member_deposit
        net_balance = round_currency(member_deposit - member_total_cost)

        member_summaries.append({
            "membership_id": member.id,
            "user_name": member.user.full_name,
            "user_email": member.user.email,
            "role": member.role,
            "total_meals": float(m_total_meals),
            "meal_cost": float(member_meal_cost),
            "shared_cost": float(shared_cost_per_member),
            "total_cost": float(member_total_cost),
            "total_deposited": float(member_deposit),
            "net_balance": float(net_balance),
            "status": "SURPLUS" if net_balance >= 0 else "DUE"
        })

    total_mess_expenses = total_bazaar + total_shared_expenses
    mess_cash_in_hand = round_currency(total_deposits_collected - total_mess_expenses)

    return {
        "cycle_id": cycle.id,
        "cycle_name": cycle.name,
        "cycle_status": cycle.status,
        "start_date": cycle.start_date,
        "end_date": cycle.end_date,
        "financial_overview": {
            "total_bazaar_expense": float(total_bazaar),
            "total_shared_expense": float(total_shared_expenses),
            "total_mess_expense": float(total_mess_expenses),
            "total_deposits_collected": float(total_deposits_collected),
            "cash_in_hand": float(mess_cash_in_hand),
            "total_meals_served": float(total_meals),
            "meal_rate": float(meal_rate),
            "active_members_count": member_count,
        },
        "member_summaries": member_summaries
    }