# Defines the package and resources required for the www role
class roles::www{
  include profiles::nginx
  include profiles::http_resources
}
