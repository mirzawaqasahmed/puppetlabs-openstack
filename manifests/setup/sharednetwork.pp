# A static class to set up a shared network. Should appear on the
# controller node. It sets up the public network, a private network,
# two subnets (one for admin, one for test), and the routers that
# connect the subnets to the public network.
#
# After this class has run, you should have a functional network
# avaiable for your test user to launch and connect machines to.
class openstack::setup::sharednetwork {

  $external_network = hiera('openstack::network::external')
  $start_ip = hiera('openstack::network::external::ippool::start')
  $end_ip   = hiera('openstack::network::external::ippool::end')
  $ip_range = "start=${start_ip},end=${end_ip}"
  $gateway  = hiera('openstack::network::external::gateway')
  $dns      = hiera('openstack::network::external::dns')

  $private_network = hiera('openstack::network::neutron::private')

  neutron_network { 'public':
    tenant_name              => 'services',
    provider_network_type    => 'gre',
    router_external          => true,
    provider_segmentation_id => 3604,
    shared                   => true,
  } ->

  neutron_subnet { $external_network:
    cidr             => $external_network,
    ip_version       => '4',
    gateway_ip       => $gateway,
    enable_dhcp      => false,
    network_name     => 'public',
    tenant_name      => 'services',
    allocation_pools => [$ip_range],
    dns_nameservers  => [$dns],
  }

  neutron_network { 'private':
    tenant_name              => 'services',
    provider_network_type    => 'gre',
    router_external          => false,
    provider_segmentation_id => 4063,
    shared                   => true,
  } ->

  neutron_subnet { $private_network:
    cidr             => $private_network,
    ip_version       => '4',
    enable_dhcp      => true,
    network_name     => 'private',
    tenant_name      => 'services',
    dns_nameservers  => [$dns],
  } 

  neutron_subnet { '10.0.2.0/24':
    cidr             => '10.0.2.0/24',
    ip_version       => '4',
    enable_dhcp      => true,
    network_name     => 'private',
    tenant_name      => 'test',
    dns_nameservers  => [$dns],
  }

  openstack::setup::router { "services:${private_network}": }
  openstack::setup::router { 'test:10.0.2.0/24': }
}
