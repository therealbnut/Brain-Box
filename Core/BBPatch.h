#ifndef _BB_PATCH_H_
#define _BB_PATCH_H_

#include <JavaScriptCore/JavaScriptCore.h>
#include <string>
#include <map>

#include "BBException.h"

namespace BB
{
	class Context;

	class Patch
	{
	public:
		typedef struct _property_source_pair
		{
			std::string name;
			std::string source;
		} name_source_pair;
		typedef struct _property_function_pair
		{
			std::string name;
			JSObjectRef function;
		} name_function_pair;
		typedef struct _property_value_pair
		{
			std::string name;
			JSValueRef  value;
		} name_value_pair;
		
		static const name_source_pair   NameSourcePairEnd;
		static const name_function_pair NameFunctionPairEnd;
		static const name_value_pair    NameValuePairEnd;

		inline JSObjectRef  object() const {return this->m_patch_object;}
		inline BB::Context* context() const {return &this->m_context;}

		static BB::Patch* CreateFromSource(BB::Context& context,
										   const name_value_pair  input_defaults[],
										   const name_source_pair output_sources[],
										   const std::string& update_source);
		
		void addInput(const std::string& name, JSValueRef value);
		void addOutput(const std::string& name, JSObjectRef function);
		
		void removeInput(const std::string& name);
		void removeOutput(const std::string& name);

		JSValueRef getInput(const std::string& name) const throw(BB::Exception);
		JSValueRef getOutput(const std::string& name) const throw(BB::Exception);
		
		void connect(const std::string& to_input,
					 BB::Patch* from_patch,
					 const std::string& output) throw(BB::Exception);
		void disconnect(const std::string& to_input,
						BB::Patch* from_patch,
						const std::string& output) throw(BB::Exception);
		void disconnect(const std::string& input) throw(BB::Exception);
		void disconnectOutput(const std::string& output) throw(BB::Exception);
		void disconnectAll() throw(BB::Exception);

		JSValueRef update() const;

		static BB::Patch* FromJS(JSContextRef ctx,
								 JSObjectRef object);
	protected:
		Patch(BB::Context& context,
			  const name_value_pair    input_defaults[],
			  const name_function_pair output_functions[],
			  JSObjectRef update_function);
		virtual ~Patch();

		JSValueRef evaluateScript(const std::string& string) const throw(BB::Exception);

	protected:
		friend class Context;

		static void Initialize(JSContextRef ctx, JSObjectRef object);
		static void Finalize(JSObjectRef object);
		
		static JSObjectRef Constructor(JSContextRef, JSObjectRef, size_t, const JSValueRef[], JSValueRef*) throw(BB::Exception);

		static JSValueRef AddInput(JSContextRef,JSObjectRef,JSObjectRef,size_t,const JSValueRef[],JSValueRef*) throw(BB::Exception);
		static JSValueRef AddOutput(JSContextRef,JSObjectRef,JSObjectRef,size_t,const JSValueRef[],JSValueRef*) throw(BB::Exception);
		static JSValueRef RemoveInput(JSContextRef,JSObjectRef,JSObjectRef,size_t,const JSValueRef[],JSValueRef*) throw(BB::Exception);
		static JSValueRef RemoveOutput(JSContextRef,JSObjectRef,JSObjectRef,size_t,const JSValueRef[],JSValueRef*) throw(BB::Exception);

		static JSValueRef Update(JSContextRef,JSObjectRef,JSObjectRef,size_t,const JSValueRef[],JSValueRef*) throw(BB::Exception);

		static JSValueRef GetInput(JSContextRef,JSObjectRef,JSObjectRef,size_t,const JSValueRef[],JSValueRef*) throw(BB::Exception);
		static JSValueRef GetOutput(JSContextRef,JSObjectRef,JSObjectRef,size_t,const JSValueRef[],JSValueRef*) throw(BB::Exception);

		static JSValueRef Connect(JSContextRef,JSObjectRef,JSObjectRef,size_t,const JSValueRef[],JSValueRef*) throw(BB::Exception);
		static JSValueRef DisconnectInput(JSContextRef,JSObjectRef,JSObjectRef,size_t,const JSValueRef[],JSValueRef*) throw(BB::Exception);
		static JSValueRef DisconnectOutput(JSContextRef,JSObjectRef,JSObjectRef,size_t,const JSValueRef[],JSValueRef*) throw(BB::Exception);

		static const JSClassDefinition Definition;
		static const JSStaticValue     StaticValues[];
		static const JSStaticFunction  StaticFunctions[];

	private:
		BB::Context& m_context;
		JSObjectRef  m_patch_object;
		JSObjectRef  m_update_function;
		JSObjectRef  m_create_function;

		std::map<std::string, std::pair<BB::Patch*, std::string> > m_input_connections;
		std::multimap<std::string, std::pair<BB::Patch*, std::string> > m_output_connections;

		std::map<std::string, JSValueRef>  m_inputs;
		std::map<std::string, JSObjectRef> m_outputs;
	};
};

#endif
