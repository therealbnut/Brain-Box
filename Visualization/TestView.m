#import "TestView.h"


@implementation TestView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
	{
		BBVector3Array_create(&self->_colors);
		BBVector3Array_create(&self->_scales);
		BBVector3Array_create(&self->_translations);
		BBVector3Array_create(&self->_forwards);
		BBVector3Array_create(&self->_ups);
		
		[self setColors:       &self->_colors];
		[self setScales:       &self->_scales];
		[self setTranslations: &self->_translations];
		[self setForwards:     &self->_forwards];
		[self setUps:          &self->_ups];
		
		for (int i=0; i<8; ++i)
		{
			BBVector3 pos = BBVector3CreateRandom();
			pos = BBVector3Add(pos, BBVector3Make(0.0, 0.0, -4.0));
			pos = BBVector3Mul(pos, 2.0);
			
			BBVector3Array_add(&self->_colors,       BBVector3Make(1.0, 0.0, 0.0));
			BBVector3Array_add(&self->_scales,       BBVector3Make(0.4, 0.4, 0.4));
			BBVector3Array_add(&self->_translations, pos);
			BBVector3Array_add(&self->_forwards,     BBVector3Make(0.0, 0.0, 1.0));
			BBVector3Array_add(&self->_ups,          BBVector3Make(0.0, 1.0, 0.0));
		}
    }
    return self;
}

-(void) dealloc
{
	BBVector3Array_destroy(&self->_colors);
	BBVector3Array_destroy(&self->_scales);
	BBVector3Array_destroy(&self->_translations);
	BBVector3Array_destroy(&self->_forwards);
	BBVector3Array_destroy(&self->_ups);

	[super dealloc];
}

-(void) update
{
	static BBVector3 oldv = {0.0, 0.0, 0.0};
	BBVector3 old;
	float * ptr;
	float oldv_normfac;
	size_t index;

	index = 0;
	while (true)
	{
		ptr = BBVector3Array_getComponents(&self->_forwards, index);
		if (ptr == NULL)
			break;
		
		BBVector3 a = BBVector3CreateRandom();
		BBVector3 b = BBVector3CreateRandom();
		
		oldv = BBVector3Lerp(oldv, BBVector3MulP(a, b), 0.02);
		oldv_normfac = 0.1 / BBVector3Length(oldv);
		if (oldv_normfac < 1.0) oldv = BBVector3Mul(oldv, oldv_normfac);

		old = *(BBVector3*)ptr;
		old = BBVector3Normalize(BBVector3Add(old, oldv));
		*(BBVector3*)ptr = old;

		++index;
	}

	[super update];
}

@end
