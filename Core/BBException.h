#ifndef _BB_EXCEPTION_H_
#define _BB_EXCEPTION_H_

#include <stdexcept>
#include <JavaScriptCore/JavaScriptCore.h>

namespace BB
{
	class Context;
	
	class Exception : public std::exception
	{
	public:
		explicit Exception(const std::string& message, int line, const std::string& name);
		explicit Exception(const std::string& message);
		explicit Exception(const BB::Context& context, JSValueRef value);
		virtual ~Exception() throw();
		
		virtual const char*  what() const throw();

		const std::string message, name; const int line;
	};
}

#endif
