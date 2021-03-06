#
# Copyright (C) 2009  Red Hat, Inc.
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

class InstancesController < ApplicationController

  include DriverHelper
  include ConversionHelper

  around_filter :catch_auth

  def states
    @states = driver.instance_states()
    respond_to do |format|
      format.html
      format.json
      format.xml
    end
  end

  def index
    build_filter( :id )
    @instances = driver.instances( credentials, @filter )
    @id = params[:id]

    respond_to do |format|
      format.html
      format.json
      format.xml {
        render :xml=>convert_to_xml( :instance, @instances )
      }
    end
  end

  def show
    @instance = driver.instance( credentials, :id=>params[:id] )

    respond_to do |format|
      format.html {
        render :text=>'resource not found', :status=>404 and return unless @instance
      }
      format.json
      format.xml {
        render :nothing=>true, :status=>404 and return unless @instance
        render :xml=>convert_to_xml( :instance, @instance )
      }
    end
  end

  def new
    @instance = Instance.new( {
                  :id=>params[:id],
                  :image_id=>params[:image_id],
                } )
    @image   = driver.image( credentials, :id => params[:image_id] )
    @flavors = driver.flavors( credentials, { :architecture=>@image.architecture } )
    @realms = driver.realms(credentials)
  end

  def create
    @image   = driver.image( credentials, :id=>params[:image_id] )
    respond_to do |format|
      format.html {
        instance = driver.create_instance( credentials, @image.id, params )
        redirect_to instance_url( instance.id )
      }
      format.xml {
        instance = driver.create_instance( credentials, @image.id, params )
        render :xml=>convert_to_xml( :instance, instance), :status=>:created, :location=>instance_url( instance.id )
      }
    end
  end

  ##

  def start
    driver.start_instance(credentials, params[:id])
    redirect_to :action=>:show
  end

  def stop
    driver.stop_instance(credentials, params[:id])
    redirect_to :action=>:show
  end

  def destroy
    driver.destroy_instance( credentials, params[:id] )
    redirect_to :action=>:show
  end

  def reboot
    driver.reboot_instance( credentials, params[:id] )
    redirect_to :action=>:show
  end

end
