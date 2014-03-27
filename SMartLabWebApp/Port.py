'''
Created on Mar 13, 2014

@author: Arjun
'''
#All the components are  basically reffered to as ports
import json
import HardwareAccess
mapPort = []
class Port(object):
    @staticmethod
    def runInit(roomid,jsonString):
        global mapPort
        mapPort = []
        roomDetails = json.loads(jsonString)
        for j in range(int(roomDetails['rooms'][roomid]['noports'])):
            o = roomDetails['rooms'][roomid]['ports'][j]
            global mapPort
            idt = 'R' + str(roomid) + o['port_id'].encode('ascii','ignore')
            mapPort.append(Port(idt,o['port_device'].encode('ascii','ignore'),o['port_aliases'][0].encode('ascii','ignore'),roomid))
    
    def __init__(self,id,des,deviceId,roomid):
        self.id = id
        self.des = des
        self.roomid = roomid
        self.deviceId = deviceId
        self.state = Port.getState(id)
        
    @staticmethod
    def changeState(id,roomid,tostate): 
        return HardwareAccess.changeState(id, tostate)
    
    @staticmethod
    def getState(id):
        #get the state from pipes
        return HardwareAccess.getState(id)