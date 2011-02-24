#include <BBCore/BBCore.h>

int main (int argc, char * const argv[])
{
	bb_context context;

	context = bbContextCreate();

	bbContextEvaluateScriptFromFile(context, "test_suite.js");
	
	bbContextDestroy(context);

    return 0;
}
