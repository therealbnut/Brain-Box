#include "BBIndexSet.h"
#include "BBContext.h"

#include <algorithm>

#pragma mark -
#pragma mark Constructors
#pragma mark -

BB::IndexSet::IndexSet(BB::Context& context) : m_context(context), m_object(NULL)
{
	this->createObject();
}
BB::IndexSet::IndexSet(BB::Context& context, size_t count) : m_context(context), m_object(NULL)
{
	for (size_t i=0; i<count; ++i)
		this->m_indices.insert(i);
	this->createObject();
}
BB::IndexSet::IndexSet(BB::Context& context, size_t min, size_t max) : m_context(context), m_object(NULL)
{
	for (size_t i=min; i<=max; ++i)
		this->m_indices.insert(i);
	this->createObject();
}
BB::IndexSet::IndexSet(BB::Context& context, const std::set<size_t>& indices)
: m_context(context), m_indices(indices), m_object(NULL)
{
	this->createObject();
}
BB::IndexSet::IndexSet(BB::Context& context, std::set<size_t>& indices) : m_context(context), m_object(NULL)
{
	this->m_indices.swap(indices);
	this->createObject();
}

#pragma mark -
#pragma mark Create Object
#pragma mark -

void BB::IndexSet::createObject()
{
	JSContextRef ctx;

	ctx = this->m_context.context();
	this->m_object = JSObjectMake(ctx, this->m_context.indexSetClass(), this);
}

#pragma mark -
#pragma mark Set Operations
#pragma mark -

void BB::IndexSet::clear()
{
	this->m_indices.clear();
}
void BB::IndexSet::swap(IndexSet& that)
{
	this->m_indices.swap(that.m_indices);
}
void BB::IndexSet::bool_intersection(const IndexSet& a, const IndexSet& b)
{
	std::insert_iterator<std::set<size_t> > iter(this->m_indices, this->m_indices.begin());
	std::set_intersection(a.m_indices.begin(), a.m_indices.end(),
						  b.m_indices.begin(), b.m_indices.end(),
						  iter);
}
void BB::IndexSet::bool_union(const IndexSet& a, const IndexSet& b)
{
	std::insert_iterator<std::set<size_t> > iter(this->m_indices, this->m_indices.begin());
	std::set_union(a.m_indices.begin(), a.m_indices.end(),
				   b.m_indices.begin(), b.m_indices.end(),
				   iter);
}
void BB::IndexSet::bool_difference(const IndexSet& a, const IndexSet& b)
{
	std::insert_iterator<std::set<size_t> > iter(this->m_indices, this->m_indices.begin());
	std::set_difference(a.m_indices.begin(), a.m_indices.end(),
						b.m_indices.begin(), b.m_indices.end(),
						iter);
}

#pragma mark -
#pragma mark Per Element Functions
#pragma mark -

void BB::IndexSet::for_all(void (*callback)(size_t index, void * data), void * data) const
{
	for (std::set<size_t>::const_iterator
		 i = this->m_indices.begin(),
		 e = this->m_indices.end();
		 i != e; ++i)
	{
		(*callback)(*i, data);
	}
}
void BB::IndexSet::filter(bool (*callback)(size_t index, void * data), void * data,
						  IndexSet& pass, IndexSet& fail) const
{
	
	for (std::set<size_t>::const_iterator
		 i = this->m_indices.begin(),
		 e = this->m_indices.end();
		 i != e; ++i)
	{
		if ((*callback)(*i, data))
		{
			pass.m_indices.insert(*i);
		}
		else
		{
			fail.m_indices.insert(*i);
		}
	}
}
void BB::IndexSet::filter(bool (*callback)(size_t index, void * data), void * data,
						  IndexSet& pass) const
{
	for (std::set<size_t>::const_iterator
		 i = this->m_indices.begin(),
		 e = this->m_indices.end();
		 i != e; ++i)
	{
		if ((*callback)(*i, data))
		{
			pass.m_indices.insert(*i);
		}
	}
}

#pragma mark -
#pragma mark JS Casting
#pragma mark -

BB::IndexSet* BB::IndexSet::FromJS(JSContextRef ctx,
								   JSObjectRef object)
{
	BB::Context * context;
	BB::IndexSet * index_set;
	
	if (ctx != NULL)
	{
		context = BB::Context::FromJS(ctx);
		if (!JSValueIsObjectOfClass(ctx, object, context->indexSetClass()))
		{
			return NULL;
		}
	}
	
	index_set = static_cast<BB::IndexSet*>(JSObjectGetPrivate(object));

	return index_set;
}

BB::IndexSet* BB::IndexSet::FromJS(JSContextRef ctx,
								   JSValueRef value)
{
	BB::Context * context;
	BB::IndexSet * index_set;

	JSValueRef except;
	JSObjectRef object;

	except   = NULL;
	object   = JSValueToObject(ctx, value, &except);
	if (except != NULL)
	{
		context  = BB::Context::FromJS(ctx);
		context->throwException(except);
	}
	
	index_set = static_cast<BB::IndexSet*>(JSObjectGetPrivate(object));

	return index_set;
}

#pragma mark -
#pragma mark Static Functions
#pragma mark -

void BB::IndexSet::Initialize(JSContextRef ctx, JSObjectRef object)
{
}

void BB::IndexSet::Finalize(JSObjectRef object)
{
	BB::IndexSet * index_set;
	
	index_set = BB::IndexSet::FromJS(NULL, object);
	
	delete index_set;
}

#pragma mark Construct
JSObjectRef BB::IndexSet::Constructor(JSContextRef ctx,
									  JSObjectRef constructor,
									  size_t argumentCount,
									  const JSValueRef arguments[],
									  JSValueRef *exception) throw(BB::Exception)
{
	BB::Context * context;
	BB::IndexSet * indexSet;
	JSValueRef except;
	size_t min, max;
	
	context = BB::Context::FromJS(ctx);
	switch (argumentCount)
	{
		case 0:
			indexSet = new BB::IndexSet(*context);
			break;
		case 1:
			except = NULL;
			max = JSValueToNumber(ctx, arguments[0], &except);
			if (except != NULL)
				context->throwException(except);

			indexSet = new BB::IndexSet(*context, max);
			break;
		case 2:
			except = NULL;
			min = JSValueToNumber(ctx, arguments[0], &except);
			if (except != NULL)
				context->throwException(except);

			except = NULL;
			max = JSValueToNumber(ctx, arguments[1], &except);
			if (except != NULL)
				context->throwException(except);			

			indexSet = new BB::IndexSet(*context, min, max);
			break;
		default:
			context->throwException("Constructor takes at most 2 arguments arguments!");
	}
	
	return indexSet->m_object;
}

#pragma mark -
#pragma mark Static JS Functions
#pragma mark -

JSValueRef BB::IndexSet::Clear(JSContextRef ctx,
							   JSObjectRef function,
							   JSObjectRef thisObject,
							   size_t argumentCount,
							   const JSValueRef arguments[],
							   JSValueRef* exception) throw(BB::Exception)
{
	BB::IndexSet * indexSet;
	BB::Context * context;
	
	context = BB::Context::FromJS(ctx);
	if (argumentCount != 0)
		context->throwException("Clear takes no arguments!");
	
	indexSet = BB::IndexSet::FromJS(ctx, thisObject);
	indexSet->clear();
	return JSValueMakeUndefined(ctx);
}

JSValueRef BB::IndexSet::Swap(JSContextRef ctx,
							  JSObjectRef function,
							  JSObjectRef thisObject,
							  size_t argumentCount,
							  const JSValueRef arguments[],
							  JSValueRef* exception) throw(BB::Exception)
{
	BB::IndexSet * indexSet;
	BB::IndexSet * indexSetA;
	BB::Context * context;
	
	context = BB::Context::FromJS(ctx);
	if (argumentCount != 1)
		context->throwException("Swap takes one arguments!");

	indexSet = BB::IndexSet::FromJS(ctx, thisObject);
	indexSetA = BB::IndexSet::FromJS(ctx, arguments[0]);
	indexSet->swap(*indexSetA);
	return JSValueMakeUndefined(ctx);
}

JSValueRef BB::IndexSet::Intersect(JSContextRef ctx,
								   JSObjectRef function,
								   JSObjectRef thisObject,
								   size_t argumentCount,
								   const JSValueRef arguments[],
								   JSValueRef* exception) throw(BB::Exception)
{
	BB::IndexSet * indexSet;
	BB::IndexSet * indexSetA, * indexSetB;
	BB::Context * context;
	
	context = BB::Context::FromJS(ctx);
	if (argumentCount != 2)
		context->throwException("Intersect takes two arguments!");

	indexSet  = BB::IndexSet::FromJS(ctx, thisObject);
	indexSetA = BB::IndexSet::FromJS(ctx, arguments[0]);
	indexSetB = BB::IndexSet::FromJS(ctx, arguments[1]);
	
	indexSet->bool_intersection(*indexSetA, *indexSetB);

	return JSValueMakeUndefined(ctx);
}

JSValueRef BB::IndexSet::Union(JSContextRef ctx,
							   JSObjectRef function,
							   JSObjectRef thisObject,
							   size_t argumentCount,
							   const JSValueRef arguments[],
							   JSValueRef* exception) throw(BB::Exception)
{
	BB::IndexSet * indexSet;
	BB::IndexSet * indexSetA, * indexSetB;
	BB::Context * context;
	
	context = BB::Context::FromJS(ctx);
	if (argumentCount != 2)
		context->throwException("Intersect takes two arguments!");
	
	indexSet  = BB::IndexSet::FromJS(ctx, thisObject);
	indexSetA = BB::IndexSet::FromJS(ctx, arguments[0]);
	indexSetB = BB::IndexSet::FromJS(ctx, arguments[0]);
	indexSet->bool_union(*indexSetA, *indexSetB);
	return JSValueMakeUndefined(ctx);
}

JSValueRef BB::IndexSet::Difference(JSContextRef ctx,
									JSObjectRef function,
									JSObjectRef thisObject,
									size_t argumentCount,
									const JSValueRef arguments[],
									JSValueRef* exception) throw(BB::Exception)
{
	BB::IndexSet * indexSet;
	BB::IndexSet * indexSetA, * indexSetB;
	BB::Context * context;
	
	context = BB::Context::FromJS(ctx);
	if (argumentCount != 2)
		context->throwException("Intersect takes two arguments!");
	
	indexSet  = BB::IndexSet::FromJS(ctx, thisObject);
	indexSetA = BB::IndexSet::FromJS(ctx, arguments[0]);
	indexSetB = BB::IndexSet::FromJS(ctx, arguments[0]);
	indexSet->bool_difference(*indexSetA, *indexSetB);
	return JSValueMakeUndefined(ctx);
}

struct BBJSIndexSet_callbackData
{
	BB::Context * context;
	JSObjectRef function;
	JSObjectRef object;
};

void BBJSIndexSet_forAll(size_t index, void * data)
{
	struct BBJSIndexSet_callbackData* d = (struct BBJSIndexSet_callbackData*) data;
	JSValueRef js_index, except;

	js_index = JSValueMakeNumber(d->context->context(), index);
	
	except = NULL;
	JSObjectCallAsFunction(d->context->context(),
						   d->function,
						   d->object, 1, &js_index,
						   &except);
	if (except != NULL)
		d->context->throwException(except);
}

bool BBJSIndexSet_filter(size_t index, void * data)
{
	struct BBJSIndexSet_callbackData* d = (struct BBJSIndexSet_callbackData*) data;
	JSValueRef js_index, except, result;
	
	js_index = JSValueMakeNumber(d->context->context(), index);
	
	except = NULL;
	result = JSObjectCallAsFunction(d->context->context(),
									d->function,
									d->object, 1, &js_index,
									&except);
	if (except != NULL)
		d->context->throwException(except);

	return JSValueToBoolean(d->context->context(), result);
}

JSValueRef BB::IndexSet::ForAll(JSContextRef ctx,
								JSObjectRef function,
								JSObjectRef thisObject,
								size_t argumentCount,
								const JSValueRef arguments[],
								JSValueRef* exception) throw(BB::Exception)
{
	BBJSIndexSet_callbackData data;
	BB::IndexSet * indexSet;
	BB::Context * context;
	JSValueRef except;
	
	context = BB::Context::FromJS(ctx);
	if (argumentCount != 2)
		context->throwException("Intersect takes two arguments!");

	data.context = context;
	
	except = NULL;
	data.function = JSValueToObject(ctx, arguments[0], &except);
	if (except != NULL)
		context->throwException(except);
	if (!JSObjectIsFunction(ctx, data.function))
		context->throwException("ForAll's first argument should be a function");	

	if (JSValueIsNull(ctx, arguments[1]))
	{
		data.object = NULL;
	}
	else
	{
		except = NULL;
		data.object = JSValueToObject(ctx, arguments[1], &except);
		if (except != NULL)
			context->throwException(except);
	}
	
	indexSet = BB::IndexSet::FromJS(ctx, thisObject);
	indexSet->for_all(BBJSIndexSet_forAll, &data);

	return JSValueMakeUndefined(ctx);
}

JSValueRef BB::IndexSet::Filter(JSContextRef ctx,
								JSObjectRef function,
								JSObjectRef thisObject,
								size_t argumentCount,
								const JSValueRef arguments[],
								JSValueRef* exception) throw(BB::Exception)
{
	BBJSIndexSet_callbackData data;
	BB::IndexSet * indexSet;
	BB::IndexSet * indexSetPass, * indexSetFail;
	BB::Context * context;
	JSValueRef except;
	
	context = BB::Context::FromJS(ctx);
	if (argumentCount != 3 && argumentCount != 4)
		context->throwException("Intersect takes two arguments!");

	data.context = context;

	except = NULL;
	data.function = JSValueToObject(ctx, arguments[0], &except);
	if (except != NULL)
		context->throwException(except);
	if (!JSObjectIsFunction(ctx, data.function))
		context->throwException("Filter's first argument should be a function");	

	if (JSValueIsNull(ctx, arguments[1]))
	{
		data.object = NULL;
	}
	else
	{
		except = NULL;
		data.object = JSValueToObject(ctx, arguments[1], &except);
		if (except != NULL)
			context->throwException(except);
	}
	indexSet = BB::IndexSet::FromJS(ctx, thisObject);

	indexSetPass = BB::IndexSet::FromJS(ctx, arguments[2]);
	if (argumentCount > 3)
		indexSetFail = BB::IndexSet::FromJS(ctx, arguments[3]);

	switch (argumentCount)
	{
		case 3:
			indexSet->filter(BBJSIndexSet_filter, &data, *indexSetPass);
			break;
		case 4:
			indexSet->filter(BBJSIndexSet_filter, &data, *indexSetPass, *indexSetFail);
			break;
	}

	return JSValueMakeUndefined(ctx);
}

#pragma mark -
#pragma mark Static Properties
#pragma mark -

const JSStaticValue BB::IndexSet::StaticValues[] =
{
	{NULL, NULL, NULL, 0}
};

const JSStaticFunction BB::IndexSet::StaticFunctions[] =
{
	{"clear",      BB::IndexSet::Clear,      kJSPropertyAttributeReadOnly | kJSPropertyAttributeDontEnum | kJSPropertyAttributeDontDelete},
	{"swap",       BB::IndexSet::Swap,       kJSPropertyAttributeReadOnly | kJSPropertyAttributeDontEnum | kJSPropertyAttributeDontDelete},
	{"intersect",  BB::IndexSet::Intersect,  kJSPropertyAttributeReadOnly | kJSPropertyAttributeDontEnum | kJSPropertyAttributeDontDelete},
	{"union",      BB::IndexSet::Union,      kJSPropertyAttributeReadOnly | kJSPropertyAttributeDontEnum | kJSPropertyAttributeDontDelete},
	{"difference", BB::IndexSet::Difference, kJSPropertyAttributeReadOnly | kJSPropertyAttributeDontEnum | kJSPropertyAttributeDontDelete},
	{"forAll",     BB::IndexSet::ForAll,     kJSPropertyAttributeReadOnly | kJSPropertyAttributeDontEnum | kJSPropertyAttributeDontDelete},
	{"filter",     BB::IndexSet::Filter,     kJSPropertyAttributeReadOnly | kJSPropertyAttributeDontEnum | kJSPropertyAttributeDontDelete},
	
	{NULL, NULL, 0}
};

const JSClassDefinition BB::IndexSet::Definition =
{
    0, kJSClassAttributeNone,//kJSClassAttributeNoAutomaticPrototype,
    "IndexSet", NULL,
    BB::IndexSet::StaticValues,
    BB::IndexSet::StaticFunctions,
    BB::IndexSet::Initialize,
    BB::IndexSet::Finalize,
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
};
