from django.conf.urls import patterns, include, url
from SMartLabWebApp.views import login_view , main_view, logout_view,\
    change_port_state, room_view
from django.contrib import admin
admin.autodiscover()

urlpatterns = patterns('',
    # Examples:
    # url(r'^$', 'SMartLabWebApp.views.home', name='home'),
    # url(r'^blog/', include('blog.urls')),

    url(r'^admin/', include(admin.site.urls)),
    url(r'^$', login_view),
    url(r'^login/$', login_view),
    url(r'^account/loggedin/$', main_view),
    url(r'^roomView/$', room_view),
    url(r'^logout/$', logout_view),
    url(r'^changeState/$', change_port_state),
)
