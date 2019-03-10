use strict;
use warnings;
use PDL;
use PDL::NiceSlice;
use PDL::Complex;
use Photonic::Geometry::FromEpsilon;
use Photonic::WE::S::Metric;
use Photonic::WE::S::AllH;
use Photonic::WE::S::EpsilonTensor;

use Machine::Epsilon;
use List::Util;

use Test::More tests => 10;

sub agree {    
    my $a=shift;
    my $b=shift//0;
    return (($a-$b)*($a-$b))->sum<=1e-4;
}

sub Cagree {    
    my $a=shift;
    my $b=shift//0;
    return (($a-$b)->Cabs2)->sum<=1e-4;
}

#Check epsilontensor for simple 1D system
#Non-retarded limit
my ($ea, $eb)=(1+2*i,3+4*i);
my $f=6/11;
my $eps=$ea*(zeroes(11,1)->xvals<5)+ $eb*(zeroes(11)->xvals>=5)+0*i; 
my $g=Photonic::Geometry::FromEpsilon
    ->new(epsilon=>$eps); 
my $m=Photonic::WE::S::Metric->new(
    geometry=>$g, epsilon=>pdl(1), wavenumber=>pdl(2e-5),
    wavevector=>pdl([1,0])*2.1e-5);  
my $et=Photonic::WE::S::EpsilonTensor->new(nh=>10, metric=>$m);
my $etv=$et->epsilonTensor;
ok(Cagree($etv->(:,(0),(0)), 1/((1-$f)/$ea+$f/$eb)),
			     "Long. perp. non retarded");
ok(Cagree($etv->(:,(1),(1)), (1-$f)*$ea+$f*$eb),
			     "Trans. parallel non retarded");
ok(Cagree($etv->(:,(0),(1)), 0), "xy k perp");
ok(Cagree($etv->(:,(1),(0)), 0), "yx k perp");

$m=Photonic::WE::S::Metric->new(
    geometry=>$g, epsilon=>pdl(1), wavenumber=>pdl(2e-5),
    wavevector=>pdl([0,1])*2.1e-5);  
$et=Photonic::WE::S::EpsilonTensor->new(nh=>10, metric=>$m);
$etv=$et->epsilonTensor;
ok(Cagree($etv->(:,(0),(0)), 1/((1-$f)/$ea+$f/$eb)),
			     "Trans. perp. non retarded");
ok(Cagree($etv->(:,(1),(1)), (1-$f)*$ea+$f*$eb),
			     "Long. parallel non retarded");
ok(Cagree($etv->(:,(0),(1)), 0), "xy k parallel");
ok(Cagree($etv->(:,(1),(0)), 0), "yx k parallel");

#Compare to epsilon from transfer matrix.
#Construct normal incidence transfer matrix
($ea, $eb)=(r2C(1),r2C(2));
$eps=$ea*(zeroes(11,1)->xvals<5)+ $eb*(zeroes(11)->xvals>=5)+0*i; 
$g=Photonic::Geometry::FromEpsilon
    ->new(epsilon=>$eps, L=>pdl(1,1)); 
my ($na, $nb)=map {sqrt($_)} ($ea, $eb);
my $q=1.2;
my ($ka,$kb)=map {$q*$_} ((1-$f)*$na, $f*$nb); #Multiply by length also
my $ma=pdl([cos($ka), -sin($ka)/$na],[$na*sin($ka), cos($ka)])->complex;
my $mb=pdl([cos($kb), -sin($kb)/$nb],[$nb*sin($kb), cos($kb)])->complex;
my $mt=($ma->(:,:,*1,:)*$mb->mv(2,1)->(:,:,:,*1))->sumover;
#Solve exact dispersion relation
my $cospd=($mt->(:,(0),(0))+$mt->(:,(1),(1)))/2;
my $sinpd=sqrt(1-$cospd**2);
my $pd=log($cospd+i*$sinpd)/i;
warn "Bloch vector not real, $pd" unless $pd->im->abs < 1e-7;
$pd=$pd->re;
#epsilon from transfer matrix
my $epstm=($pd/$q)**2;
#epsilon from photonic
$m=Photonic::WE::S::Metric->new(
    geometry=>$g, epsilon=>pdl(1), wavenumber=>pdl($q),
    wavevector=>pdl([$pd,0]));  
$et=Photonic::WE::S::EpsilonTensor->new(nh=>1000, metric=>$m,
						  reorthogonalize=>1);
$etv=$et->epsilonTensor->(:,(1),(1));
ok(Cagree($epstm, $etv), "Epsilon agrees with transfer matrix");

#Compare to epsilon from transfer matrix with complex metric.
#Construct normal incidence transfer matrix
($ea, $eb)=(r2C(1+0*i),r2C(2+.4*i));
$eps=$ea*(zeroes(11,1)->xvals<5)+ $eb*(zeroes(11)->xvals>=5)+0*i; 
$g=Photonic::Geometry::FromEpsilon
    ->new(epsilon=>$eps, L=>pdl(1,1)); 
($na, $nb)=map {sqrt($_)} ($ea, $eb);
$q=1.2;
($ka,$kb)=map {$q*$_} ((1-$f)*$na, $f*$nb); #Multiply by length also
$ma=pdl([cos($ka), -sin($ka)/$na],[$na*sin($ka), cos($ka)])->complex;
$mb=pdl([cos($kb), -sin($kb)/$nb],[$nb*sin($kb), cos($kb)])->complex;
$mt=($ma->(:,:,*1,:)*$mb->mv(2,1)->(:,:,:,*1))->sumover;
#Solve exact dispersion relation
$cospd=($mt->(:,(0),(0))+$mt->(:,(1),(1)))/2;
$sinpd=sqrt(1-$cospd**2);
$pd=log($cospd+i*$sinpd)/i;
#epsilon from transfer matrix
my $epstm=($pd/$q)**2;
#epsilon from photonic
$m=Photonic::WE::S::Metric->new(
    geometry=>$g, epsilon=>pdl(1), wavenumber=>pdl($q),
    wavevector=>pdl([$pd,0])->complex);  
$et=Photonic::WE::S::EpsilonTensor->new(nh=>1000, metric=>$m,
						  reorthogonalize=>1);
$etv=$et->epsilonTensor->(:,(1),(1));
ok(Cagree($epstm, $etv), "Epsilon agrees with transfer matrix. Complex case.");
diag($epstm);
diag($etv);