from django.conf.urls import patterns, include, url

from django.contrib import admin
admin.autodiscover()

from frontend import views

urlpatterns = patterns('',
    # Examples:
    # url(r'^$', 'paradise.views.home', name='home'),
    # url(r'^blog/', include('blog.urls')),

    url(r'^admin/', include(admin.site.urls)),

    url(r'^$', views.index, name='index'),
)
