/*
 *  string_utility.h
 *  Core
 *
 *  Created by Andrew Bennett on 26/02/11.
 *  Copyright 2011 __MyCompanyName__. All rights reserved.
 *
 */

#include <string>

namespace string_utility
{
	std::string ltrim(const std::string& untrimmed);
	std::string rtrim(const std::string& untrimmed);
	std::string trim(const std::string& untrimmed);	
}
