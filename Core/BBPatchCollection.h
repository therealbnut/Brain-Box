#ifndef _BB_PATCH_COLLECTION_H_
#define _BB_PATCH_COLLECTION_H_

#include <JavaScriptCore/JavaScriptCore.h>
#include <set>
#include <string>

#include "BBException.h"

namespace BB
{
	class Patch;
	class Context;

	class PatchCollection
	{
	public:
		PatchCollection(BB::Context& context);
		PatchCollection(BB::Context& context, 
						const std::string& filename);
		virtual ~PatchCollection();

		inline JSObjectRef  object() const {return this->m_patch_collection_object;}
		inline BB::Context* context() const {return &this->m_context;}

		void managePatch(BB::Patch& patch);
		void unmanagePatch(BB::Patch& patch);

		std::string serialize() const;
		void deserialize(const std::string& xml);

		void saveToFile(const std::string& filename) const throw(BB::Exception);
		void loadFromFile(const std::string& filename) throw(BB::Exception);

		static BB::PatchCollection* FromJS(JSContextRef ctx,
										   JSObjectRef object);

	protected:
		friend class Context;

		static void Initialize(JSContextRef ctx, JSObjectRef object);
		static void Finalize(JSObjectRef object);

		static JSObjectRef Constructor(JSContextRef, JSObjectRef, size_t, const JSValueRef[], JSValueRef*) throw(BB::Exception);

		static JSValueRef ManagePatch(JSContextRef,JSObjectRef,JSObjectRef,size_t,const JSValueRef[],JSValueRef*) throw(BB::Exception);
		static JSValueRef UnmanagePatch(JSContextRef,JSObjectRef,JSObjectRef,size_t,const JSValueRef[],JSValueRef*) throw(BB::Exception);
		static JSValueRef SaveToFile(JSContextRef,JSObjectRef,JSObjectRef,size_t,const JSValueRef[],JSValueRef*) throw(BB::Exception);

		static const JSClassDefinition Definition;
		static const JSStaticValue     StaticValues[];
		static const JSStaticFunction  StaticFunctions[];

	private:
		std::set<BB::Patch*> m_patches;
		BB::Context& m_context;
		JSObjectRef  m_patch_collection_object;
	};
}

#endif
