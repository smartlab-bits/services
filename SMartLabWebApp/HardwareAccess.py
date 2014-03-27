'''
Created on Mar 13, 2014

@author: Arjun
'''
#Gets the initial JSON config and later communicates with the Panda Board 

#write str into a file and render it back later for persictence
import os
import json

def getJsonConfig():
    BASE_DIR = os.path.dirname(os.path.dirname(__file__))
    f = open( os.path.join(BASE_DIR, 'house_model.json'),'r')
    stri = f.read()
    f.close()
    '''str = {
            "norooms": "2",
            "rooms": [
                {
                    "room_id": "R0",
                    "room_aliases": [
                        "my room",
                        "living room",
                        "default",
                        "here"
                    ],
                    "noports": "2",
                    "ports": [
                        {
                            "port_id": "P0",
                            "port_device": "L",
                            "port_aliases": [
                                "light",
                                " bulb"
                            ]
                        },
                        {
                            "port_aliases": [
                                "fan",
                                " cool"
                            ],
                            "port_device": "F",
                            "port_id": "P1"
                        }
                    ]
                },
                {
                    "room_id": "R1",
                    "room_aliases": [
                        "kitchen"
                    ],
                    "noports": "2",
                    "ports": [
                        {
                            "port_id": "P0",
                            "port_device": "L",
                            "port_aliases": [
                                "light",
                                " bulb"
                            ]
                        },
                        {
                            "port_aliases": [
                                "fan",
                                " cool"
                            ],
                            "port_device": "F",
                            "port_id": "P1"
                        }
                    ]
                }
            ]
        }'''
    
    #f = open( 'C:\Workspace\SMartLabWebApp\SMartLabWebApp\tempJson.txt','w+')
    #f.write(stri)
    #f.close()
    #print stri
    
    return stri
    
    
    
    
    
def getSecondJson():
    BASE_DIR = os.path.dirname(os.path.dirname(__file__))
    f = open(os.path.join(BASE_DIR, 'tempJson.txt'), 'r+')
    stri = f.read()
    f.close()
    return stri
  
def writeStatesFirst(stri):
    BASE_DIR = os.path.dirname(os.path.dirname(__file__))
    f = open(os.path.join(BASE_DIR, 'states.txt'),'w')
    f.write('')
    f.close()
    f = open(os.path.join(BASE_DIR, 'states.txt'),'a+')
    details = json.loads(stri)
    #print stri
    for i in range(int(details["norooms"])):
        for j in range(int(details['rooms'][i]['noports'])):
            o = details['rooms'][i]['ports'][j]
            stateDetails = 'R' + str(i) +  o['port_id'].encode('ascii','ignore') + ' ' + o['port_state'].encode('ascii','ignore')             
            f.write(stateDetails)
            print "STate Details: " + stateDetails
    f.close()
    
def changeState(id,tostate):
    BASE_DIR = os.path.dirname(os.path.dirname(__file__))
    #communicate with the change pandaBoard to change the state
    
    if tostate == 'True':
        to = 'T'
    else:
        to = 'F'
    
    while True:
        f = open(os.path.join(BASE_DIR, 'from_gui.txt'),'w')
        #print "Reached 1"
        if f is not None:
            break
    f.write(id + ' ' +  to)
    f.close()
    while True:
        f = open(os.path.join(BASE_DIR, 'states.txt'),'r')
        if f is not None:
            break
    states = f.read()
    print "STates" + states
    index = states.find(id)
    index += 5 
    
    part1 = states[0:index]
    print "part1" + part1
    part2 = states[index+1:len(states)]
    print "Part2:" + part2
    final = part1 +to+part2
    print "Final:" + final
    f.close()
    while True:
        f = open(os.path.join(BASE_DIR, 'states.txt'),'w+')
        if f is not None:
            break   
    f.write(final)
    f.close()
    return tostate

def getState(id):
    BASE_DIR = os.path.dirname(os.path.dirname(__file__))
    #communicate with the panda Board and get the state
    f = open(os.path.join(BASE_DIR, 'states.txt'),'r')
    states = f.read()
    #print "Length is:" + str(len(states))
    index = states.find(id)
    #print index
    index += 5 
    state = states[index]
    f.close()
    if state == 'T':
        tostate = True
    else:
        tostate = False
    return tostate
