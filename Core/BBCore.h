#ifndef _BB_CORE_H_
#define _BB_CORE_H_

#ifdef __cplusplus
extern "C" {
#endif
	
	typedef struct _bb_context * bb_context;
	typedef struct _bb_patch * bb_patch;
	typedef struct _bb_patch_collection * bb_patch_collection;


#pragma mark -
#pragma mark Context
#pragma mark -

	bb_context bbContextCreate(void);
	void       bbContextDestroy(bb_context context);
	void       bbContextEvaluateScript(bb_context ctx, const char * script);
	void       bbContextEvaluateScriptFromFile(bb_context ctx, const char * filename);

#pragma mark -
#pragma mark Patch
#pragma mark -	

	bb_patch bbPatchCreate(void);
	void     bbPatchDestroy(bb_patch patch);

	void bbPatchAddInputAsString(bb_patch patch, const char * name, const char * string);
	void bbPatchAddInputAsNumber(bb_patch patch, const char * name, double number);
	void bbPatchAddOutputAsFunction(bb_patch patch, const char * name, const char * source);

	void bbPatchRemoveInput(bb_patch patch, const char * name);
	void bbPatchRemoveOutput(bb_patch patch, const char * name);

	char * bbPatchGetInputAsString(bb_patch ptch, const char * name);
	double bbPatchGetInputAsNumber(bb_patch ptch, const char * name);
	char * bbPatchGetOutputAsString(bb_patch ptch, const char * name);
	double bbPatchGetOutputAsNumber(bb_patch ptch, const char * name);
	
	void bbPatchConnect(bb_patch patch_in, const char * input,
						bb_patch patch_out, const char * output);
	void bbPatchDisconnectInput(bb_patch ptch, const char * name);
	void bbPatchDisconnectOutput(bb_patch ptch, const char * name);

#pragma mark -
#pragma mark Patch Collection
#pragma mark -	
	
	bb_patch_collection bbPatchCollectionCreate(bb_context ctx);
	bb_patch_collection bbPatchCollectionCreateFromFile(bb_context ctx, const char * filename);
	void                bbPatchCollectionDestroy(bb_patch_collection collection);

	void bbPatchCollectionManagePatch(bb_patch_collection collection, bb_patch patch);
	void bbPatchCollectionUnmanagePatch(bb_patch_collection collection, bb_patch patch);
	
	char * bbPatchCollectionSerialize(bb_patch_collection collection);
	void   bbPatchCollectionDeserialize(bb_patch_collection collection, const char * xml);
	
	void bbPatchCollectionSaveToFile(bb_patch_collection collection, const char * filename);
	void bbPatchCollectionLoadFromFile(bb_patch_collection collection, const char * filename);	

#ifdef __cplusplus
}
#endif

#endif
