#
# Copyright (C) 2009  RimuHosting Ltd
# Author: Ivan Meredith <ivan@ivan.net.nz>
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

require "deltacloud/base_driver"
require "deltacloud/drivers/rimu/rimu_hosting_client"

module Deltacloud
  module Drivers
    module Rimu

class RimuHostingDriver < Deltacloud::BaseDriver
  def images(credentails, opts=nil)
    rh = RimuHostingClient.new(credentails)
    images = rh.list_images.map do | image |
      Image.new({
              :id => image["distro_code"].gsub(/\./,"-"),
              :name => image["distro_code"],
              :description => image["distro_description"],
              :owner_id => "root",
              :architecture => "x86"
      })
    end
    images.sort_by{|e| [e.description]}
    images = filter_on( images, :id, opts)
    images
  end

  def flavors(credentials, opts=nil)
    rh = RimuHostingClient.new(credentials)
    flavors = rh.list_plans.map do | flavor |
      Flavor.new({
              :id => flavor["pricing_plan_code"],
              :memory => flavor["minimum_memory_mb"].to_f/1024,
              :storage => flavor["minimum_disk_gb"].to_i,
              :architecture => "x86"
      })
    end
    flavors = filter_on( flavors, :id, opts)
    flavors
  end

  def realms(credentials, opts=nil)
    [Realm.new( {
            :id=>"rimu",
            :name=>"RimuHosting",
            :state=> "AVAILABLE"
    } )]
  end

  def instances(credentials, opts=nil)
     rh = RimuHostingClient.new(credentials)
    instances = rh.list_nodes.map do | inst |
      convert_srv_to_instance(inst)
    end
    instances = filter_on( instances, :id, opts)
    instances
  end

  def reboot_instance(credentials, id)
     rh = RimuHostingClient.new(credentials)
    rh.set_server_state(id, :RESTARTING)
  end

  def start_instance(credentials, id)
    rh = RimuHostingClient.new(credentials)
    rh.set_server_state(id, :STARTED)
  end

  def stop_instance(credentials, id)
    destroy_instance(credentials, id)
  end

  def destroy_instance(credentials, id)
     rh = RimuHostingClient.new(credentials)
    rh.delete_server(id)
  end

  def create_instance(credentials, image_id, opts)
     rh = RimuHostingClient.new(credentials)
    # really need to raise an exception here.
    flavor_id = 1
    if (opts[:flavor_id]) then
      flavor_id = opts[:flavor_id]
    end
    # really bad, but at least its a fqdn
    name = Time.now.to_s + '.com'
    if (opts[:name]) then
      name = opts[:name]
    end
    convert_srv_to_instance(rh.create_server(image_id, flavor_id, name))

  end

  def convert_srv_to_instance( inst )
    Instance.new({
            :id => inst["order_oid"].to_s,
            :name => inst["domain_name"],
            :image_id => "lenny",
            :state => "RUNNING",
            :name => inst["domain_name"],
            :realm_id => "RH",
            :owner_id => "root",
            :flavor_id => "none",
            :actions => instance_actions_for("RUNNING")
    })
  end

  define_instance_states do
    start.to( :pending )          .automatically

    pending.to( :running )        .automatically

    running.to( :running )        .on(:reboot)
    running.to( :shutting_down )  .on(:stop)

    shutting_down.to( :stopped )  .automatically

    stopped.to( :finish )         .automatically
  end


end

    end
  end
end
