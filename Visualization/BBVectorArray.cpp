#include "BBVisualization.h"

#include <vector>

size_t BBVector3ArrayDefault_add(void * user_data, const BBVector3 data)
{
	std::vector<BBVector3> * vec;

	vec = static_cast<std::vector<BBVector3>*>(user_data);
	vec->push_back(data);

	return vec->size()-1L;
}
float* BBVector3ArrayDefault_get(void * user_data, size_t index)
{
	std::vector<BBVector3> * vec;

	vec = static_cast<std::vector<BBVector3>*>(user_data);

	if (index < vec->size())
		return vec->at(index).coord;

	return NULL;
}
void   BBVector3ArrayDefault_remove(void * user_data, size_t index)
{
	std::vector<BBVector3> * vec;
	
	vec = static_cast<std::vector<BBVector3>*>(user_data);

	vec->erase(vec->begin() + index);
}
void   BBVector3ArrayDefault_forEach(void * user_data, BBVector3ArrayForEachCallback callback, void * context)
{
	std::vector<BBVector3> * vec;
	
	vec = static_cast<std::vector<BBVector3>*>(user_data);
	
	for (std::vector<BBVector3>::const_iterator
		 i = vec->begin(),
		 e = vec->end();
		 i != e; ++i)
	{
		(*callback)(context, *i);
	}
}

void BBVector3Array_create(BBVector3Array array)
{
	array->add       = &BBVector3ArrayDefault_add;
	array->get       = &BBVector3ArrayDefault_get;
	array->remove    = &BBVector3ArrayDefault_remove;
	array->forEach   = &BBVector3ArrayDefault_forEach;
	array->user_data = new std::vector<BBVector3>;
}

void BBVector3Array_destroy(BBVector3Array array)
{
	delete static_cast<std::vector<BBVector3>*>(array->user_data);
	free(array);
}

