#!perl

use strict;
use warnings;
use lib './t';
use Test::More;
use AssertHelper;
use FIDO::Raw;

my $pk = FIDO::Raw::PublicKey::ES256->new ($es256_pk);
isa_ok $pk, 'FIDO::Raw::PublicKey::ES256';

my $a = FIDO::Raw::Assert->new;
$a->clientdata_hash ($cdh);
$a->rp ("localhost");
$a->count (1);
ok (!eval {$a->authdata (0, '0' x length ($authdata))});
$a->up (FIDO::Raw->OPT_FALSE);
$a->uv (FIDO::Raw->OPT_FALSE);
$a->sig (0, $sig);

is $a->verify (0, FIDO::Raw->COSE_ES256, $pk), FIDO::Raw->ERR_INVALID_ARGUMENT;

done_testing;

