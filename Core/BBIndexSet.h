#ifndef _BB_INDEX_SET_H_
#define _BB_INDEX_SET_H_

#include <JavaScriptCore/JavaScriptCore.h>
#include <set>

#include "BBException.h"

namespace BB
{
	class Context;

	class IndexSet
	{
	public:
		IndexSet(BB::Context& context);
		IndexSet(BB::Context& context, size_t count);
		IndexSet(BB::Context& context, size_t min, size_t max);
		IndexSet(BB::Context& context, const std::set<size_t>& indices);
		IndexSet(BB::Context& context, std::set<size_t>& indices);

		inline JSObjectRef  object() const {return this->m_object;}
		inline BB::Context* context() const {return &this->m_context;}

		void clear();
		void swap(IndexSet& that);
		void bool_intersection(const IndexSet& a, const IndexSet& b);
		void bool_union(const IndexSet& a, const IndexSet& b);
		void bool_difference(const IndexSet& a, const IndexSet& b);

		void for_all(void (*callback)(size_t index, void * data), void * data) const;
		void filter(bool (*callback)(size_t index, void * data), void * data,
					IndexSet& pass, IndexSet& fail) const;
		void filter(bool (*callback)(size_t index, void * data), void * data,
					IndexSet& pass) const;

		static BB::IndexSet* FromJS(JSContextRef ctx,
									JSObjectRef object);
		static BB::IndexSet* FromJS(JSContextRef ctx,
									JSValueRef value);

	protected:
		friend class Context;

		static void Initialize(JSContextRef ctx, JSObjectRef object);
		static void Finalize(JSObjectRef object);

		static JSObjectRef Constructor(JSContextRef, JSObjectRef, size_t, const JSValueRef[], JSValueRef*) throw(BB::Exception);

		static JSValueRef Clear(JSContextRef,JSObjectRef,JSObjectRef,size_t,const JSValueRef[],JSValueRef*) throw(BB::Exception);
		static JSValueRef Swap(JSContextRef,JSObjectRef,JSObjectRef,size_t,const JSValueRef[],JSValueRef*) throw(BB::Exception);
		static JSValueRef Intersect(JSContextRef,JSObjectRef,JSObjectRef,size_t,const JSValueRef[],JSValueRef*) throw(BB::Exception);
		static JSValueRef Union(JSContextRef,JSObjectRef,JSObjectRef,size_t,const JSValueRef[],JSValueRef*) throw(BB::Exception);
		static JSValueRef Difference(JSContextRef,JSObjectRef,JSObjectRef,size_t,const JSValueRef[],JSValueRef*) throw(BB::Exception);
		static JSValueRef ForAll(JSContextRef,JSObjectRef,JSObjectRef,size_t,const JSValueRef[],JSValueRef*) throw(BB::Exception);
		static JSValueRef Filter(JSContextRef,JSObjectRef,JSObjectRef,size_t,const JSValueRef[],JSValueRef*) throw(BB::Exception);

		static const JSClassDefinition Definition;
		static const JSStaticValue     StaticValues[];
		static const JSStaticFunction  StaticFunctions[];		

	protected:
		void createObject();
		
	private:
		BB::Context& m_context;
		JSObjectRef  m_object;

		std::set<size_t> m_indices;
	};
}

#endif
