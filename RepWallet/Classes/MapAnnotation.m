//
//  MapAnnotation.m
//  repWallet
//
//  Created by Alberto Fiore on 10/1/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import "MapAnnotation.h"
#import "Firm.h"
#import "Event.h"
#import "UnpaidInvoice.h"
#import "RMMapView.h"
#import "TrafficIncident.h"


@implementation MapAnnotation

@synthesize canShowCallout;
@synthesize isDraggable;
@synthesize calloutTitle;
@synthesize calloutSubtitle;
@synthesize calloutSubbottomtitle;
@synthesize index;
@synthesize selected;
@synthesize data;

-(id) initWithImage:(UIImage *)image data:(id<Mappable>)data isDraggable:(BOOL)isDraggable canShowCallout:(BOOL) canShowCallout index:(int)idx coordinate:(CLLocationCoordinate2D)coordinate mapView:(RMMapView *)mapView
{
    self = [super initWithMapView:mapView coordinate:coordinate andTitle:nil];
    
    if (self) {
        
        self.annotationIcon = image;
        
        if (idx == 0 || idx == -1) {
            self.anchorPoint = CGPointMake(0.5, 0.5);
        } else {
            self.anchorPoint = CGPointMake(0.5, 1.0);
        }
        
        self.index = idx;
        self.isDraggable = isDraggable;
        self.canShowCallout = canShowCallout;
        self.data = data;
        
        NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init]; 
        [dateFormatter setTimeStyle:NSDateFormatterNoStyle]; 
        [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        
        NSNumberFormatter * numberFormatter = [[NSNumberFormatter alloc] init]; 
        [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle]; 
        [numberFormatter setMaximumFractionDigits:3];
        
        if([data isMemberOfClass:[Firm class]]) {
            
            Firm * f = (Firm *)self.data;
            self.annotationType = FIRM_MARKER;
            self.calloutTitle = [f firmName];
            self.calloutSubtitle = [f street];
            self.calloutSubbottomtitle = [NSString stringWithFormat:@"%@ - %@", [f town], [f country]];
            
        } else if([data isMemberOfClass:[Event class]]) {
            
            self.annotationType = EVENT_MARKER;
            self.calloutTitle = [(Event *)self.data firmName];
            self.calloutSubtitle = [NSString stringWithFormat:@"Date: %@", [dateFormatter stringFromDate:[(Event *)self.data date]]];
            self.calloutSubbottomtitle = [NSString stringWithFormat:@"%@ %@", [(Event *)self.data subject], [(Event *)self.data result]];
            
        }  else if([data isMemberOfClass:[UnpaidInvoice class]]) {
            
            self.annotationType = UNPAID_MARKER;
            NSString * amt = [NSString stringWithFormat:@"%@ €", [numberFormatter stringFromNumber:[(UnpaidInvoice *)self.data amount]]];
            NSString * opened = [NSString stringWithFormat:@"opened: %@", [dateFormatter stringFromDate:[(UnpaidInvoice *)self.data startDate]]];
            self.calloutTitle = [[(UnpaidInvoice *)self.data firm] firmName];
            self.calloutSubtitle = [NSString stringWithFormat:@"Amount: %@", amt];
            self.calloutSubbottomtitle = [NSString stringWithFormat:@"Status: %@", opened];
            
        } else if([data isMemberOfClass:[TrafficIncident class]]) {
            
            TrafficIncident *t = (TrafficIncident *)self.data;
            self.annotationType = TRAFFIC_MARKER;
            self.calloutTitle = [NSString stringWithFormat:@"%@ (%@)", [t type], [t severity]];
            
            if ([t description]) {
                self.calloutSubtitle = [t description];
            } else if ([t congestion]) {
                self.calloutSubtitle = [t congestion];
            } 
            
            if ([t description]) {
                self.calloutSubbottomtitle = [t detour];
            }
            
            self.selected = NO;
            
            
        } else
            ;
        
        [dateFormatter release];
        [numberFormatter release];
    } 
    
    return self;
}

-(id) initActualLocationAnnotationWithImage:(UIImage *)image coordinate:(CLLocationCoordinate2D)coordinate mapView:(RMMapView *)mapView {
    
    self = [self initWithImage:image data:nil isDraggable:NO canShowCallout:NO index:0 coordinate:coordinate mapView:mapView];
    if (self) {
        ;
        
    } 
    
    return self;
}

-(void)dealloc
{
    [self.data release];
    [self.calloutTitle release];
    [self.calloutSubtitle release];
    [self.calloutSubbottomtitle release];
    [super dealloc];
}

@end
