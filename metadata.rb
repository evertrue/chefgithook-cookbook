name             'chefgithook'
maintainer       'EverTrue, Inc.'
maintainer_email 'eric.herot@evertrue.com'
license          'All rights reserved'
description      'Installs/Configures chefgithook'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '1.0.5'

depends 'runit', '~> 1.5.8'
depends 's3_file', '~> 2.3.0'
