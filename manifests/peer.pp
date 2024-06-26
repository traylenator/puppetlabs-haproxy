# @summary This type will set up a peer entry inside the peers configuration block in haproxy.cfg on the load balancer. 
#
# @note
#   Currently, it has the ability to
#   specify the instance name, ip address, ports and server_names.
#
#
# @param peers_name
#   Specifies the peer in which this load balancer needs to be added.
#
# @param server_names
#   Sets the name of the peer server in the peers configuration block.
#   Defaults to the hostname. Can be an array. If this parameter is
#   specified as an array, it must be the same length as the
#   ipaddresses parameter's array. A peer is created for each pair
#   of server\_names and ipaddresses in the array.
#
# @param ipaddresses
#   Specifies the IP address used to contact the peer member server.
#   Can be an array. If this parameter is specified as an array it
#   must be the same length as the server\_names parameter's array.
#   A peer is created for each pair of address and server_name.
#
# @param port
#   Sets the port on which the peer is going to share the state.
#
# @param config_file
#   Optional. Path of the config file where this entry will be added.
#   Assumes that the parent directory exists.
#   Default: $haproxy::params::config_file
# 
# @param instance
#  The instance name of the mailer entry. Default value: 'haproxy'.
#
# @note
#   Automatic discovery of peer nodes may be implemented by exporting the peer resource
#   for all HAProxy balancer servers that are configured in the same HA block and
#   then collecting them on all load balancers.
#
define haproxy::peer (
  String                          $peers_name,
  Variant[String, Stdlib::Port]   $port,
  Variant[String[1], Array]       $server_names = $facts['networking']['hostname'],
  Variant[String, Array]          $ipaddresses  = $facts['networking']['ip'],
  String                          $instance     = 'haproxy',
  Optional[Stdlib::Absolutepath]  $config_file  = undef,

) {
  include haproxy::params

  if $instance == 'haproxy' {
    $instance_name = 'haproxy'
    $_config_file = pick($config_file, $haproxy::config_file)
  } else {
    $instance_name = "haproxy-${instance}"
    $_config_file = pick($config_file, inline_template($haproxy::params::config_file_tmpl))
  }

  $parameters = {
    'ipaddresses'  => $ipaddresses,
    'server_names' => $server_names,
    'port'         => $port,
  }

  # Templates uses $ipaddresses, $server_name, $ports, $option
  concat::fragment { "${instance_name}-peers-${peers_name}-${name}":
    order   => "30-peers-01-${peers_name}-${name}",
    target  => $_config_file,
    content => epp('haproxy/haproxy_peer.epp', $parameters),
  }
}
