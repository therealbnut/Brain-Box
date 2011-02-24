#include "BBPatch.h"

#include "BBContext.h"
#include "BBCore.h"

#include <vector>
#include <iostream>

#pragma mark Static Public Methods

const BB::Patch::name_source_pair   BB::Patch::NameSourcePairEnd   = {"",""};
const BB::Patch::name_function_pair BB::Patch::NameFunctionPairEnd = {"",NULL};
const BB::Patch::name_value_pair    BB::Patch::NameValuePairEnd    = {"",NULL};

BB::Patch* BB::Patch::CreateFromSource(BB::Context& context,
									   const name_value_pair  input_defaults[],
									   const name_source_pair output_sources[],
									   const std::string& update_source)
{
	std::vector<name_function_pair> outputs;
	const name_source_pair * source;
	JSObjectRef update_function;

	update_function = NULL;
	if (output_sources != NULL)
	{
		for (source = &output_sources[0]; !source->name.empty(); ++source)
		{
			outputs.push_back((name_function_pair){
				source->name,
				context.createFunction(source->source.c_str())
			});
		}
	}
	outputs.push_back(BB::Patch::NameFunctionPairEnd);

	update_function = context.createFunction(update_source);
	return new BB::Patch(context, 
						 input_defaults,
						 &outputs[0],
						 update_function);
}

#pragma mark Public Methods

JSValueRef BB::Patch::getInput(const std::string& name) const throw(BB::Exception)
{
	std::map<std::string, std::pair<BB::Patch*, std::string> >::const_iterator connection;
	std::pair<BB::Patch*, std::string> link;
	JSValueRef value;
	JSValueRef except;
	
	connection = this->m_input_connections.find(name);
	if (connection == this->m_input_connections.end())
	{
		std::map<std::string, JSValueRef>::const_iterator inputs;
		JSStringRef string_js;
		std::string excep_str;

		inputs = this->m_inputs.find(name);
		if (inputs != this->m_inputs.end())
			return inputs->second;

		excep_str = "Patch does not have an input: " + name;
		string_js = JSStringCreateWithUTF8CString(excep_str.c_str());
		except    = JSValueMakeString(this->m_context.context(), string_js);

		this->m_context.throwException(except);
	}
	link = connection->second;

	value = link.first->getOutput(link.second);

	return value;
}

JSValueRef BB::Patch::getOutput(const std::string& name) const throw(BB::Exception)
{
	std::map<std::string,JSObjectRef>::const_iterator function;
	JSValueRef value;
	JSValueRef except;
	
	function = this->m_outputs.find(name);
	if (function == this->m_outputs.end())
	{
		JSStringRef string_js;
		std::string excep_str;

		excep_str = "Patch does not have an output: " + name;
		string_js = JSStringCreateWithUTF8CString(excep_str.c_str());
		except    = JSValueMakeString(this->m_context.context(), string_js);

		this->m_context.throwException(except);
	}
	//JSValueRef JSObjectCallAsFunction(JSContextRef ctx,
	//					JSObjectRef object,
	//					JSObjectRef thisObject, size_t argumentCount, const JSValueRef arguments[],
	//					JSValueRef* exception);
	except = NULL;
	value	= JSObjectCallAsFunction(this->m_context.context(),
									 function->second, this->m_patch_object,
									 0, NULL,
									 &except);
	if (except != NULL)
		this->m_context.throwException(except);

	return value;
}

JSValueRef BB::Patch::update() const
{
	JSValueRef except, ret;
	std::vector<JSValueRef> call_arguments;

	if (this->m_update_function != NULL)
	{
		except  = NULL;
		ret     = JSObjectCallAsFunction(this->m_context.context(),
										 this->m_update_function, this->m_patch_object,
										 call_arguments.size(), &call_arguments[0],
										 &except);
		if (except != NULL)
			this->m_context.throwException(except);
	}
	else
	{
		ret = JSValueMakeUndefined(this->m_context.context());
	}

	return ret;
}

#pragma mark Construction and Destruction

BB::Patch::Patch(BB::Context& context,
				 const name_value_pair    input_defaults[],
				 const name_function_pair output_functions[],
				 JSObjectRef update_function)
 :	m_context(context),
	m_create_function(NULL)
{
	const name_value_pair*    input;
	const name_function_pair* output;
	JSContextRef ctx;

	ctx = context.context();
	this->m_update_function = update_function;	
	this->m_patch_object = JSObjectMake(ctx, context.patchClass(), this);

	if (input_defaults != NULL)
	{
		for (input = &input_defaults[0]; !input->name.empty(); ++input)
		{
			this->addInput(input->name, input->value);
		}
	}
	if (output_functions != NULL)
	{
		for (output = &output_functions[0]; !output->name.empty(); ++output)
		{
			this->addOutput(output->name, output->function);
		}
	}

//	JSValueProtect(ctx, this->m_patch_object);
}
BB::Patch::~Patch()
{
	this->disconnectAll();
}

void BB::Patch::addInput(const std::string& name, JSValueRef value)
{
	this->m_inputs.insert(std::make_pair(name, value));
}
void BB::Patch::addOutput(const std::string& name, JSObjectRef function)
{
	this->m_outputs.insert(std::make_pair(name, function));
}
void BB::Patch::removeInput(const std::string& name)
{
	this->disconnect(name);
	this->m_inputs.erase(name);
}
void BB::Patch::removeOutput(const std::string& name)
{
	this->disconnectOutput(name);
	this->m_outputs.erase(name);
}

#pragma mark Connection Functions

void BB::Patch::connect(const std::string& to_input,
						BB::Patch* from_patch,
						const std::string& output) throw(BB::Exception)
{
	std::pair<std::map<std::string, std::pair<BB::Patch*, std::string> >::iterator, bool> match;

	assert(from_patch != NULL && from_patch != this);

	if (this->m_inputs.find(to_input) == this->m_inputs.end())
		this->m_context.throwException("Input does not exist: " + to_input);
	if (from_patch->m_outputs.find(output) == from_patch->m_outputs.end())
		this->m_context.throwException("Output does not exist: " + output);

	// try to insert the new connection
	match = this->m_input_connections.insert(std::make_pair(to_input, std::make_pair(from_patch, output)));

	// if it is already connected, remove the connection from the other patch
	if (!match.second)
	{
		std::pair<BB::Patch*, std::string> pair = match.first->second;
		pair.first->disconnect(pair.second);
		match.first->second = std::make_pair(from_patch, output);
	}

	// perhaps ensure the other patch knows this is connected.
	from_patch->m_output_connections.insert(std::make_pair(output, std::make_pair(this, to_input)));
}

// std::map<std::string, std::pair<BB::Patch*, std::string> > m_input_connections;
// std::multimap<std::string, std::pair<BB::Patch*, std::string> > m_output_connections;
void BB::Patch::disconnect(const std::string& to_input,
						   BB::Patch* from_patch,
						   const std::string& output) throw(BB::Exception)
{
	typedef std::multimap<std::string, std::pair<BB::Patch*, std::string> >::iterator iter;
	std::map<std::string, std::pair<BB::Patch*, std::string> >::iterator input_match;
	std::pair<BB::Patch*, std::string> result;
	std::pair<iter,iter> range;
	iter output_match;

	input_match = this->m_input_connections.find(to_input);
	if (input_match == this->m_input_connections.end())
		this->m_context.throwException("Unable to find input: " + to_input);
	result = input_match->second;

	assert(input_match->second.first  == from_patch &&
		   input_match->second.second == output);

	range = from_patch->m_output_connections.equal_range(output);
	output_match = from_patch->m_output_connections.end();
	for (iter i=range.first; i!=range.second; ++i)
	{
		if (i->second.first  == this &&
			i->second.second == to_input)
		{
			assert(output_match == from_patch->m_output_connections.end());
			output_match = i;
		}
	}

	if (output_match == from_patch->m_output_connections.end())
		this->m_context.throwException("Unable to find output: " + output);

	from_patch->m_output_connections.erase(output_match);
	this->m_input_connections.erase(input_match);
}

void BB::Patch::disconnect(const std::string& to_input) throw(BB::Exception)
{
	std::map<std::string, std::pair<BB::Patch*, std::string> >::iterator input_match;

	input_match = this->m_input_connections.find(to_input);
	if (input_match == this->m_input_connections.end())
		this->m_context.throwException("Unable to find input: " + to_input);
	
	this->disconnect(input_match->first,
					 input_match->second.first,
					 input_match->second.second);
}

void BB::Patch::disconnectOutput(const std::string& output) throw(BB::Exception)
{
	typedef std::multimap<std::string, std::pair<BB::Patch*, std::string> >::iterator iter;
	typedef std::vector<std::pair<std::string, std::pair<BB::Patch*, std::string> > > store;
	std::pair<iter,iter> range;
	store for_removal;
	iter output_match;
	
	range = this->m_output_connections.equal_range(output);
	output_match = this->m_output_connections.end();
	for (iter i=range.first; i!=range.second; ++i)
		for_removal.push_back(*i);
	for (store::iterator i=for_removal.begin(); i!=for_removal.end(); ++i)
		this->disconnect(i->first, i->second.first, i->second.second);
}

void BB::Patch::disconnectAll() throw(BB::Exception)
{
	std::map<std::string, std::pair<BB::Patch*, std::string> >::iterator input_match;
	std::multimap<std::string, std::pair<BB::Patch*, std::string> >::iterator output_match;

	while ((input_match = this->m_input_connections.begin()) != this->m_input_connections.end())
		this->disconnect(input_match->first, input_match->second.first, input_match->second.second);
	while ((output_match = this->m_output_connections.begin()) != this->m_output_connections.end())
		output_match->second.first->disconnect(output_match->second.second, this, output_match->first);
}

#pragma mark Utility Functions

JSValueRef BB::Patch::evaluateScript(const std::string& string) const throw(BB::Exception)
{
	JSStringRef script;
	JSValueRef except, value;
	
	except = NULL;
	script = JSStringCreateWithUTF8CString(string.c_str());
	value  = JSEvaluateScript(this->m_context.context(), script, this->m_patch_object, NULL, 1, &except);
	if (except != NULL)
		this->m_context.throwException(except);

	JSStringRelease(script);
	
	return value;
}

#pragma mark -
#pragma mark Static Functions
#pragma mark -

void BB::Patch::Initialize(JSContextRef ctx, JSObjectRef object)
{
}

void BB::Patch::Finalize(JSObjectRef object)
{
	BB::Patch * patch;

	patch = BB::Patch::FromJS(NULL, object);

	delete patch;
}

#pragma mark Construct
JSObjectRef BB::Patch::Constructor(JSContextRef ctx,
								   JSObjectRef constructor,
								   size_t argumentCount,
								   const JSValueRef arguments[],
								   JSValueRef *exception) throw(BB::Exception)
{
	BB::Context * context;
	BB::Patch * patch;
	JSObjectRef update_function;
	JSValueRef except;
	
	context = BB::Context::FromJS(ctx);
	if (argumentCount == 0)
	{
		update_function = NULL;
	}
	else if (argumentCount == 1)
	{
		except   = NULL;
		update_function = JSValueToObject(ctx, arguments[2], &except);
		if (except != NULL)
			context->throwException(except);
		if (!JSObjectIsFunction(ctx, update_function))
			context->throwException("Create's third argument must be a function");
	}
	else
	{
		context->throwException("Create takes at most one 1 argument!");
	}
	
	patch = new BB::Patch(*context, NULL, NULL, update_function);
	
	return patch->m_patch_object;
}

#pragma mark Input and Outputs
JSValueRef BB::Patch::AddInput(JSContextRef ctx,
							 JSObjectRef function,
							 JSObjectRef thisObject,
							 size_t argumentCount,
							 const JSValueRef arguments[],
							 JSValueRef* exception) throw(BB::Exception)
{
	BB::Context * context;
	BB::Patch * patch;
	context = BB::Context::FromJS(ctx);
	if (argumentCount != 2)
		context->throwException("AddInput only takes two arguments!");
	patch = BB::Patch::FromJS(ctx, thisObject);
	patch->addInput(patch->m_context.getString(arguments[0]), arguments[1]);
	return patch->update();
}

JSValueRef BB::Patch::AddOutput(JSContextRef ctx,
								JSObjectRef function,
								JSObjectRef thisObject,
								size_t argumentCount,
								const JSValueRef arguments[],
								JSValueRef* exception) throw(BB::Exception)
{
	BB::Context * context;
	BB::Patch * patch;
	JSObjectRef output_function;
	JSValueRef except;
	
	context = BB::Context::FromJS(ctx);
	if (argumentCount != 2)
		context->throwException("AddOutput only takes two arguments!");
	patch = BB::Patch::FromJS(ctx, thisObject);

	except   = NULL;
	output_function = JSValueToObject(ctx, arguments[1], &except);
	if (except != NULL)
		context->throwException(except);
	if (!JSObjectIsFunction(ctx, output_function))
		context->throwException("AddOutput's second argument must be a function");

	patch->addOutput(patch->m_context.getString(arguments[0]), output_function);
	return patch->update();
}

JSValueRef BB::Patch::RemoveInput(JSContextRef ctx,
								  JSObjectRef function,
								  JSObjectRef thisObject,
								  size_t argumentCount,
								  const JSValueRef arguments[],
								  JSValueRef* exception) throw(BB::Exception)
{
	BB::Context * context;
	BB::Patch * patch;
	context = BB::Context::FromJS(ctx);
	if (argumentCount != 2)
		context->throwException("RemoveInput only takes one argument!");
	patch = BB::Patch::FromJS(ctx, thisObject);
	patch->removeInput(patch->m_context.getString(arguments[0]));
	return patch->update();
}

JSValueRef BB::Patch::RemoveOutput(JSContextRef ctx,
								JSObjectRef function,
								JSObjectRef thisObject,
								size_t argumentCount,
								const JSValueRef arguments[],
								JSValueRef* exception) throw(BB::Exception)
{
	BB::Context * context;
	BB::Patch * patch;
	context = BB::Context::FromJS(ctx);
	if (argumentCount != 2)
		context->throwException("RemoveOutput only takes one argument!");
	patch = BB::Patch::FromJS(ctx, thisObject);
	patch->removeOutput(patch->m_context.getString(arguments[0]));
	return patch->update();
}

JSValueRef BB::Patch::GetInput(JSContextRef ctx,
							   JSObjectRef function,
							   JSObjectRef thisObject,
							   size_t argumentCount,
							   const JSValueRef arguments[],
							   JSValueRef* exception) throw(BB::Exception)
{
	BB::Context * context;
	BB::Patch * patch;

	context = BB::Context::FromJS(ctx);
	if (argumentCount != 1)
		context->throwException("GetInput takes only one argument!");

	patch = BB::Patch::FromJS(ctx, thisObject);
	
	return patch->getInput(context->getString(arguments[0]));
}

JSValueRef BB::Patch::GetOutput(JSContextRef ctx,
								JSObjectRef function,
								JSObjectRef thisObject,
								size_t argumentCount,
								const JSValueRef arguments[],
								JSValueRef* exception) throw(BB::Exception)
{
	BB::Context * context;
	BB::Patch * patch;
	
	context = BB::Context::FromJS(ctx);
	if (argumentCount != 1)
		context->throwException("GetOutput takes only one argument!");
	
	patch = BB::Patch::FromJS(ctx, thisObject);
	
	return patch->getOutput(context->getString(arguments[0]));
}

#pragma mark Connections

JSValueRef BB::Patch::Connect(JSContextRef ctx,
							  JSObjectRef function,
							  JSObjectRef thisObject,
							  size_t argumentCount,
							  const JSValueRef arguments[],
							  JSValueRef* exception) throw(BB::Exception)
{
	BB::Context * context;
	BB::Patch * patch, * output_patch;
	JSObjectRef object;
	JSValueRef except;
	std::string input, output;
	
	context = BB::Context::FromJS(ctx);
	if (argumentCount != 3)
		context->throwException("Connect takes only three arguments!");

	patch = BB::Patch::FromJS(ctx, thisObject);

	except = NULL;
	object = JSValueToObject(ctx, arguments[1], &except);
	if (except != NULL)
		patch->m_context.throwException("Connect second argument is invalid");
	output_patch = BB::Patch::FromJS(ctx, object);
	if (output_patch == NULL)
		patch->m_context.throwException("Connect second argument must be a Patch object");

	input  = context->getString(arguments[0]);
	output = context->getString(arguments[2]);

	patch->connect(input, output_patch, output);

	return JSValueMakeUndefined(ctx);
}

JSValueRef BB::Patch::DisconnectInput(JSContextRef ctx,
									  JSObjectRef function,
									  JSObjectRef thisObject,
									  size_t argumentCount,
									  const JSValueRef arguments[],
									  JSValueRef* exception) throw(BB::Exception)
{
	BB::Context * context;
	BB::Patch * patch;
	std::string name;
	
	context = BB::Context::FromJS(ctx);
	if (argumentCount != 1)
		context->throwException("DisconnectInput takes only one argument!");
	
	patch = BB::Patch::FromJS(ctx, thisObject);
	name  = context->getString(arguments[0]);
	patch->disconnect(name);

	return JSValueMakeUndefined(ctx);
}

JSValueRef BB::Patch::DisconnectOutput(JSContextRef ctx,
									   JSObjectRef function,
									   JSObjectRef thisObject,
									   size_t argumentCount,
									   const JSValueRef arguments[],
									   JSValueRef* exception) throw(BB::Exception)
{
	BB::Context * context;
	BB::Patch * patch;
	std::string name;
	
	context = BB::Context::FromJS(ctx);
	if (argumentCount != 1)
		context->throwException("DisconnectOutput takes only one argument!");
	
	patch = BB::Patch::FromJS(ctx, thisObject);
	name  = context->getString(arguments[0]);
	patch->disconnectOutput(name);
	
	return JSValueMakeUndefined(ctx);
}

#pragma mark Update
JSValueRef BB::Patch::Update(JSContextRef ctx,
							 JSObjectRef function,
							 JSObjectRef thisObject,
							 size_t argumentCount,
							 const JSValueRef arguments[],
							 JSValueRef* exception) throw(BB::Exception)
{
	BB::Context * context;
	BB::Patch * patch;
	
	context = BB::Context::FromJS(ctx);
	if (argumentCount != 0)
		context->throwException("Update takes only one argument!");
	
	patch = BB::Patch::FromJS(ctx, thisObject);
	
	return patch->update();
}

#pragma mark Utility

BB::Patch* BB::Patch::FromJS(JSContextRef ctx,
							 JSObjectRef object)
{
	BB::Context * context;
	BB::Patch * patch;
	
	if (ctx != NULL)
	{
		context = BB::Context::FromJS(ctx);
		if (!JSValueIsObjectOfClass(ctx, object, context->patchClass()))
		{
			return NULL;
		}
	}

	patch = static_cast<BB::Patch*>(JSObjectGetPrivate(object));

	return patch;
}

#pragma mark Static Properties

const JSStaticValue BB::Patch::StaticValues[] =
{
	{NULL, NULL, NULL, 0}
};

const JSStaticFunction BB::Patch::StaticFunctions[] =
{
//	{"Create", BB::Patch::Create, kJSPropertyAttributeReadOnly | kJSPropertyAttributeDontEnum | kJSPropertyAttributeDontDelete},
	{"update", BB::Patch::Update, kJSPropertyAttributeReadOnly | kJSPropertyAttributeDontEnum | kJSPropertyAttributeDontDelete},

	{"addInput",  BB::Patch::AddInput,  kJSPropertyAttributeReadOnly | kJSPropertyAttributeDontEnum | kJSPropertyAttributeDontDelete},
	{"addOutput", BB::Patch::AddOutput, kJSPropertyAttributeReadOnly | kJSPropertyAttributeDontEnum | kJSPropertyAttributeDontDelete},
	{"removeInput",  BB::Patch::RemoveInput,  kJSPropertyAttributeReadOnly | kJSPropertyAttributeDontEnum | kJSPropertyAttributeDontDelete},
	{"removeOutput", BB::Patch::RemoveOutput, kJSPropertyAttributeReadOnly | kJSPropertyAttributeDontEnum | kJSPropertyAttributeDontDelete},

	{"getInput",  BB::Patch::GetInput,  kJSPropertyAttributeReadOnly | kJSPropertyAttributeDontEnum | kJSPropertyAttributeDontDelete},
	{"getOutput", BB::Patch::GetOutput, kJSPropertyAttributeReadOnly | kJSPropertyAttributeDontEnum | kJSPropertyAttributeDontDelete},

	{"connect",          BB::Patch::Connect,  kJSPropertyAttributeReadOnly | kJSPropertyAttributeDontEnum | kJSPropertyAttributeDontDelete},
	{"disconnectInput",  BB::Patch::DisconnectInput,  kJSPropertyAttributeReadOnly | kJSPropertyAttributeDontEnum | kJSPropertyAttributeDontDelete},
	{"disconnectOutput", BB::Patch::DisconnectOutput, kJSPropertyAttributeReadOnly | kJSPropertyAttributeDontEnum | kJSPropertyAttributeDontDelete},

	{NULL, NULL, 0}
};

const JSClassDefinition BB::Patch::Definition =
{
    0, kJSClassAttributeNone,//kJSClassAttributeNoAutomaticPrototype,
    "Patch", NULL,
    BB::Patch::StaticValues,
    BB::Patch::StaticFunctions,
    BB::Patch::Initialize,
    BB::Patch::Finalize,
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
};

#pragma mark -
#pragma mark Patch C Interface
#pragma mark -

#pragma mark Create and Destroy

bb_patch bbPatchCreate(bb_context ctx)
{
	BB::Context * context;
	BB::Patch * patch;
	
	try
	{
		context = reinterpret_cast<BB::Context*>(ctx);
		patch   = BB::Patch::CreateFromSource(*context, NULL, NULL, NULL);
		
		JSValueProtect(context->context(), patch->object());
	}
	catch (BB::Exception& error)
	{
		std::cerr << error.what() << std::endl;
		return NULL;
	}
	
	return reinterpret_cast<bb_patch>(patch);
}

void bbPatchDestroy(bb_patch ptch)
{
	BB::Context* context;
	BB::Patch*   patch;
	JSContextRef ctx;
	JSObjectRef  object;
	
	try
	{
		patch   = reinterpret_cast<BB::Patch*>(ptch);
		context = patch->context();
		ctx     = context->context();
		object  = patch->object();
		
		JSValueUnprotect(ctx, object);
		JSGarbageCollect(ctx);
	}
	catch (BB::Exception& error)
	{
		std::cerr << error.what() << std::endl;
	}		
}

#pragma mark Update

void bbPatchUpdate(bb_patch ptch)
{
	BB::Patch* patch;
	
	try
	{
		patch = reinterpret_cast<BB::Patch*>(ptch);
		patch->update();
	}
	catch (BB::Exception& error)
	{
		std::cerr << error.what() << std::endl;
	}	
}

#pragma mark Add and Remove Inputs and Outputs

void bbPatchAddInputAsString(bb_patch ptch, const char * name, const char * string)
{
	BB::Patch* patch;
	JSValueRef value;
	
	try
	{
		patch = reinterpret_cast<BB::Patch*>(ptch);
		value = patch->context()->createString(string);
		patch->addInput(name, value);
	}
	catch (BB::Exception& error)
	{
		std::cerr << error.what() << std::endl;
	}	
}

void bbPatchAddInputAsNumber(bb_patch ptch, const char * name, double number)
{
	BB::Patch* patch;
	JSValueRef value;
	
	try
	{
		patch = reinterpret_cast<BB::Patch*>(ptch);
		value = patch->context()->createNumber(number);
		patch->addInput(name, value);
	}
	catch (BB::Exception& error)
	{
		std::cerr << error.what() << std::endl;
	}	
}

void bbPatchAddOutputAsFunction(bb_patch ptch, const char * name, const char * source)
{
	JSObjectRef function;
	BB::Patch* patch;
	
	try
	{
		patch    = reinterpret_cast<BB::Patch*>(ptch);
		function = patch->context()->createFunction(source);
		patch->addOutput(name, function);
	}
	catch (BB::Exception& error)
	{
		std::cerr << error.what() << std::endl;
	}
}

void bbPatchRemoveInput(bb_patch ptch, const char * name)
{
	BB::Patch* patch;
	
	try
	{
		patch = reinterpret_cast<BB::Patch*>(ptch);
		patch->removeInput(name);
	}
	catch (BB::Exception& error)
	{
		std::cerr << error.what() << std::endl;
	}
}

void bbPatchRemoveOutput(bb_patch ptch, const char * name)
{
	BB::Patch* patch;
	
	try
	{
		patch = reinterpret_cast<BB::Patch*>(ptch);
		patch->removeOutput(name);
	}
	catch (BB::Exception& error)
	{
		std::cerr << error.what() << std::endl;
	}
}

#pragma mark Manage Connections

void bbPatchConnect(bb_patch ptch_in,  const char * input,
					bb_patch ptch_out, const char * output)
{
	BB::Patch* patch_in;
	BB::Patch* patch_out;
	
	try
	{
		patch_in  = reinterpret_cast<BB::Patch*>(ptch_in);
		patch_out = reinterpret_cast<BB::Patch*>(ptch_out);
		patch_in->connect(input, patch_out, output);
	}
	catch (BB::Exception& error)
	{
		std::cerr << error.what() << std::endl;
	}	
}

void bbPatchDisconnectInput(bb_patch ptch, const char * name)
{
	BB::Patch* patch;
	
	try
	{
		patch = reinterpret_cast<BB::Patch*>(ptch);
		patch->disconnect(name);
	}
	catch (BB::Exception& error)
	{
		std::cerr << error.what() << std::endl;
	}
}

void bbPatchDisconnectOutput(bb_patch ptch, const char * name)
{
	BB::Patch* patch;
	
	try
	{
		patch = reinterpret_cast<BB::Patch*>(ptch);
		patch->disconnectOutput(name);
	}
	catch (BB::Exception& error)
	{
		std::cerr << error.what() << std::endl;
	}
}

#pragma mark Get Input and Output

const char * bbPatchGetInputAsString(bb_patch ptch, const char * name)
{
	BB::Patch* patch;
	
	try
	{
		std::string string;
		JSValueRef value;
		char * buffer;
		
		patch  = reinterpret_cast<BB::Patch*>(ptch);
		value  = patch->getInput(name);
		string = patch->context()->getString(value);
		buffer = (char*) malloc(string.size()+1);
		string.copy(buffer, string.size());
		buffer[string.size()] = '\0';
		
		return buffer;
	}
	catch (BB::Exception& error)
	{
		std::cerr << error.what() << std::endl;
	}
	
	return NULL;
}

double bbPatchGetInputAsNumber(bb_patch ptch, const char * name)
{
	BB::Patch* patch;
	
	try
	{
		std::string string;
		JSValueRef value;
		
		patch  = reinterpret_cast<BB::Patch*>(ptch);
		value  = patch->getInput(name);
		return patch->context()->getNumber(value);
	}
	catch (BB::Exception& error)
	{
		std::cerr << error.what() << std::endl;
	}
	
	return NULL;
}

const char * bbPatchGetOutputAsString(bb_patch ptch, const char * name)
{
	BB::Patch* patch;
	
	try
	{
		std::string string;
		JSValueRef value;
		char * buffer;
		
		patch  = reinterpret_cast<BB::Patch*>(ptch);
		value  = patch->getOutput(name);
		string = patch->context()->getString(value);
		buffer = (char*) malloc(string.size()+1);
		string.copy(buffer, string.size());
		buffer[string.size()] = '\0';
		
		return buffer;
	}
	catch (BB::Exception& error)
	{
		std::cerr << error.what() << std::endl;
	}
	
	return NULL;
}

double bbPatchGetOutputAsNumber(bb_patch ptch, const char * name)
{
	BB::Patch* patch;
	
	try
	{
		std::string string;
		JSValueRef value;
		
		patch  = reinterpret_cast<BB::Patch*>(ptch);
		value  = patch->getOutput(name);
		return patch->context()->getNumber(value);
	}
	catch (BB::Exception& error)
	{
		std::cerr << error.what() << std::endl;
	}
	
	return NULL;
}

