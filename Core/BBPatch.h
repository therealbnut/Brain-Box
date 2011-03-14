#ifndef _BB_PATCH_H_
#define _BB_PATCH_H_

#include <JavaScriptCore/JavaScriptCore.h>
#include <string>
#include <vector>
#include <map>

#include <libxml/parser.h>
#include <libxml/tree.h>

#include "BBException.h"

namespace BB
{
	class Context;
	class PatchCollection;

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
										   const name_source_pair output_sources[]);
		
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

		static BB::Patch* FromJS(JSContextRef ctx,
								 JSObjectRef object);

		inline size_t inputCount() const  {return this->m_inputs.size();}
		inline size_t outputCount() const {return this->m_outputs.size();}
		std::vector<const char*> inputs() const;
		std::vector<const char*> outputs() const;
		std::vector<std::pair<BB::Patch*,const char*> > inputConnections() const;

	protected:
		friend class PatchCollection;

		Patch(BB::Context& context,
			  const name_value_pair    input_defaults[],
			  const name_function_pair output_functions[]);
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

		static JSValueRef GetInput(JSContextRef,JSObjectRef,JSObjectRef,size_t,const JSValueRef[],JSValueRef*) throw(BB::Exception);
		static JSValueRef GetOutput(JSContextRef,JSObjectRef,JSObjectRef,size_t,const JSValueRef[],JSValueRef*) throw(BB::Exception);

		static JSValueRef Connect(JSContextRef,JSObjectRef,JSObjectRef,size_t,const JSValueRef[],JSValueRef*) throw(BB::Exception);
		static JSValueRef DisconnectInput(JSContextRef,JSObjectRef,JSObjectRef,size_t,const JSValueRef[],JSValueRef*) throw(BB::Exception);
		static JSValueRef DisconnectOutput(JSContextRef,JSObjectRef,JSObjectRef,size_t,const JSValueRef[],JSValueRef*) throw(BB::Exception);

		static const JSClassDefinition Definition;
		static const JSStaticValue     StaticValues[];
		static const JSStaticFunction  StaticFunctions[];

	protected:		
		xmlNodePtr serialize(const std::map<const BB::Patch*,size_t>& ids) const;

		size_t deserializePatch(xmlNodePtr patch);
		static void DeserializeConnections(BB::Context& context,
										   xmlNodePtr patch,
										   const std::map<size_t,BB::Patch*>& ids);
		
	private:
		BB::Context& m_context;
		JSObjectRef  m_patch_object;

		std::map<std::string, std::pair<BB::Patch*, std::string> > m_input_connections;
		std::multimap<std::string, std::pair<BB::Patch*, std::string> > m_output_connections;

		std::map<std::string, JSValueRef>  m_inputs;
		std::map<std::string, JSObjectRef> m_outputs;
	};
};

#endif
