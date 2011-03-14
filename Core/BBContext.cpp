#include "BBContext.h"

#include "BBPatchCollection.h"
#include "BBPatch.h"
#include "BBIndexSet.h"

#include "BBCore.h"

#include <stdexcept>
#include <iostream>
#include <fstream>
#include <vector>

BB::Context::Context()
 :	m_class_context(NULL),
	m_class_patch(NULL),
	m_class_patch_collection(NULL),
	m_class_index_set(NULL)
{
	JSObjectRef object;
	
	this->m_class_context = JSClassCreate(&BB::Context::Definition);
	this->m_context       = JSGlobalContextCreate(this->m_class_context);

	object = JSContextGetGlobalObject(this->m_context);
	JSObjectSetPrivate(object, this);

	this->patchClass();
	this->patchCollectionClass();
	this->indexSetClass();
}

BB::Context::~Context()
{
	if (this->m_class_context != NULL)
		JSClassRelease(this->m_class_context);
	if (this->m_class_patch != NULL)
		JSClassRelease(this->m_class_patch);
	if (this->m_class_patch_collection != NULL)
		JSClassRelease(this->m_class_patch_collection);
	if (this->m_class_index_set != NULL)
		JSClassRelease(this->m_class_index_set);

	JSGlobalContextRelease(this->m_context);
}

JSValueRef BB::Context::createNumber(double number) const
{
	return JSValueMakeNumber(this->m_context, number);
}
JSValueRef BB::Context::createString(const std::string& string) const
{
	JSStringRef js_string;
	js_string = JSStringCreateWithUTF8CString(string.c_str());
	return JSValueMakeString(this->m_context, js_string);
}

double BB::Context::getNumber(JSValueRef value) const throw(BB::Exception)
{
	JSValueRef except;
	double result;

	except = NULL;
	result = JSValueToNumber(this->m_context, value, &except);
	if (except != NULL)
		this->throwException("Unable to get number from value!");

	return result;
}

std::string BB::Context::getString(JSValueRef value) const throw(BB::Exception)
{
	std::vector<char> buffer;
	JSStringRef js_string;
	JSValueRef except;

	except = NULL;
	js_string = JSValueToStringCopy(this->m_context, value, &except);
	if (except != NULL)
		this->throwException("Unable to get string from value!");

	buffer.resize(JSStringGetMaximumUTF8CStringSize(js_string));
	JSStringGetUTF8CString(js_string, &buffer[0], buffer.size());

	JSStringRelease(js_string);
	
	return &buffer[0];
}

#pragma mark -
#pragma mark JS Class Definitions
#pragma mark -

JSClassRef BB::Context::patchClass()
{
	if (this->m_class_patch == NULL)
	{
		JSObjectRef constructor, global;
		JSStringRef constructor_string;

		this->m_class_patch = JSClassCreate(&BB::Patch::Definition);
		
		constructor_string = JSStringCreateWithUTF8CString(BB::Patch::Definition.className);
		constructor = JSObjectMakeConstructor(this->m_context, NULL,
											  BB::Patch::Constructor);
		global  = JSContextGetGlobalObject(this->m_context);
		JSObjectSetProperty(this->m_context, global,
							constructor_string, constructor,
							kJSPropertyAttributeReadOnly |
							kJSPropertyAttributeDontEnum |
							kJSPropertyAttributeDontDelete,
							NULL);
		JSStringRelease(constructor_string);		
	}
	return this->m_class_patch;
}

JSClassRef BB::Context::patchCollectionClass()
{
	if (this->m_class_patch_collection == NULL)
	{
		JSObjectRef constructor, global;
		JSStringRef constructor_string;
		
		this->m_class_patch_collection = JSClassCreate(&BB::PatchCollection::Definition);
		
		constructor_string = JSStringCreateWithUTF8CString(BB::PatchCollection::Definition.className);
		constructor = JSObjectMakeConstructor(this->m_context, NULL,
											  BB::PatchCollection::Constructor);
		global  = JSContextGetGlobalObject(this->m_context);
		JSObjectSetProperty(this->m_context, global,
							constructor_string, constructor,
							kJSPropertyAttributeReadOnly |
							kJSPropertyAttributeDontEnum |
							kJSPropertyAttributeDontDelete,
							NULL);
		JSStringRelease(constructor_string);		
	}
	return this->m_class_patch_collection;
}

JSClassRef BB::Context::indexSetClass()
{
	if (this->m_class_index_set == NULL)
	{
		JSObjectRef constructor, global;
		JSStringRef constructor_string;
		
		this->m_class_index_set = JSClassCreate(&BB::IndexSet::Definition);
		
		constructor_string = JSStringCreateWithUTF8CString(BB::IndexSet::Definition.className);
		constructor = JSObjectMakeConstructor(this->m_context, NULL,
											  BB::IndexSet::Constructor);
		global  = JSContextGetGlobalObject(this->m_context);
		JSObjectSetProperty(this->m_context, global,
							constructor_string, constructor,
							kJSPropertyAttributeReadOnly |
							kJSPropertyAttributeDontEnum |
							kJSPropertyAttributeDontDelete,
							NULL);
		JSStringRelease(constructor_string);		
	}
	return this->m_class_index_set;
}

#pragma mark -
#pragma mark Evaluate Scripts

JSValueRef BB::Context::evaluateScript(const std::string& string) const throw(BB::Exception)
{
	JSStringRef script;
	JSValueRef except, value;

	except = NULL;
	script = JSStringCreateWithUTF8CString(string.c_str());
	value  = JSEvaluateScript(this->m_context, script, NULL, NULL, 1, &except);
	if (except != NULL)
		this->throwException(except);
	
	JSStringRelease(script);
	
	return value;
}

JSValueRef BB::Context::evaluateScriptFromFile(const std::string& filename) const throw(BB::Exception)
{
//	std::ifstream ifs(filename.c_str());
//	std::string file_content((std::istreambuf_iterator<char>(ifs)), std::istreambuf_iterator<char>());

	std::ifstream file(filename.c_str());
	std::vector<char> buffer;
	JSStringRef script;
	JSObjectRef function;
	JSValueRef except, value;

	if (!file.good())
		return NULL;
	
	file.seekg(0, std::ios_base::end);
	buffer.resize(file.tellg());
	file.seekg(0, std::ios_base::beg);

	file.read(&buffer[0], buffer.size());
	file.close();
	
	buffer.push_back('\0');

	except = NULL;
	script = JSStringCreateWithUTF8CString(&buffer[0]);
	function = JSObjectMakeFunction(this->m_context, NULL, 0, NULL, script,
									NULL, 1, &except);
	JSStringRelease(script);
	if (except != NULL)
		this->throwException(except);
	
	except = NULL;
	value = JSObjectCallAsFunction(this->m_context, function, NULL, 0, NULL, &except);
	if (except != NULL)
		this->throwException(except);

	JSValueProtect(this->m_context, value);
	JSGarbageCollect(this->m_context);
	JSValueUnprotect(this->m_context, value);
	
	return value;
}

#pragma mark -
#pragma mark Exceptions

void BB::Context::throwException(JSValueRef except) const throw(BB::Exception)
{
	throw BB::Exception(*this, except);
}

void BB::Context::throwException(const std::string& description) const throw(BB::Exception)
{
	throw BB::Exception(description);
}

#pragma mark Properties

std::string BB::Context::safeGetString(JSValueRef value) const
{
	std::vector<char> buffer;
	JSStringRef js_string;

	js_string = JSValueToStringCopy(this->m_context, value, NULL);

	buffer.resize(JSStringGetMaximumUTF8CStringSize(js_string));
	JSStringGetUTF8CString(js_string, &buffer[0], buffer.size());

	JSStringRelease(js_string);
	
	return &buffer[0];
}

double BB::Context::safeGetNumber(JSValueRef value) const
{
	double number;
	number = JSValueToNumber(this->m_context, value, NULL);
	return number;
}

JSValueRef BB::Context::safeGetProperty(JSValueRef value, const std::string& name) const
{
	JSObjectRef object;
	JSStringRef string;
	JSValueRef  prop;
	
	object = JSValueToObject(this->m_context, value, NULL);
	string = JSStringCreateWithUTF8CString(name.c_str());
	prop   = JSObjectGetProperty(this->m_context, object, string, NULL);

	JSStringRelease(string);
	
	return prop;
}

#pragma mark Static Functions

BB::Context* BB::Context::FromJS(JSContextRef ctx)
{
	BB::Context* context;
	JSObjectRef  global;
	
	global  = JSContextGetGlobalObject(ctx);
	context = static_cast<BB::Context*>(JSObjectGetPrivate(global));

	return context;
}

void BB::Context::Initialize(JSContextRef ctx, JSObjectRef object)
{
}
void BB::Context::Finalize(JSObjectRef object)
{
//	BB::Context * context;
//	context = static_cast<BB::Context*>(JSObjectGetPrivate(object));
//	JSGarbageCollect(context->m_context);
}

JSObjectRef BB::Context::createFunction(const std::string& source) throw(BB::Exception)
{
	JSStringRef  body;
	JSObjectRef  function;
	JSValueRef   except;

	except   = NULL;
	body     = JSStringCreateWithUTF8CString(source.c_str());
	function = JSObjectMakeFunction(this->m_context, NULL, 0, NULL,
									body, NULL, 1,
									&except);
	if (except != NULL)
		this->throwException(except);

	return function;
}

JSValueRef BB::Context::Print(JSContextRef ctx,
							  JSObjectRef function,
							  JSObjectRef thisObject,
							  size_t argumentCount,
							  const JSValueRef arguments[],
							  JSValueRef* exception)
{
	BB::Context * context;
	JSStringRef string_js;
	std::vector<char> buffer;
	JSValueRef except;

	context = BB::Context::FromJS(ctx);
	if (argumentCount != 1)
		context->throwException("Print takes one argument!");	

	except    = NULL;
	string_js = JSValueToStringCopy(ctx, arguments[0], &except);
	if (except != NULL)
	{
		exception[0] = except;
		return NULL;
	}
	
	buffer.resize(JSStringGetMaximumUTF8CStringSize(string_js));
	JSStringGetUTF8CString(string_js, &buffer[0], buffer.size());

	printf("%s\n", &buffer[0]);
	
	JSStringRelease(string_js);

	return JSValueMakeUndefined(ctx);
}

JSValueRef BB::Context::GarbageCollect(JSContextRef ctx,
									   JSObjectRef function,
									   JSObjectRef thisObject,
									   size_t argumentCount,
									   const JSValueRef arguments[],
									   JSValueRef* exception)
{
	BB::Context * context;

	context = BB::Context::FromJS(ctx);
	if (argumentCount != 0)
		context->throwException("GarbageCollect takes one argument!");	

	JSGarbageCollect(ctx);

	return JSValueMakeUndefined(ctx);
}

#pragma mark Static Properties

const JSStaticValue BB::Context::StaticValues[] =
{
	{NULL, NULL, NULL, 0}
};
const JSStaticFunction BB::Context::StaticFunctions[] =
{
	{"Print",               BB::Context::Print,          kJSPropertyAttributeReadOnly | kJSPropertyAttributeDontEnum | kJSPropertyAttributeDontDelete},
	{"ForceGarbageCollect", BB::Context::GarbageCollect, kJSPropertyAttributeReadOnly | kJSPropertyAttributeDontEnum | kJSPropertyAttributeDontDelete},
};

const JSClassDefinition BB::Context::Definition =
{
    0, kJSClassAttributeNoAutomaticPrototype,
    "Patch", NULL,
    BB::Context::StaticValues,
    BB::Context::StaticFunctions,
    BB::Context::Initialize,
    BB::Context::Finalize,
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
};

#pragma mark -
#pragma mark C Interface
#pragma mark -

#pragma mark Create and Destroy

bb_context bbContextCreate(void)
{
	BB::Context * context;
	
	try
	{
		context = new BB::Context();
	}
	catch (BB::Exception& error)
	{
		std::cerr << error.what() << std::endl;
		return NULL;
	}
	
	return reinterpret_cast<bb_context>(context);
}
void bbContextDestroy(bb_context ctx)
{
	BB::Context * context;
	
	context = reinterpret_cast<BB::Context*>(ctx);
	
	delete context;
}

#pragma mark Evaluate Script

void bbContextEvaluateScript(bb_context ctx, const char * script)
{
	BB::Context * context;
	try
	{
		context = reinterpret_cast<BB::Context*>(ctx);
		context->evaluateScript(script);
	}
	catch (BB::Exception& error)
	{
		std::cerr << error.what() << std::endl;
	}
}

void bbContextEvaluateScriptFromFile(bb_context ctx, const char * filename)
{
	BB::Context * context;
	try
	{
		context = reinterpret_cast<BB::Context*>(ctx);
		context->evaluateScriptFromFile(filename);
	}
	catch (BB::Exception& error)
	{
		std::cerr << error.what() << std::endl;
	}
}
