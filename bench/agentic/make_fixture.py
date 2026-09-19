#!/usr/bin/env python3
"""Build the `shop` fixture repo used by the agentic token benchmark.

The repo is deliberately wider than any single task needs (~25 modules), so an
agent that reads everything pays for it and one that searches narrowly does not.

Usage: python make_fixture.py DEST [--bug]    # --bug plants the pricing defect
"""
import os, sys, textwrap

FILES = {
    "shop/__init__.py": "",
    "shop/config/__init__.py": "",
    "shop/config/settings.py": '''
        CURRENCY = "USD"
        DEFAULT_COUNTRY = "US"
        TAX_RATES = {"US": 0.07, "CO": 0.19, "MX": 0.16, "BR": 0.17, "AR": 0.21}
        FREE_SHIPPING_THRESHOLD = 100.0
        MAX_ITEMS_PER_ORDER = 50
    ''',
    "shop/tax.py": '''
        from shop.config.settings import TAX_RATES, DEFAULT_COUNTRY


        def tax_rate(country=None):
            return TAX_RATES.get(country or DEFAULT_COUNTRY, 0.0)


        def add_tax(amount, country=None):
            return round(amount * (1 + tax_rate(country)), 2)
    ''',
    "shop/pricing.py": '''
        def apply_discount(price, percent):
            """Return price reduced by `percent` (0-100), rounded to cents."""
            if not 0 <= percent <= 100:
                raise ValueError("percent must be between 0 and 100")
            return round(price * percent / 100, 2)


        def bulk_price(unit_price, qty):
            if qty >= 10:
                return apply_discount(unit_price * qty, 10)
            return round(unit_price * qty, 2)
    ''',
    "shop/cart.py": '''
        from shop.pricing import bulk_price
        from shop.tax import add_tax


        class Cart:
            def __init__(self, country=None):
                self.items = []
                self.country = country

            def add(self, sku, unit_price, qty=1):
                self.items.append((sku, unit_price, qty))

            def subtotal(self):
                return round(sum(bulk_price(p, q) for _, p, q in self.items), 2)


        def calc_total(cart):
            return add_tax(cart.subtotal(), cart.country)
    ''',
    "shop/orders.py": '''
        from dataclasses import dataclass, field
        from shop.cart import calc_total


        @dataclass
        class Order:
            id: int
            customer: str
            cart: object
            status: str = "new"
            notes: list = field(default_factory=list)

            @property
            def total(self):
                return calc_total(self.cart)


        def mark_paid(order):
            order.status = "paid"
            order.notes.append("paid")
            return order
    ''',
    "shop/invoices.py": '''
        from shop.cart import calc_total


        def invoice_lines(order):
            lines = [f"Invoice #{order.id} for {order.customer}"]
            for sku, price, qty in order.cart.items:
                lines.append(f"{sku} x{qty} @ {price:.2f}")
            lines.append(f"TOTAL {calc_total(order.cart):.2f}")
            return lines
    ''',
    "shop/reports.py": '''
        def revenue(orders):
            return round(sum(o.total for o in orders if o.status == "paid"), 2)


        def orders_by_customer(orders):
            out = {}
            for o in orders:
                out.setdefault(o.customer, []).append(o.id)
            return out
    ''',
    "tests/__init__.py": "",
    "tests/test_pricing.py": '''
        import unittest
        from shop.pricing import apply_discount, bulk_price


        class PricingTest(unittest.TestCase):
            def test_discount(self):
                self.assertEqual(apply_discount(200.0, 25), 150.0)

            def test_no_discount(self):
                self.assertEqual(apply_discount(80.0, 0), 80.0)

            def test_bulk(self):
                self.assertEqual(bulk_price(10.0, 10), 90.0)
    ''',
    "tests/test_orders.py": '''
        import unittest
        from shop.cart import Cart
        from shop.orders import Order, mark_paid
        from shop.reports import revenue


        class OrdersTest(unittest.TestCase):
            def test_total_with_tax(self):
                c = Cart(country="CO"); c.add("A", 100.0)
                self.assertEqual(Order(1, "ana", c).total, 119.0)

            def test_revenue_counts_paid_only(self):
                c = Cart(); c.add("A", 10.0)
                a, b = Order(1, "ana", c), Order(2, "bo", c)
                mark_paid(a)
                self.assertEqual(revenue([a, b]), 10.7)
    ''',
}

# Filler modules: plausible, unrelated code that makes "read everything" expensive.
FILLER = ["catalog", "users", "shipping", "inventory", "notifications", "audit",
          "coupons", "returns", "warehouse", "suppliers", "loyalty", "reviews",
          "search", "sessions", "webhooks", "payments_gateway"]
FILLER_BODY = '''
    """{name} service."""
    import logging

    log = logging.getLogger(__name__)
    _STORE = {{}}


    def create_{name}(key, **fields):
        if key in _STORE:
            raise KeyError(f"{name} {{key}} exists")
        _STORE[key] = dict(fields, key=key, active=True)
        log.info("created {name} %s", key)
        return _STORE[key]


    def get_{name}(key):
        return _STORE.get(key)


    def update_{name}(key, **fields):
        rec = _STORE[key]
        rec.update(fields)
        return rec


    def deactivate_{name}(key):
        rec = _STORE[key]
        rec["active"] = False
        return rec


    def list_{name}(active_only=True):
        return [r for r in _STORE.values() if r["active"] or not active_only]


    def search_{name}(term):
        term = term.lower()
        return [r for r in _STORE.values() if any(term in str(v).lower() for v in r.values())]


    def export_{name}():
        return [dict(r) for r in _STORE.values()]


    def import_{name}(rows):
        for row in rows:
            _STORE[row["key"]] = dict(row)
        return len(rows)
'''


def main(dest, bug):
    files = dict(FILES)
    if not bug:
        files["shop/pricing.py"] = files["shop/pricing.py"].replace("price * percent / 100", "price * (100 - percent) / 100")
    for n in FILLER:
        files[f"shop/{n}.py"] = FILLER_BODY.format(name=n)
    for rel, body in files.items():
        path = os.path.join(dest, rel)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w") as f:
            f.write(textwrap.dedent(body).lstrip("\n"))


if __name__ == "__main__":
    main(sys.argv[1], "--bug" in sys.argv)
