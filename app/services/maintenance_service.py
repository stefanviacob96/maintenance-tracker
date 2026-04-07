from datetime import datetime, timedelta


def calculate_next_due_date(completed_at_str, frequency_days):
    completed_date = datetime.strptime(completed_at_str, "%Y-%m-%d").date()
    next_due_date = completed_date + timedelta(days=frequency_days)
    return next_due_date.isoformat()
