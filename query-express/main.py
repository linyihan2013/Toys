import urllib.request
import urllib.parse
import urllib.response
import json
from html.parser import HTMLParser

#   Strip HTML tags from strings
class MLStripper(HTMLParser):
    def __init__(self):
        self.reset()
        self.strict = False
        self.convert_charrefs= True
        self.fed = []
    def handle_data(self, d):
        self.fed.append(d)
    def get_data(self):
        return ''.join(self.fed)

#   Query the state about the express from Shunfeng
def QueryShunfeng(express_number):

    #   Assert if the length of the express number is not 12
    if len(express_number) != 12:
        print("运单号码必须为12位长。\n")
        return

    #   Generate the URL with data in the GET method
    values = {'app':'bill',
              'lang':'sc',
              'region':'cn',
              'translate':''}
    data = urllib.parse.urlencode(values)
    url = "http://www.sf-express.com/sf-service-web/service/bills/%s/routes?%s" % (express_number, data)

    #   Request for the URL
    req = urllib.request.Request(url)
    try:
        res = urllib.request.urlopen(req)
        content = res.read().decode()
        content = json.loads(content)

        #   Parse the response
        if len(content) <= 0:
            print("抱歉！未查到此运单%s信息，请确认运单号码是否正确。\n" % express_number)
        else:
            content = content[0]

            #   Print the state out the express
            if content['id']:
                print("快递单号", ':', content['id'])
            if content['productName']:
                print("产品名", ':', content['productName'])
            if content['origin']:
                print("出发地", ':', content['origin'])
            if content['destination']:
                print("目的地", ':', content['destination'])
            if content['warehouse']:

                if content['warehouse']:
                    print('已出库', ':', "是")
                else:
                    print('已出库', ':', "否")
            if content['delivered']:

                if content['delivered']:
                    print('已发货', ':', "是")
                else:
                    print('已发货', ':', "否")
            if content['expressState']:
                expressState = ""

                if content['expressState'] == '1':
                    expressState = "已签收"
                elif content['expressState'] == '2':
                    expressState = "已作废"
                elif content['expressState'] == '3':
                    expressState = "已转寄"
                elif content['expressState'] == '4':
                    expressState = "已退回"
                elif content['expressState'] == '5':
                    expressState = "已扣件"
                elif content['expressState'] == '6':
                    expressState = "已遗失"

                print("快递状态", ':', expressState)
            if content['routes']:
                print("运输路线", ':')

                for step in content['routes']:
                    if step['stayWhyCode'] != '1':
                        # Use MLStripper to strip HTML tags
                        if step['scanDateTime'] and step['remark']:
                            s = MLStripper()
                            s.feed(step['remark'])
                            print('\t', step['scanDateTime'], '\t', s.get_data())
            print()

    except urllib.request.HTTPError as e:
        print('The server couldn\'t fulfill the request.')
        print('Error code: ', e.code)
    except urllib.request.URLError as e:
        print('We failed to reach a server.')
        print('Reason: ', e.reason)

if __name__ == "__main__":
    print("欢迎使用顺丰快递查询。\n")
    while True:
        print("请输入快递单号：")
        try:
            express_number = input()
            QueryShunfeng(express_number)
        except EOFError as e:
            exit(0)