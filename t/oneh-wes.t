use strict;
use warnings;
use PDL;
use PDL::NiceSlice;
use PDL::Complex;
use Photonic::Geometry::FromEpsilon;
use Photonic::WE::S::Metric;
use Photonic::WE::S::OneH;

use Test::More tests => 4;

sub Cagree {    
    my $a=shift;
    my $b=shift//0;
    return (($a-$b)->Cabs2)->sum<=1e-7;
}

#Check haydock coefficients for simple 1D system
#1D system e=1 or 2
my ($ea, $eb)=(1+2*i, 3+4*i);
my $f=6/11;
my $eps=$ea*(zeroes(11)->xvals<5)+ $eb*(zeroes(11)->xvals>=5)+0*i; 
my $g=Photonic::Geometry::FromEpsilon
    ->new(epsilon=>$eps, Direction0=>pdl([1])); 
my $m=Photonic::WE::S::Metric->new(
    geometry=>$g, epsilon=>pdl(1), wavenumber=>pdl(2), wavevector=>pdl([1])
    );
my $o=Photonic::WE::S::OneH->new(metric=>$m, polarization=>pdl([1])->r2C);
$o->iterate;
ok(Cagree(pdl($o->current_a), (1-$ea)*(1-$f)+(1-$eb)*$f), "1D a_0");
ok(Cagree(pdl($o->next_b2), ($eb-$ea)**2*$f*(1-$f)), "1D b_1^2");
$o->iterate;
ok(Cagree(pdl($o->current_a), ((1-$ea)*$f+(1-$eb)*(1-$f))), "1D a_1");
ok(Cagree(pdl($o->next_b2), 0), "1D b_2^2");