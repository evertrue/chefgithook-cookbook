name             'chefgithook'
maintainer       'EverTrue, Inc.'
maintainer_email 'eric.herot@evertrue.com'
license          'Apache 2.0'
description      'Installs/Configures chefgithook'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '2.1.1'

depends 'runit', '~> 1.5'
depends 's3_file', '~> 2.5'
