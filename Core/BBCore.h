#ifndef _BB_CORE_H_
#define _BB_CORE_H_

#ifdef __cplusplus
extern "C" {
#endif

	typedef struct _bb_context * bb_context;
	typedef struct _bb_patch * bb_patch;

	bb_context bbContextCreate(void);
	void       bbContextDestroy(bb_context context);
	void       bbContextEvaluateScript(bb_context ctx, const char * script);
	void       bbContextEvaluateScriptFromFile(bb_context ctx, const char * filename);

	bb_patch bbPatchCreate(void);
	void     bbPatchDestroy(bb_patch patch);

	void bbPatchUpdate(bb_patch patch);

	void bbPatchAddInputAsString(bb_patch patch, const char * name, const char * string);
	void bbPatchAddInputAsNumber(bb_patch patch, const char * name, double number);
	void bbPatchAddOutputAsFunction(bb_patch patch, const char * name, const char * source);

	void bbPatchRemoveInput(bb_patch patch, const char * name);
	void bbPatchRemoveOutput(bb_patch patch, const char * name);

	const char * bbPatchGetInputAsString(bb_patch ptch, const char * name);
	double       bbPatchGetInputAsNumber(bb_patch ptch, const char * name);
	const char * bbPatchGetOutputAsString(bb_patch ptch, const char * name);
	double       bbPatchGetOutputAsNumber(bb_patch ptch, const char * name);
	
	void bbPatchConnect(bb_patch patch_in, const char * input,
						bb_patch patch_out, const char * output);
	void bbPatchDisconnectInput(bb_patch ptch, const char * name);
	void bbPatchDisconnectOutput(bb_patch ptch, const char * name);
	
#ifdef __cplusplus
}
#endif

#endif
