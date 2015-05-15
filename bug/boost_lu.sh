#! /bin/bash -e
# $Id$
# -----------------------------------------------------------------------------
# CppAD: C++ Algorithmic Differentiation: Copyright (C) 2003-15 Bradley M. Bell
#
# CppAD is distributed under multiple licenses. This distribution is under
# the terms of the
#                     Eclipse Public License Version 1.0.
#
# A copy of this license is included in the COPYING file of this distribution.
# Please visit http://www.coin-or.org/CppAD/ for information on other licenses.
# -----------------------------------------------------------------------------
cat << EOF
This test results in a very long error message with boost-1.55.0 and
gcc-4.9.2. Here is the gist of the message:
	/usr/include/boost/numeric/ublas/detail/matrix_assign.hpp:33:35:
	error: no match for ‘operator<’
	... snip ...
		return norm_inf (e1 - e2) < epsilon *
                                   ^
EOF
cat << EOF > bug.$$
#include <cppad/cppad.hpp>

# define NUMERIC_LIMITS_FUN(name)                  \
	static CppAD::AD<double> name(void)            \
	{	return static_cast< CppAD::AD<double> > (  \
			std::numeric_limits<double>::name()    \
		);                                         \
	}

# define NUMERIC_LIMITS_BOOL(name)                 \
	static const bool name =                       \
		std::numeric_limits<double>::name;

# define NUMERIC_LIMITS_INT(name)                 \
	static const int name =                       \
		std::numeric_limits<double>::name;



namespace std {
	/// Specialization of numeric_limits< CppAD::AD<double> >
	template <>
	class numeric_limits< CppAD::AD<double> > {
	public:
		// has_denorm
		static const float_denorm_style has_denorm =
			std::numeric_limits<double>::has_denorm;
		// round_style
		static const float_round_style round_style =
			std::numeric_limits<double>::round_style;

		// bool
		NUMERIC_LIMITS_BOOL(is_specialized);
		NUMERIC_LIMITS_BOOL(is_signed);
		NUMERIC_LIMITS_BOOL(is_integer);
		NUMERIC_LIMITS_BOOL(is_exact);
		NUMERIC_LIMITS_BOOL(has_infinity);
		NUMERIC_LIMITS_BOOL(has_quiet_NaN);
		NUMERIC_LIMITS_BOOL(has_signaling_NaN);
		NUMERIC_LIMITS_BOOL(has_denorm_loss);
		NUMERIC_LIMITS_BOOL(is_iec559);
		NUMERIC_LIMITS_BOOL(is_bounded);
		NUMERIC_LIMITS_BOOL(is_modulo);
		NUMERIC_LIMITS_BOOL(traps);
		NUMERIC_LIMITS_BOOL(tinyness_before);

		// int
		NUMERIC_LIMITS_INT(digits);
		NUMERIC_LIMITS_INT(digits10);
		NUMERIC_LIMITS_INT(radix);
		NUMERIC_LIMITS_INT(min_exponent);
		NUMERIC_LIMITS_INT(min_exponent10);
		NUMERIC_LIMITS_INT(max_exponent);
		NUMERIC_LIMITS_INT(max_exponent10);

		/// functions
		NUMERIC_LIMITS_FUN( epsilon)
		NUMERIC_LIMITS_FUN( min    )
		NUMERIC_LIMITS_FUN( max    )
	};
}

#include <boost/numeric/ublas/lu.hpp>
int main() {
    typedef CppAD::AD<double> T;
    boost::numeric::ublas::matrix<T> a(5,5);
    boost::numeric::ublas::permutation_matrix<std::size_t> pert(5);
    // lu decomposition
    const std::size_t s = lu_factorize(a, pert);

    return 0;
}
EOF
# -----------------------------------------------------------------------------
if [ ! -e build ]
then
	mkdir build
fi
cd build
echo "$0"
name=`echo $0 | sed -e 's|.*/||' -e 's|\..*||'`
mv ../bug.$$ $name.cpp
echo "g++ -I../.. --std=c++11 -g $name.cpp -o $name >& $name.log"
if ! g++ -I../.. --std=c++11 -g $name.cpp -o $name >& $name.log
then
	cat << EOF > $name.sed
s|\\[|&\\n|g
s|\\]|&\\n|g
s|[‘{}]|&\\n|g
s|[a-zA-Z0-9_]* *=|\\n&|g
#
s|boost::numeric::ublas::||g
s|/usr/include/boost/numeric/ublas/||g
#
s|CppAD::AD<double> *|AD|g
s|<matrix<AD>, basic_unit_lower<> >|<matrix_AD_ulower>|g
s|<matrix<AD>, basic_upper<> >|<matrix_AD_upper>|g
s|scalar_minus<AD, AD>|scalar_minus_AD|g
s|triangular_adaptor<\\([^<>]*\\)>|triangular_\\1|g
s|triangular_matrix_AD_ulower|AD_ulower|g
s|triangular_matrix_AD_upper|AD_upper|g
s|matrix_matrix_prod<AD_ulower, AD_upper, AD> *|AD_prod_ulower_upper|g
s|<AD_ulower, AD_upper, AD_prod_ulower_upper> *|<AD_prod_ulower_upper>|g
s|matrix_matrix_binary<AD_prod_ulower_upper>|AD_prod_ulower_upper|g
EOF
	echo "sed -f $name.sed $name.log > ../$name.log"
	sed -f $name.sed $name.log > ../$name.log
	echo "$name.sh: Compliation Error: see $name.log"
	exit 1
fi
#
echo "./$name"
if ! ./$name
then
	echo
	echo "$name.sh: Execution Error"
	exit 1
fi
echo
echo "$name.sh: OK"
exit 0
