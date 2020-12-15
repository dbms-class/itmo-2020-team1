# encoding: UTF-8

## Веб сервер
import cherrypy

from connect import parse_cmd_line
from connect import create_connection
from static import index

@cherrypy.expose
class App(object):
    def __init__(self, args):
        self.args = args

    @cherrypy.expose
    def start(self):
        return "Hello web app"

    @cherrypy.expose
    def index(self):
      return index()

    @cherrypy.expose
    @cherrypy.tools.json_out()
    def countries(self):
        with create_connection(self.args) as db:
            cur = db.cursor()
            cur.execute("SELECT id, country_name FROM COUNTRIES")
            countries = cur.fetchall()
            result = []
            for c in countries:
                result.append({"id": c[0], "country_name": c[1]})
            return result

    @cherrypy.expose
    @cherrypy.tools.json_out()
    def apartments(self, country_id = None):
        with create_connection(self.args) as db:
            cur = db.cursor()
            if country_id is None:
              cur.execute("SELECT id, name, address, country_id FROM APARTMENTS")
            else:
              cur.execute("SELECT id, name, address, country_id FROM APARTMENTS WHERE country_id=%s", country_id)
            result = []
            apartments = cur.fetchall()
            for a in apartments:
                result.append({"id": a[0], "name": a[1], "address": a[2], "country_id": a[3]})
            return result

    #Устанавливает стоимость аренды жилья apartment_id на неделе номер week в значение price
    @cherrypy.expose
    @cherrypy.tools.json_out()
    def update_price(self, apartment_id, year, week, price):
        with create_connection(self.args) as db:
            cur = db.cursor()
            cur.execute("""INSERT INTO APARTMENT_PRICES(apartment_id, year, start_week, daily_price)
            VALUES (%s, %s, %s, %s)
            ON CONFLICT ON CONSTRAINT uniq_price DO UPDATE  SET daily_price = EXCLUDED.daily_price""", (apartment_id, year, week, price))
            return

    @cherrypy.expose
    @cherrypy.tools.json_out()
    def get_price(self, country_id, year, week, max_price=None, bed_count=None):
        with create_connection(self.args) as db:
            cur = db.cursor()
            args = (country_id, year, week)
            req_add = ""
            if max_price is not None:
                req_add += """ AND AP.daily_price <= %s"""
                args += (max_price,)
            if bed_count is not None:
                req_add += """ AND A.beds >= %s"""
                args += (bed_count,)
            cur.execute("""SELECT A.id, A.name, A.beds, AP.year, AP.start_week, AP.daily_price
                FROM APARTMENTS A JOIN APARTMENT_PRICES AP ON A.id = AP.apartment_id WHERE A.country_id = %s AND AP.year = %s
                AND AP.start_week = %s""" + req_add, args)
            maxp = None
            minp = None
            aparts_result = []
            aparts = cur.fetchall()
            for a in aparts:
                maxp = max(maxp, a[5]) if maxp else a[5]
                minp = min(minp, a[5]) if minp else a[5]
                aparts_result.append({"apartment_id": a[0], "apartment_name": a[1], "bed_count": a[2], "year": a[3], "week": a[4], "price": a[5]})
            result = {"max_price": maxp, "min_price": minp, "apartments": aparts_result}
            return result

    @cherrypy.expose
    @cherrypy.tools.json_out()
    def appt_sale(self, owner_id, week, target_plus):
        with create_connection(self.args) as db:
            cur = db.cursor()
            args = (owner_id, week, week, target_plus, target_plus)
            cur.execute("""WITH apt_profits AS (
            SELECT ap_pr.apartment_id, ap_pr.daily_price as old_price, (ap_pr.daily_price - 50::money) as new_price,
            ((case when (ap_pr.daily_price::numeric - 50) > (select avg(daily_price::numeric) from apartment_prices) 
            then (ap_pr.daily_price - 50::money)*0.7 
            else (ap_pr.daily_price - 50::money)*0.9 end) - ap_pr.daily_price * 0.5)*7 as expected_income
            from apartment_prices ap_pr
            join apartments ap on ap.id = ap_pr.apartment_id
            where ap.host_id = %s
            and ap_pr.start_week = %s
            and ap.id not in (select apartment_id from contracts where extract(week from start_date) = %s))
            ,apt_revs as (
            select apartment_id, old_price, new_price, expected_income, 
            sum(expected_income) over (order by expected_income desc) as rev 
            from apt_profits)
            SELECT apartment_id, old_price, new_price, expected_income from apt_revs
            where rev < %s::money
            or rev = (select min(rev) from apt_revs where rev >= %s::money);""", args)
            sales_result = []
            sales = cur.fetchall()
            cur2 = db.cursor()
            for s in sales:
                sales_result.append(
                    {"apartment_id": s[0], "old_price": s[1], "new_price": s[2], "expected_income": s[3]})
                args = (s[2], s[0], week)
                cur2.execute("""update apartment_prices 
                set daily_price = %s 
                where apartment_id = %s 
                and start_week = %s""", args)
            return sales_result


cherrypy.config.update({
  'server.socket_host': '0.0.0.0',
  'server.socket_port': 8080,
})
cherrypy.quickstart(App(parse_cmd_line()))


