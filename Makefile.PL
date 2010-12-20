use inc::Module::Install;

name 'Weather-WWO';

all_from 'lib/Weather/WWO.pm';

abstract 'Simple API to World Weather Online';
author 'Mateu X Hunter';
license 'perl';
version_from 'lib/Weather/WWO.pm';

requires(
    'Data::Dumper::Concise' => 0,
    'JSON'                  => 0,
    'LWP::Simple'           => 0,
    'Moose'                 => '1.21',
    'namespace::autoclean'  => 0,
    'Regexp::Common'        => 0,
);

auto_install;
WriteAll;
