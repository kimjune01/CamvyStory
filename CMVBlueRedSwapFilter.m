
#import "CMVBlueRedSwapFilter.h"
#import "GPUImageLookupFilter.h"

@implementation CMVBlueRedSwapFilter

- (id)init;
{
    if (!(self = [super init]))
    {
		return nil;
    }
    
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
    UIImage *image = [UIImage imageNamed:@"lookup_RGB.png"];
#else
    NSImage *image = [NSImage imageNamed:@"lookup_RGB.png"];
#endif
    
    NSAssert(image, @"To use CMVBlueRedSwapFilter you need to add lookup_RGB.png to your application bundle.");
    
    lookupImageSource = [[GPUImagePicture alloc] initWithImage:image];
    GPUImageLookupFilter *lookupFilter = [[GPUImageLookupFilter alloc] init];
    [self addFilter:lookupFilter];
    
    [lookupImageSource addTarget:lookupFilter atTextureLocation:1];
    [lookupImageSource processImage];
    
    self.initialFilters = [NSArray arrayWithObjects:lookupFilter, nil];
    self.terminalFilter = lookupFilter;
    
    return self;
}

#pragma mark -
#pragma mark Accessors

@end