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
    def appt_sale(self, owner_id, year, week, target_price):
        avg_price = None
        with create_connection(self.args) as db:
            cur = db.cursor()
            cur.execute("""SELECT AVG(daily_price::NUMERIC * 7) FROM APARTMENT_PRICES AP JOIN
                        APARTMENTS A ON AP.apartment_id = A.id WHERE start_week = %s AND year = %s""",
                        (week, year))
            avg_res = cur.fetchall()
            avg_price = avg_res[0][0]

        apts_to_sale = []
        with create_connection(self.args) as db:
            cur = db.cursor()
            date = str(year) + "-01-01"
            cur.execute("""SELECT A.id, (AP.daily_price * 7)::NUMERIC AS old_price, (AP.daily_price * 7 - 350::MONEY)::NUMERIC AS new_price,
            ((case when (AP.daily_price * 7 - 350::MONEY) < %s::MONEY THEN ((AP.daily_price * 7 - 350::MONEY) * 0.9) ELSE ((AP.daily_price * 7 - 350::MONEY) * 0.7) END) - AP.daily_price * 7 * 0.5)::NUMERIC AS expected_income
            FROM APARTMENTS A JOIN APARTMENT_PRICES AP ON A.id = AP.apartment_id
            LEFT JOIN CONTRACTS C ON C.apartment_id = A.id
            WHERE C.start_date IS NULL OR ((%s::date + 7 * %s) NOT BETWEEN C.start_date AND C.end_date
            AND A.host_id = %s)
            ORDER BY expected_income DESC""",
                (avg_price, date, week, owner_id))
            que_res = cur.fetchall()
            total_inc = 0
            for res in que_res:
                if float(res[3]) <= 0:
                    continue
                apts_to_sale.append({"apartment_id": res[0], "old_price": float(res[1]), "new_price": float(res[2]), "expected_income": float(res[3])})
                total_inc += float(res[3])
                if total_inc >= float(target_price):
                    break
            print(apts_to_sale)

        with create_connection(self.args) as db:
            cur = db.cursor()
            for apt in apts_to_sale:
                cur.execute("""UPDATE APARTMENT_PRICES SET daily_price = %s::MONEY WHERE apartment_id = %s AND year = %s AND start_week = %s""",
                        (apt['new_price'] / 7, apt['apartment_id'], year, week))

        return apts_to_sale


cherrypy.config.update({
  'server.socket_host': '0.0.0.0',
  'server.socket_port': 8080,
})
cherrypy.quickstart(App(parse_cmd_line()))


