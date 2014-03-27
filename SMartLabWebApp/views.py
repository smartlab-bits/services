'''
Created on Mar 13, 2014

@author: Arjun
'''
from django.contrib import auth
from django.template import Template, Context
from django.http import HttpResponse
from django.template.loader import get_template
from django.core.mail import send_mail
from django.http import HttpResponseRedirect
from django.shortcuts import render, render_to_response, redirect
from django.template.context import RequestContext
from django.contrib.auth.views import logout, login
from django.contrib.auth import authenticate
from django.contrib.auth.decorators import login_required
from SMartLabWebApp import HardwareAccess
from SMartLabWebApp import Port
from SMartLabWebApp import Room
import json


def login_view(request):
    if not request.user.is_authenticated() :
        if request.POST :
            username = request.POST.get('username', '')
            password = request.POST.get('password', '')
            user = auth.authenticate(username=username, password=password)
            if user is not None and user.is_active:
        # Correct password, and the user is marked "active"
                auth.login(request, user)
        # Redirect to a success page.
                return HttpResponseRedirect("../../account/loggedin/")
            else:
        # Show an error page
                return HttpResponseRedirect("../../")
        else:
                return render_to_response('login.html', context_instance=RequestContext(request))
    else:
        return HttpResponseRedirect("../../account/loggedin/")
    
def logout_view(request):
    auth.logout(request)
    # Redirect to a success page.
    return HttpResponseRedirect("/login/")

    
    
def change_port_state(request):
    id = request.GET.get('id')
    roomid = request.GET.get('roomid')
    tostate = request.GET.get('tostate')
    
    return HttpResponse(Port.Port.changeState(id,roomid,tostate))
 
 
def room_view(request):
    strs = HardwareAccess.getJsonConfig()
    details = json.loads(strs)
    mapRooms = []
    mapRoomDetails = []
    mapPort = []
    for i in range(int(details["norooms"])):
        mapRoomDetails.append(Room.Room(i,details["rooms"][i]["room_aliases"]))
        Port.Port.runInit(i, strs)
        mapPort = Port.mapPort
        mapRooms.append(mapPort)
        
    c = Context({"Rooms":mapRooms,"RoomDetails":mapRoomDetails})
    #request.session["mapRooms"] = mapRooms
    #request.session["mapRoomDetails"] = mapRoomDetails
    t = get_template('roomView.html')
    mapRooms = []
    mapRoomDetails = []
    mapPort = []
    return HttpResponse(t.render(c))
       
@login_required   
def main_view(request):
    stri = HardwareAccess.getJsonConfig()
    HardwareAccess.writeStatesFirst(stri)
    t = get_template('main.html')
    c = Context({})
    return HttpResponse(t.render(c))
        