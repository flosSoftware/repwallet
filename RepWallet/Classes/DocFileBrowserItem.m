#import "DocFileBrowserItem.h"


@implementation DocFileBrowserItem
@synthesize fileTitle;
@synthesize isDirectory;
@synthesize path;
@synthesize isSelectable;

+ (DocFileBrowserItem*)itemWithTitle:(NSString *)t andPath:(NSString *)p isDirectory:(BOOL)isDir{
	DocFileBrowserItem *d = [[DocFileBrowserItem alloc] init];
	d.fileTitle = t;
	d.path = p;
	d.isDirectory = isDir;
	d.isSelectable = true;
	return [d autorelease];
}

- (void)dealloc{
	self.fileTitle = nil;
	self.path = nil;
	[super dealloc];
}

@end
