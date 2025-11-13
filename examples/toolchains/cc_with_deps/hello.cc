#include <iostream>
#include <boost/filesystem/operations.hpp>
#include <boost/version.hpp>
#include <zlib.h>

int main()
{
	std::cout << "Hello world!\n";
	std::cout << "zlib version: " << ZLIB_VERSION << std::endl;
	std::cout << "Boost version: " << BOOST_LIB_VERSION << std::endl;

	return 0;
}
