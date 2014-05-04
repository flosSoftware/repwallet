//
//  RouteOverlayMapView.m
//  repWallet
//
//  Created by Alberto Fiore on 2/10/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import "RouteOverlay.h"

@implementation RouteOverlay

@synthesize inMapView;
@synthesize routePoints;
@synthesize lineColor; 

- (id)init {
	self = [super init];
	if (self != nil) {
		
		self.backgroundColor = [UIColor clearColor];
		self.userInteractionEnabled = NO;
	}
	
	return self;
}

- (void)dealloc {
	[inMapView release];
	[routePoints release];
	[lineColor release];
	[super dealloc];
}

- (void) setMapView:(RMMapView *)mapView isPortrait:(BOOL)isPortrait{
    
//    NSLog(@"mapView.bounds.size.width %f mapView.bounds.size.height %f", mapView.bounds.size.width, mapView.bounds.size.height);
    
    self.frame = CGRectMake(0.0f,
                            0.0f,
                            isPortrait? mapView.bounds.size.width : mapView.bounds.size.height,
                            isPortrait? mapView.bounds.size.height : mapView.bounds.size.width);
    self.inMapView = mapView;
    [[self.inMapView getOverlayView] addSublayer:self.layer];
}

- (void)drawRect:(CGRect)rect { 
    
	if(!self.hidden && self.routePoints != nil && self.routePoints.count > 0) {
        
		CGContextRef context = UIGraphicsGetCurrentContext(); 
		
		if(!self.lineColor) {
            
			self.lineColor = [UIColor colorWithRed:0.0f green:0.0f blue:(156.0 /255) alpha:0.5f];
            
		}
		
		CGContextSetStrokeColorWithColor(context, self.lineColor.CGColor);
		CGContextSetRGBFillColor(context, 0.0f, 0.0f, 1.0f, 1.0f);
		
		CGContextSetLineWidth(context, 4.0f);
		
		for(int i = 0; i < self.routePoints.count; i++) {
            
			CGPoint point = [self.inMapView coordinateToPixel:[[self.routePoints objectAtIndex:i] coordinate]];
			
			if(i == 0) {
                
				CGContextMoveToPoint(context, point.x, point.y);

			} else {
                
				CGContextAddLineToPoint(context, point.x, point.y);

			}
		}
		
		CGContextStrokePath(context);
       
	}
}

- (void)setRoute:(NSArray *)routePoints {
 
    self.routePoints = routePoints;
    
}

@end
