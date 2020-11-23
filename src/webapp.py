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
    def countries(self, country_id = None):
        with create_connection(self.args) as db:
            cur = db.cursor()
            if country_id is None:
              cur.execute("SELECT id, country_name FROM COUNTRIES")
            else:
              cur.execute("SELECT id, country_name FROM COUNTRIES id= %s", country_id)
            result = []
            countries = cur.fetchall()
            for c in countries:
                result.append({"id": c[0], "name": c[1]})
            return result

    #Устанавливает стоимость аренды жилья apartment_id на неделе номер week в значение price
    @cherrypy.expose
    @cherrypy.tools.json_out()
    def update_price(self, apartment_id, year, week, price):
        with create_connection(self.args) as db:
            cur = db.cursor()
            cur.execute("""INSERT INTO APARTMENTS_PRICES(apartment_id, year, start_week, daily_price)
            VALUES (%d, %d, %d, %d)
            ON CONFLICT DO UPDATE  SET daily_price = EXCLUDED.daily_price""", apartment_id, year, week, price,),
            return


cherrypy.config.update({
  'server.socket_host': '0.0.0.0',
  'server.socket_port': 8080,
})
cherrypy.quickstart(App(parse_cmd_line()))


