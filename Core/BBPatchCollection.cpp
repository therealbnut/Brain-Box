#include "BBPatchCollection.h"
#include "BBContext.h"
#include "BBPatch.h"
#include "BBCore.h"

#include <map>
#include <iostream>
#include <iterator>
#include <fstream>
#include <vector>

BB::PatchCollection::PatchCollection(BB::Context& context)
 :	m_context(context)
{
	JSContextRef ctx;
	ctx = context.context();
	this->m_patch_collection_object = JSObjectMake(ctx, context.patchCollectionClass(), this);
}

BB::PatchCollection::PatchCollection(BB::Context& context, 
									 const std::string& filename)
  :	m_context(context)
{
	JSContextRef ctx;
	ctx = context.context();
	this->m_patch_collection_object = JSObjectMake(ctx, context.patchCollectionClass(), this);

	this->loadFromFile(filename);
}

BB::PatchCollection::~PatchCollection()
{
	for (std::set<BB::Patch*>::const_iterator
		 i = this->m_patches.begin(),
		 e = this->m_patches.end();
		 i != e; ++i)
	{
		this->unmanagePatch(*(*i));
	}
}

#pragma mark -
#pragma mark Patch Management

void BB::PatchCollection::managePatch(BB::Patch& patch)
{
	if (!this->m_patches.insert(&patch).second)
	{
		std::cerr << "Could not manage patch, perhaps it is already managed!" << std::endl;
	}
	else
	{
		JSContextRef ctx;
		ctx = this->m_context.context();
		JSValueProtect(ctx, patch.object());
	}
}

void BB::PatchCollection::unmanagePatch(BB::Patch& patch)
{
	std::set<BB::Patch*>::iterator i;
	
	i = this->m_patches.find(&patch);
	if (i == this->m_patches.end())
	{
		std::cerr << "Could not destroy patch, perhaps it is not managed!" << std::endl;
	}
	else
	{
		JSContextRef ctx;

		this->m_patches.erase(i);

		ctx = this->m_context.context();
		JSValueUnprotect(ctx, patch.object());
		JSGarbageCollect(ctx);
	}
}

/*
	<collection>
		<patch id="0">
			<input name="forks" default="6" />
			<input name="woo" default="2">
				<connect patch="3" link="test" />
			</input>
			<output name="forks">
 <![CDATA[
	return 12;
 ]]>
			</output>
		</patch>
	</collection>
 */

#pragma mark Serialize and Deserialize
std::string BB::PatchCollection::serialize() const
{
	std::map<const BB::Patch*, size_t> patchMap;
	size_t currentPatchIndex;
	xmlDocPtr doc;
	xmlNodePtr collection, patch;
	std::string data;
	xmlChar * doc_txt;
	int doc_txt_len;
	
	doc        = xmlNewDoc(BAD_CAST "1.0");
	collection = xmlNewNode(NULL, BAD_CAST "collection");
	
	xmlDocSetRootElement(doc, collection);
	
	currentPatchIndex = 0;
	for (std::set<BB::Patch*>::const_iterator
		 i = this->m_patches.begin(),
		 e = this->m_patches.end();
		 i != e; ++i)
	{
		patchMap.insert(std::make_pair(*i, currentPatchIndex));
		++currentPatchIndex;
	}
	
	for (std::set<BB::Patch*>::const_iterator
		 i = this->m_patches.begin(),
		 e = this->m_patches.end();
		 i != e; ++i)
	{
		patch = (*i)->serialize(patchMap);
		xmlAddChild(collection, patch);
	}
	
	doc_txt = NULL;
	xmlDocDumpFormatMemoryEnc(doc, &doc_txt, &doc_txt_len, "UTF-8", 1);
	if (doc_txt == NULL)
		this->m_context.throwException("Unable to write memory!");
	
	xmlFreeDoc(doc);
	xmlCleanupParser();
	xmlMemoryDump();
	
	data.assign((char*)doc_txt, doc_txt_len);
	
	return data;
}

void BB::PatchCollection::deserialize(const std::string& xml)
{
	std::map<size_t,BB::Patch*> patchMap;
    xmlDocPtr doc;
	xmlNodePtr collection;
	xmlNodePtr patch;

	doc = xmlReadMemory(xml.c_str(), xml.size(), "memory", "UTF-8", 1);
    if (doc == NULL)
	{
		printf("%s\n", xml.c_str());
		this->m_context.throwException("Unable to read memory!");
	}
	
	collection = xmlDocGetRootElement(doc);
	
    for (patch = collection->children; patch != NULL; patch = patch->next)
	{
        if (patch->type == XML_ELEMENT_NODE)
		{
			std::string patch_name = (const char*)patch->name;
			if (patch_name == "patch")
			{
				BB::Patch * patchobj;
				size_t id;
				
				patchobj = new BB::Patch(this->m_context, NULL, NULL);
				id       = patchobj->deserializePatch(patch);
				
				patchMap.insert(std::make_pair(id, patchobj));
				
				this->managePatch(*patchobj);
			}
		}
    }
	
    for (patch = collection->children; patch != NULL; patch = patch->next)
	{
		std::string patch_name = (const char*)patch->name;
        if (patch->type == XML_ELEMENT_NODE)
		{
			if (patch_name == "patch")
			{
				BB::Patch::DeserializeConnections(this->m_context, patch, patchMap);
			}
		}
    }
	
    xmlFreeDoc(doc);
	xmlCleanupParser();
	xmlMemoryDump();	
}


#pragma mark File Save and Load

void BB::PatchCollection::saveToFile(const std::string& filename) const throw(BB::Exception)
{
	std::ofstream fs;
	std::string data;

	fs.open(filename.c_str());
	if (!fs.good())
		this->m_context.throwException("Unable to open file: '" + filename + "'");

	data = this->serialize();

	fs.write(data.c_str(), data.size());
	
	fs.close();
}

void BB::PatchCollection::loadFromFile(const std::string& filename) throw(BB::Exception)
{
	std::ifstream fs;
	std::vector<char> buffer;
	std::string data;

	fs.open(filename.c_str());
	if (!fs.good())
		this->m_context.throwException("Unable to open file: '" + filename + "'");

	fs.seekg(0, std::ios::end);
	buffer.resize(fs.tellg());
	fs.seekg(0, std::ios::beg);
	fs.read(&buffer[0], buffer.size());
	fs.close();

	data.assign(&buffer[0], buffer.size());

	this->deserialize(data);
}

#pragma mark Static JavaScript Functions

void BB::PatchCollection::Initialize(JSContextRef ctx, JSObjectRef object)
{
	BB::PatchCollection * collection;
	
	collection = BB::PatchCollection::FromJS(NULL, object);	
}
void BB::PatchCollection::Finalize(JSObjectRef object)
{
	BB::PatchCollection * collection;
	
	collection = BB::PatchCollection::FromJS(NULL, object);
	
	delete collection;
}

JSObjectRef BB::PatchCollection::Constructor(JSContextRef ctx,
											 JSObjectRef constructor,
											 size_t argumentCount,
											 const JSValueRef arguments[],
											 JSValueRef *exception) throw(BB::Exception)
{
	BB::Context * context;
	BB::PatchCollection * collection;

	context = BB::Context::FromJS(ctx);
	switch (argumentCount)
	{
		case 0:
		{
			collection = new BB::PatchCollection(*context);
			break;
		}
		case 1:
			collection = new BB::PatchCollection(*context, 
												 context->getString(arguments[0]));
			break;
		default:
		context->throwException("Constructor takes no arguments!");
	}

	return collection->m_patch_collection_object;
}
JSValueRef BB::PatchCollection::ManagePatch(JSContextRef ctx,
											JSObjectRef function,
											JSObjectRef thisObject,
											size_t argumentCount,
											const JSValueRef arguments[],
											JSValueRef* exception) throw(BB::Exception)
{
	BB::Context * context;
	BB::PatchCollection * collection;
	BB::Patch * patch;
	JSObjectRef object;
	JSValueRef except;
	
	context = BB::Context::FromJS(ctx);
	if (argumentCount != 1)
	{
		context->throwException("ManagePatch takes one argument!");
	}
	
	collection = BB::PatchCollection::FromJS(ctx, thisObject);

	except = NULL;
	object = JSValueToObject(ctx, arguments[0], &except);
	if (except != NULL)
		context->throwException("Connect second argument is invalid");
	patch = BB::Patch::FromJS(ctx, object);
	
	collection->managePatch(*patch);
	
	return JSValueMakeUndefined(ctx);
}
JSValueRef BB::PatchCollection::UnmanagePatch(JSContextRef ctx,
											  JSObjectRef function,
											  JSObjectRef thisObject,
											  size_t argumentCount,
											  const JSValueRef arguments[],
											  JSValueRef* exception) throw(BB::Exception)
{
	BB::Context * context;
	BB::PatchCollection * collection;
	BB::Patch * patch;
	JSObjectRef object;
	JSValueRef except;
	
	context = BB::Context::FromJS(ctx);
	if (argumentCount != 1)
	{
		context->throwException("DestroyPatch takes one argument!");
	}
	
	collection = BB::PatchCollection::FromJS(ctx, thisObject);
	
	except = NULL;
	object = JSValueToObject(ctx, arguments[0], &except);
	if (except != NULL)
		context->throwException("Connect second argument is invalid");
	patch = BB::Patch::FromJS(ctx, object);
	
	collection->unmanagePatch(*patch);
	
	return JSValueMakeUndefined(ctx);
}
JSValueRef BB::PatchCollection::SaveToFile(JSContextRef ctx,
										   JSObjectRef function,
										   JSObjectRef thisObject,
										   size_t argumentCount,
										   const JSValueRef arguments[],
										   JSValueRef* exception) throw(BB::Exception)
{
	BB::Context * context;
	BB::PatchCollection * collection;
	std::string filename;
	
	context = BB::Context::FromJS(ctx);
	if (argumentCount != 1)
	{
		context->throwException("DestroyPatch takes one argument!");
	}
	
	collection = BB::PatchCollection::FromJS(ctx, thisObject);
	
	filename = context->getString(arguments[0]);
	collection->saveToFile(filename);
	
	return JSValueMakeUndefined(ctx);
}

#pragma mark -
#pragma mark Utility
#pragma mark -

BB::PatchCollection* BB::PatchCollection::FromJS(JSContextRef ctx,
												 JSObjectRef object)
{
	BB::Context * context;
	BB::PatchCollection * collection;
	
	if (ctx != NULL)
	{
		context = BB::Context::FromJS(ctx);
		if (!JSValueIsObjectOfClass(ctx, object, context->patchCollectionClass()))
		{
			return NULL;
		}
	}
	
	collection = static_cast<BB::PatchCollection*>(JSObjectGetPrivate(object));
	
	return collection;
}

#pragma mark -
#pragma mark Static Properties
#pragma mark -

const JSStaticValue BB::PatchCollection::StaticValues[] =
{
	{NULL, NULL, NULL, 0}
};

const JSStaticFunction BB::PatchCollection::StaticFunctions[] =
{
	{"managePatch",   BB::PatchCollection::ManagePatch,   kJSPropertyAttributeReadOnly | kJSPropertyAttributeDontEnum | kJSPropertyAttributeDontDelete},
	{"unmanagePatch", BB::PatchCollection::UnmanagePatch, kJSPropertyAttributeReadOnly | kJSPropertyAttributeDontEnum | kJSPropertyAttributeDontDelete},

	{"saveToFile",    BB::PatchCollection::SaveToFile,    kJSPropertyAttributeReadOnly | kJSPropertyAttributeDontEnum | kJSPropertyAttributeDontDelete},

	{NULL, NULL, 0}
};

const JSClassDefinition BB::PatchCollection::Definition =
{
    0, kJSClassAttributeNone,//kJSClassAttributeNoAutomaticPrototype,
    "PatchCollection", NULL,
    BB::PatchCollection::StaticValues,
    BB::PatchCollection::StaticFunctions,
    BB::PatchCollection::Initialize,
    BB::PatchCollection::Finalize,
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
};

#pragma mark -
#pragma mark Patch C Interface
#pragma mark -

#pragma mark Create and Destroy

bb_patch_collection bbPatchCollectionCreate(bb_context ctx)
{
	BB::Context * context;
	BB::PatchCollection * collection;
	
	try
	{
		context    = reinterpret_cast<BB::Context*>(ctx);
		collection = new BB::PatchCollection(*context);
		
		JSValueProtect(context->context(), collection->object());
	}
	catch (BB::Exception& error)
	{
		std::cerr << error.what() << std::endl;
		return NULL;
	}
	
	return reinterpret_cast<bb_patch_collection>(collection);
}

bb_patch_collection bbPatchCollectionCreateFromFile(bb_context ctx, const char * filename)
{
	BB::Context * context;
	BB::PatchCollection * collection;
	
	try
	{
		context    = reinterpret_cast<BB::Context*>(ctx);
		collection = new BB::PatchCollection(*context, filename);
		
		JSValueProtect(context->context(), collection->object());
	}
	catch (BB::Exception& error)
	{
		std::cerr << error.what() << std::endl;
		return NULL;
	}
	
	return reinterpret_cast<bb_patch_collection>(collection);
}

void bbPatchCollectionDestroy(bb_patch_collection _collection)
{
	BB::Context * context;
	BB::PatchCollection * collection;
	JSContextRef ctx;
	
	try
	{
		collection = reinterpret_cast<BB::PatchCollection *>(_collection);
		context    = collection->context();
		ctx        = context->context();

		JSValueUnprotect(ctx, collection->object());
		JSGarbageCollect(ctx);
	}
	catch (BB::Exception& error)
	{
		std::cerr << error.what() << std::endl;
	}
}

#pragma mark Patch Management

void bbPatchCollectionManagePatch(bb_patch_collection _collection, bb_patch _patch)
{
	BB::PatchCollection * collection;
	BB::Patch * patch;
	
	try
	{
		collection = reinterpret_cast<BB::PatchCollection *>(_collection);
		patch      = reinterpret_cast<BB::Patch *>(_patch);
		collection->managePatch(*patch);
	}
	catch (BB::Exception& error)
	{
		std::cerr << error.what() << std::endl;
	}
}
void bbPatchCollectionUnmanagePatch(bb_patch_collection _collection, bb_patch _patch)
{
	BB::PatchCollection * collection;
	BB::Patch * patch;
	
	try
	{
		collection = reinterpret_cast<BB::PatchCollection *>(_collection);
		patch      = reinterpret_cast<BB::Patch *>(_patch);
		collection->unmanagePatch(*patch);
	}
	catch (BB::Exception& error)
	{
		std::cerr << error.what() << std::endl;
	}
}

#pragma mark Serialization

char * bbPatchCollectionSerialize(bb_patch_collection _collection)
{
	BB::PatchCollection * collection;
	std::string string;
	char * buffer;	
	
	try
	{
		collection = reinterpret_cast<BB::PatchCollection *>(_collection);

		string = collection->serialize();
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

void bbPatchCollectionDeserialize(bb_patch_collection _collection, const char * xml)
{
	BB::PatchCollection * collection;
	std::string string;
	
	try
	{
		collection = reinterpret_cast<BB::PatchCollection *>(_collection);
		collection->deserialize(xml);
	}
	catch (BB::Exception& error)
	{
		std::cerr << error.what() << std::endl;
	}
}

#pragma mark File Load and Save

void bbPatchCollectionSaveToFile(bb_patch_collection _collection, const char * filename)
{
	BB::PatchCollection * collection;
	
	try
	{
		collection = reinterpret_cast<BB::PatchCollection *>(_collection);
		collection->saveToFile(filename);
	}
	catch (BB::Exception& error)
	{
		std::cerr << error.what() << std::endl;
	}
}

void bbPatchCollectionLoadFromFile(bb_patch_collection _collection, const char * filename)
{
	BB::PatchCollection * collection;
	
	try
	{
		collection = reinterpret_cast<BB::PatchCollection *>(_collection);
		collection->loadFromFile(filename);
	}
	catch (BB::Exception& error)
	{
		std::cerr << error.what() << std::endl;
	}
}

