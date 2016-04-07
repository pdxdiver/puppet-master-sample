# Defines file, directory and content resources
class profiles::http_resources{
  $http = hiera_hash('http')

  file { $http[www_home_dir]:
    ensure => directory,
    recurse => true,
  }
  file { sprintf("%s%s", $http[www_home_dir], $http[index_file]):
    ensure => present,
    source => $http[home_page_src],
  }
}
