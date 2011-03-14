#ifndef _BB_VISUALIZATION_H_
#define _BB_VISUALIZATION_H_

#ifdef __cplusplus
#include <cstdlib>
extern "C"
{
#else
#include <stdlib.h>
#endif

typedef struct _BBVector3 {float coord[3];} BBVector3;
#define BBVector3Make(x,y,z) ((BBVector3){x,y,z})

void      BBMultGLMatrixWithForwardAndUp(BBVector3 forward, BBVector3 up);

#pragma mark -
#pragma mark Vector3
#pragma mark -

BBVector3 BBVector3CreateRandom(void);
BBVector3 BBVector3Lerp(BBVector3 a, BBVector3 b, float v);
BBVector3 BBVector3Normalize(BBVector3 a);
float     BBVector3Length(BBVector3 a);
#define   BBVector3Add(a, b)  ((BBVector3){a.coord[0]+b.coord[0],a.coord[1]+b.coord[1],a.coord[2]+b.coord[2]})
#define   BBVector3Sub(a, b)  ((BBVector3){a.coord[0]-b.coord[0],a.coord[1]-b.coord[1],a.coord[2]-b.coord[2]})
#define   BBVector3Mul(a, b)  ((BBVector3){a.coord[0]*b,a.coord[1]*b,a.coord[2]*b})
#define   BBVector3MulP(a, b) ((BBVector3){a.coord[0]*b.coord[0],a.coord[1]*b.coord[1],a.coord[2]*b.coord[2]})

#pragma mark -
#pragma mark Vector3 Array
#pragma mark -

	typedef void (*BBVector3ArrayForEachCallback)(void * context, const BBVector3 data);

	typedef size_t (*BBVector3ArrayAddVectorFunc    )(void * user_data, const BBVector3 data);
	typedef float* (*BBVector3ArrayGetVectorFunc    )(void * user_data, size_t index);
	typedef void   (*BBVector3ArrayRemoveVectorFunc )(void * user_data, size_t index);
	typedef void   (*BBVector3ArrayForEachVectorFunc)(void * user_data, BBVector3ArrayForEachCallback callback, void * context);

	typedef struct _BBVector3Array
	{
		BBVector3ArrayAddVectorFunc     add;
		BBVector3ArrayGetVectorFunc     get;
		BBVector3ArrayRemoveVectorFunc  remove;
		BBVector3ArrayForEachVectorFunc forEach;
		void * user_data;
	}
	* BBVector3Array;

	void BBVector3Array_create(BBVector3Array array);
	void BBVector3Array_destroy(BBVector3Array array);

#define BBVector3Array_add(array, data)						((*(array)->add)((array)->user_data, data))
#define BBVector3Array_getComponents(array, data)			((*(array)->get)((array)->user_data, data))
#define BBVector3Array_get(array, data)						(*(BBVector3*)((*(array)->get)((array)->user_data, data)))
#define BBVector3Array_remove(array, index)					((*(array)->remove)((array)->user_data, index))
#define BBVector3Array_forEach(array, callback, context)	((*(array)->forEach)((array)->user_data, callback, data))
	
#ifdef __cplusplus
}
#endif

#ifdef __OBJC__
#include <BBVisualization/BBWorldView.h>
#endif

#endif
