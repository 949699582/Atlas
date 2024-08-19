import argparse
import urllib2
import urllib
import json

if __name__ == '__main__':

    print("Start ChipSN From MES")
    parser = argparse.ArgumentParser(description='Sip Test')

    parser.add_argument('-sn', '--sn', help='sn.', type=str, default=False, required=True)

    # parser.add_argument('-k', '--k', help='k.', type=str, default=False, required=True)

    args = parser.parse_args()


    file = open('/vault/data_collection/test_station_config/gh_station_info.json', "rb")

    fileJson = json.load(file)

#    url = 'http://10.33.20.148/bobcat/sfc_response.aspx?sn=GTQ02314E58P2R0AG&c=QUERY_RECORD&p=GET_FATP_SN_BY_SIP_SN'

    url = fileJson['ghinfo']['SFC_URL']
    print(url)
    # url = "http://10.191.243.238/api/bobcat"

    stationID = fileJson['ghinfo']['STATION_ID']
    print(stationID)

#    url = 'http://10.33.20.148/bobcat/sfc_response.aspx'

    data = {"c":"QUERY_RECORD","p":"QUERY_PANEL","sn":args.sn,"tsid":stationID}

    url_values = urllib.urlencode(data)
    print(url_values)

    res = urllib2.urlopen(url,url_values)
    print("==url return=====")
    print(res)

    print(res.read())

