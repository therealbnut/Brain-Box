#ifndef _BB_CONTEXT_H_
#define _BB_CONTEXT_H_

#include <string>
#include <JavaScriptCore/JavaScriptCore.h>

#include "BBException.h"

namespace BB
{
	class Context
	{
	public:
		Context();
		~Context();

		inline JSContextRef context() const {return this->m_context;}
		JSClassRef patchClass();

		JSValueRef evaluateScript(const std::string& string) const throw(BB::Exception);
		JSValueRef evaluateScriptFromFile(const std::string& filename) const throw(BB::Exception);

		JSValueRef createNumber(double number) const;
		JSValueRef createString(const std::string& string) const;
		
		double getNumber(JSValueRef value) const throw(BB::Exception);
		std::string getString(JSValueRef value) const throw(BB::Exception);
		
		void throwException(JSValueRef except) const throw(BB::Exception);
		void throwException(const std::string& description) const throw(BB::Exception);
		
		JSObjectRef createFunction(const std::string& source) throw(BB::Exception);

		static BB::Context* FromJS(JSContextRef ctx);

	protected:
		friend class BB::Exception;
		
		std::string safeGetString(JSValueRef value) const;
		double      safeGetNumber(JSValueRef value) const;
		JSValueRef  safeGetProperty(JSValueRef value, const std::string& name) const;
		
	protected:
		static void Initialize(JSContextRef ctx, JSObjectRef object);
		static void Finalize(JSObjectRef object);
		static JSValueRef Print(JSContextRef ctx,
								JSObjectRef function,
								JSObjectRef thisObject,
								size_t argumentCount,
								const JSValueRef arguments[],
								JSValueRef* exception);		

		static const JSClassDefinition Definition;
		static const JSStaticValue     StaticValues[];
		static const JSStaticFunction  StaticFunctions[];		

	private:
		JSClassRef m_class_context;
		JSClassRef m_class_patch;
		JSGlobalContextRef m_context;
	};
}

#endif
