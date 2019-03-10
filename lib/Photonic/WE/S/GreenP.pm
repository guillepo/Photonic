=head1 NAME

Photonic::WE::S::GreenP

=head1 VERSION

version 0.011

=head1 SYNOPSIS

   use Photonic::WE::S::GreenP;
   my $green=Photonic::WE::S::GreepP(haydock=>$h, nh=>$nh);
   my $greenProjection=$green->evaluate($epsB);

=head1 DESCRIPTION

Calculates the dielectric function for a given fixed
Photonic::WE::S::AllH structure as a function of the dielectric
functions of the components.

=head1 METHODS

=over 4

=item * new(haydock=>$h, nh=>$nh, smallE=>$smallE)

Initializes the structure.

$h is a Photonic::WE::S::AllH structure (required).

$nh is the maximum number of Haydock coefficients to use (required).

$smallE is the criteria of convergence (defaults to 1e-7)

=item * evaluate($epsB)

Returns the macroscopic projected green'S function for a given complex
value of the  dielectric functions of the particle $epsB.

=back

=head1 ACCESORS (read only)

=over 4

=item * haydock

The WE::S::AllH structure

=item * epsA epsB

The dielectric functions of component A and component B used in the
last calculation.

=item * u

The spectral variable used in the last calculation

=item * nh

The maximum number of Haydock coefficients to use.

=item * nhActual

The actual number of Haydock coefficients used in the last calculation

=item * converged

Flags that the last calculation converged before using up all coefficients

=item * smallE

Criteria of convergence. 0 means don't check. From Photonic::Roles::EpsParams. 

=back

=begin Pod::Coverage

=head2 BUILD

=end Pod::Coverage

=cut

package Photonic::WE::S::GreenP;
$Photonic::WE::S::GreenP::VERSION = '0.011';
use namespace::autoclean;
use PDL::Lite;
use PDL::NiceSlice;
use PDL::Complex;
use Photonic::WE::S::AllH;
use Moose;
use Photonic::Types;

has 'nh' =>(is=>'ro', isa=>'Num', required=>1, 
	    documentation=>'Desired no. of Haydock coefficients');
has 'smallH'=>(is=>'ro', isa=>'Num', required=>1, default=>1e-7,
    	    documentation=>'Convergence criterium for Haydock coefficients');
has 'smallE'=>(is=>'ro', isa=>'Num', required=>1, default=>1e-7,
    	    documentation=>'Convergence criterium for use of Haydock coeff.');
has 'haydock' =>(is=>'ro', isa=>'Photonic::WE::S::AllH', required=>1);
has 'nhActual'=>(is=>'ro', isa=>'Num', init_arg=>undef, 
                 writer=>'_nhActual');
has 'converged'=>(is=>'ro', isa=>'Num', init_arg=>undef, writer=>'_converged');
has 'Gpp'=>(is=>'ro', isa=>'PDL::Complex', init_arg=>undef,
	    lazy=>1, builder=>'_build_Gpp',
	      documentation=>'Value of projected Greens function');

sub _build_Gpp {
    my $self=shift;
    $self->haydock->run unless $self->haydock->iteration;
    my $epsR=$self->haydock->epsilonR;
    my $as=$self->haydock->as;
    my $bcs=$self->haydock->bcs;
    # Continued fraction evaluation: Lentz method
    # Numerical Recipes p. 171
    my $tiny=1.e-30;
    my $converged=0;
    #    b0+a1/b1+a2/...
    #	lo debo convertir a
    #       1-a_0-g0g1b1^2/1-a1-g1g2b2^2/...
    #   entonces bn->1-an y an->-g{n-1}gnbn^2 o -bc_n
    my $fn=1-$as->[0];
    $fn=r2C($tiny) if $fn->re==0 and $fn->im==0;
    my $n=1;
    my ($fnm1, $Cnm1, $Dnm1)=($fn, $fn, r2C(0)); #previous coeffs.
    my ($Cn, $Dn); #current coeffs.
    my $Deltan;
    while($n<$self->nh && $n<$self->haydock->iteration){
	$Dn=1-$as->[$n]-$bcs->[$n]*$Dnm1;
	$Dn=r2C($tiny) if $Dn->re==0 and $Dn->im==0;
	$Cn=1-$as->[$n]-$bcs->[$n]/$Cnm1;
	$Cn=r2C($tiny) if $Cn->re==0 and $Cn->im==0;
	$Dn=1/$Dn;
	$Deltan=$Cn*$Dn;
	$fn=$fnm1*$Deltan;
	last if $converged=$Deltan->approx(1, $self->smallE)->all;
	$fnm1=$fn;
	$Dnm1=$Dn;
	$Cnm1=$Cn;
	$n++;
    }
    #If there are less available coefficients than $self->nh and all
    #of them were used, there is no remaining work to do, so, converged 
    $converged=1 if $self->haydock->iteration < $self->nh;
    $self->_converged($converged);
    $self->_nhActual($n);
    my $g0b02=$self->haydock->gs->[0]*$self->haydock->b2s->[0];
    return $g0b02/($epsR*$fn);
}


__PACKAGE__->meta->make_immutable;
    
1;