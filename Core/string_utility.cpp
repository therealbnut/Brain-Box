/*
 *  string_utility.cpp
 *  Core
 *
 *  Created by Andrew Bennett on 26/02/11.
 *  Copyright 2011 __MyCompanyName__. All rights reserved.
 *
 */

#include "string_utility.h"

std::string string_utility::ltrim(const std::string& untrimmed)
{
	std::string s = untrimmed;
	s.erase(s.begin(), std::find_if(s.begin(), s.end(), std::not1(std::ptr_fun<int, int>(std::isspace))));
	return s;
}
std::string string_utility::rtrim(const std::string& untrimmed)
{
	std::string s = untrimmed;
	s.erase(std::find_if(s.rbegin(), s.rend(), std::not1(std::ptr_fun<int, int>(std::isspace))).base(), s.end());
	return s;
}
std::string string_utility::trim(const std::string& untrimmed)
{
	std::string s = untrimmed;
	return ltrim(rtrim(s));
}
