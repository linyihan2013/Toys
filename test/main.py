#-*- coding: utf-8 -*-
import os.path
import tornado.httpserver
import tornado.ioloop
import tornado.web
import tornado.options
import mako.lookup
import mako.template
from tornado.options import define, options

define("port", default=8888, help="run on the given port", type=int)

class BaseHandler(tornado.web.RequestHandler):
    def initialize(self):
        template_path = self.get_template_path()
        self.lookup = mako.lookup.TemplateLookup(directories=[template_path], input_encoding='utf-8', output_encoding='utf-8')

    def render_string(self, filename, **kwargs):
        template = self.lookup.get_template(filename)
        namespace = self.get_template_namespace()
        namespace.update(kwargs)
        return template.render(**namespace)

    def render(self, filename, **kwargs):
        self.finish(self.render_string(filename, **kwargs))

class MainHandler(BaseHandler):
    def get(self):
        self.render('mybidong.html',days='10',hours='6', coin='12')

class Application(tornado.web.Application):
    def __init__(self):
        handlers = [
               (r'/',MainHandler),
               ]
        settings = {
               'template_path' : os.path.join(os.path.dirname(__file__),'templates')
               }
        tornado.web.Application.__init__(self, handlers,**settings)

def main():
    tornado.options.parse_command_line()
    application = Application()
    http_server = tornado.httpserver.HTTPServer(application)
    http_server.listen(options.port)
    tornado.ioloop.IOLoop.instance().start()

if __name__ == "__main__":
    main()
