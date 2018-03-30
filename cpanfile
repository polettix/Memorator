requires 'perl', '5.010';
requires 'Minion', '8.0';
requires 'Log::Any', '1.700';
requires 'Try::Tiny', '0.30';

on test => sub {
   requires 'Test::More', '0.88';
   requires 'Path::Tiny', '0.096';
};

on develop => sub {
   requires 'Path::Tiny',        '0.096';
   requires 'Template::Perlish', '1.52';
};
