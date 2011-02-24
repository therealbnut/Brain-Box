#include "BBException.h"
#include "BBContext.h"

BB::Exception::Exception(const std::string& _message, int _line, const std::string& _name)
  :	std::exception(), message(_message), line(_line), name(_name)
{	
}

BB::Exception::Exception(const std::string& _message)
  :	std::exception(), message(_message), line(0), name("Internal Error")
{
}

BB::Exception::Exception(const BB::Context& context, JSValueRef value)
  :	std::exception(),
	message(context.safeGetString(context.safeGetProperty(value, "message"))),
	name(context.safeGetString(context.safeGetProperty(value, "name"))),
	line(context.safeGetNumber(context.safeGetProperty(value, "line")))
{
}

BB::Exception::~Exception() throw()
{
}

char BB_Exception_Buffer[1024];
const char* BB::Exception::what() const throw()
{
	sprintf(BB_Exception_Buffer,
			"%s: %s, at line %d\n",
			this->name.c_str(),
			this->message.c_str(),
			this->line);

	return BB_Exception_Buffer;
}
