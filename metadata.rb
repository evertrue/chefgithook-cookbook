name             'chefgithook'
maintainer       'EverTrue, Inc.'
maintainer_email 'eric.herot@evertrue.com'
license          'All rights reserved'
description      'Installs/Configures chefgithook'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '1.0.8'

depends 'runit', '~> 1.5'
depends 's3_file', '~> 2.5'
