# Instruct puppet to use the hiera roles classes for node configuration
node default {
  hiera_include('roles')
}
