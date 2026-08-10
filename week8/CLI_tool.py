import sqlite3
from datetime import datetime, timedelta

def get_date_input(prompt):
    while True:
        date_str = input(prompt)
        try:
            valid_date = datetime.strptime(date_str, "%Y-%m-%d")
            return valid_date
        except ValueError:
            print("Invalid format. Please use YYYY-MM-DD.")

def calculate_previous_period(start_date, end_date):
    
    delta = end_date - start_date + timedelta(days=1)
    prev_end_date = start_date - timedelta(days=1)
    prev_start_date = prev_end_date - delta + timedelta(days=1)
    return prev_start_date, prev_end_date

def get_summary_metrics(cursor, start_str, end_str):
    
    query = """
        SELECT COUNT(DISTINCT o.order_id) AS total_orders,
               COUNT(DISTINCT o.customer_id) AS unique_customers,
               IFNULL(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_percent / 100.0)), 0) AS total_revenue
        FROM orders o
        LEFT JOIN order_items oi ON o.order_id = oi.order_id
        WHERE DATE(o.order_date) BETWEEN ? AND ?
    """
    cursor.execute(query, (start_str, end_str))
    return cursor.fetchone()

def get_top_products(cursor, start_str, end_str):
    
    query = """
        SELECT p.product_name, 
               SUM(oi.quantity * oi.unit_price * (1 - oi.discount_percent / 100.0)) AS revenue
        FROM orders o
        JOIN order_items oi ON o.order_id = oi.order_id
        JOIN products p ON oi.product_id = p.product_id
        WHERE DATE(o.order_date) BETWEEN ? AND ?
        GROUP BY p.product_id
        ORDER BY revenue DESC
        LIMIT 3
    """
    cursor.execute(query, (start_str, end_str))
    return cursor.fetchall()

def generate_report():
    print("=== E-Commerce Order Analytics System ===")
    
    
    report_type = input("Enter report type (daily/weekly/monthly): ").strip().lower()
    
    print("\nPlease enter the date range for your report.")
    start_date = get_date_input("Start Date (YYYY-MM-DD): ")
    end_date = get_date_input("End Date (YYYY-MM-DD): ")
    
    if start_date > end_date:
        print("Error: Start Date must be before End Date.")
        return

    prev_start, prev_end = calculate_previous_period(start_date, end_date)
    
    start_str, end_str = start_date.strftime("%Y-%m-%d"), end_date.strftime("%Y-%m-%d")
    p_start_str, p_end_str = prev_start.strftime("%Y-%m-%d"), prev_end.strftime("%Y-%m-%d")

    
    conn = sqlite3.connect('ecommerce.db')
    cursor = conn.cursor()

    try:
        
        curr_orders, curr_customers, curr_revenue = get_summary_metrics(cursor, start_str, end_str)
        
        
        prev_orders, prev_customers, prev_revenue = get_summary_metrics(cursor, p_start_str, p_end_str)
        
        
        top_products = get_top_products(cursor, start_str, end_str)

        
        def calc_change(curr, prev):
            if prev == 0:
                return 100.0 if curr > 0 else 0.0
            return ((curr - prev) / prev) * 100

        rev_change = calc_change(curr_revenue, prev_revenue)
        ord_change = calc_change(curr_orders, prev_orders)

        
        print(f"\n{'='*45}")
        print(f" SUMMARY REPORT ({report_type.upper()})")
        print(f" Period: {start_str} to {end_str}")
        print(f" Comparison Period: {p_start_str} to {p_end_str}")
        print(f"{'='*45}")
        
        print(f"\n--- KEY METRICS ---")
        print(f"Total Revenue:      ${curr_revenue:,.2f} ({rev_change:+.2f}% vs prev)")
        print(f"Total Orders:       {curr_orders} ({ord_change:+.2f}% vs prev)")
        print(f"Unique Customers:   {curr_customers}")
        
        print(f"\n--- TOP 3 PRODUCTS BY REVENUE ---")
        if top_products:
            for i, (name, rev) in enumerate(top_products, 1):
                print(f"{i}. {name} - ${rev:,.2f}")
        else:
            print("No sales data in this period.")
            
        print(f"{'='*45}\n")

    except Exception as e:
        print(f"An error occurred during report generation: {e}")
    finally:
        conn.close()

if __name__ == "__main__":
    generate_report()